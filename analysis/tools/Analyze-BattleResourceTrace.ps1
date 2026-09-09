[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PerformanceCsv,
    [Parameter(Mandatory = $true)]
    [string]$TraceJsonl,
    [string]$ProcessPerformanceCsv,
    [string]$SwfCaptureLog,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

function Resolve-InputFile([string]$Path, [string]$Description) {
    $resolved = [IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "$Description not found: $resolved"
    }
    return $resolved
}

function Read-JsonLines([string]$Path) {
    $items = [Collections.Generic.List[object]]::new()
    $lineNumber = 0
    foreach ($line in [IO.File]::ReadLines($Path)) {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $items.Add(($line | ConvertFrom-Json))
        }
        catch {
            throw "Invalid JSON at $Path line $lineNumber."
        }
    }
    return $items
}

function Convert-ToUtc([object]$Value) {
    if ($Value -is [DateTimeOffset]) { return $Value.UtcDateTime }
    if ($Value -is [DateTime]) { return $Value.ToUniversalTime() }
    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    $styles = [Globalization.DateTimeStyles]::AllowWhiteSpaces
    if ($text.EndsWith('Z', [StringComparison]::OrdinalIgnoreCase)) {
        $styles = $styles -bor [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal
    }
    else {
        $styles = $styles -bor [Globalization.DateTimeStyles]::AssumeLocal
    }
    $parsed = [DateTime]::MinValue
    if (-not [DateTime]::TryParse($text, [Globalization.CultureInfo]::InvariantCulture, $styles, [ref]$parsed)) {
        return $null
    }
    return $parsed.ToUniversalTime()
}

function Convert-ToNullableDouble([string]$Value) {
    $number = 0.0
    if ([double]::TryParse(
        $Value,
        [Globalization.NumberStyles]::Float,
        [Globalization.CultureInfo]::InvariantCulture,
        [ref]$number)) {
        return $number
    }
    return $null
}

function Normalize-ResourcePath([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
    $text = $Value.Trim().Replace('\', '/')
    $uri = $null
    if ([Uri]::TryCreate($text, [UriKind]::Absolute, [ref]$uri)) {
        $text = $uri.AbsolutePath
    }
    $text = $text.TrimStart('/')
    if ($text.StartsWith('play/', [StringComparison]::OrdinalIgnoreCase)) {
        $text = $text.Substring(5)
    }
    $text = [regex]::Replace($text, '~\d+(?=\.swf$)', '', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $text = [regex]::Replace($text, '\.swf$', '', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    return $text.Trim('/')
}

$performancePath = Resolve-InputFile $PerformanceCsv 'Performance CSV'
$tracePath = Resolve-InputFile $TraceJsonl 'Trace JSONL'
$performance = @(Import-Csv -LiteralPath $performancePath | ForEach-Object {
    [pscustomobject]@{
        TimeUtc = Convert-ToUtc $_.Time
        BattleNumber = [int]($_.BattleNumber)
        TotalMemoryMB = Convert-ToNullableDouble $_.FlashTotalMemoryMB
        PrivateMemoryMB = Convert-ToNullableDouble $_.FlashPrivateMemoryMB
        FreeMemoryMB = Convert-ToNullableDouble $_.FlashFreeMemoryMB
        Row = $_
    }
})
$events = @(Read-JsonLines $tracePath | Where-Object { $_.recordType -eq 'flash-event' } | ForEach-Object {
    [pscustomobject]@{
        TimeUtc = Convert-ToUtc $_.timeUtc
        BattleNumber = [int]$_.battleNumber
        Sequence = [int]$_.sequence
        Type = [string]$_.type
        Resource = Normalize-ResourcePath ([string]$_.resource)
        DurationMs = [int]$_.durationMs
        Value = [int]$_.value
        DroppedEventCount = [int]$_.droppedEventCount
    }
})

$processPerformancePath = $null
$ppapiPerformance = @()
if (-not [string]::IsNullOrWhiteSpace($ProcessPerformanceCsv)) {
    $processPerformancePath = Resolve-InputFile $ProcessPerformanceCsv 'Process performance CSV'
    $ppapiPerformance = @(Import-Csv -LiteralPath $processPerformancePath |
        Where-Object { $_.Role -ceq 'ppapi-flash' } |
        ForEach-Object {
            [pscustomobject]@{
                TimeUtc = Convert-ToUtc $_.Time
                ProcessId = [string]$_.ProcessId
                PrivateMemoryMB = Convert-ToNullableDouble $_.PrivateMemoryMB
            }
        })
}

$captureByResource = @{}
if (-not [string]::IsNullOrWhiteSpace($SwfCaptureLog)) {
    $capturePath = Resolve-InputFile $SwfCaptureLog 'SWF capture log'
    $captureRequests = @{}
    foreach ($item in Read-JsonLines $capturePath) {
        $requestId = [string]$item.requestId
        if ($item.event -eq 'Requested') {
            $captureRequests[$requestId] = [ordered]@{
                Resource = Normalize-ResourcePath ([string]$item.url)
                Url = [string]$item.url
                ReceivedBytes = -1L
                CacheEvidence = ''
            }
        }
        elseif ($captureRequests.ContainsKey($requestId) -and $item.event -eq 'Response') {
            $captureRequests[$requestId].CacheEvidence = [string]$item.cacheEvidence
        }
        elseif ($captureRequests.ContainsKey($requestId) -and $item.event -eq 'LoadComplete') {
            $captureRequests[$requestId].ReceivedBytes = [int64]$item.receivedContentLength
        }
    }
    foreach ($capture in $captureRequests.Values) {
        if ([string]::IsNullOrWhiteSpace($capture.Resource)) { continue }
        if (-not $captureByResource.ContainsKey($capture.Resource)) {
            $captureByResource[$capture.Resource] = [Collections.Generic.List[object]]::new()
        }
        $captureByResource[$capture.Resource].Add([pscustomobject]$capture)
    }
}

$longFrames = @($events | Where-Object { $_.Type -eq 'frame-gap' -and $_.Value -ge 100 -and $_.TimeUtc })
$resourceStarts = @($events | Where-Object { $_.Type -eq 'resource-started' -and $_.Resource })
$resourceEnds = @($events | Where-Object { $_.Type -eq 'resource-ended' -and $_.Resource })
$duplicateLookup = @{}
$duplicateRequests = @($resourceStarts | Group-Object BattleNumber, Resource | Where-Object { $_.Count -gt 1 } |
    ForEach-Object {
        $first = $_.Group[0]
        $duplicateLookup[$first.Resource] = [int]($duplicateLookup[$first.Resource]) + $_.Count - 1
        [pscustomobject]@{
            BattleNumber = $first.BattleNumber
            Resource = $first.Resource
            RequestCount = $_.Count
            DuplicateCount = $_.Count - 1
        }
    })
$unfinishedByBattle = @($resourceStarts | Group-Object BattleNumber, Resource | ForEach-Object {
    $first = $_.Group[0]
    $completionCount = @($resourceEnds | Where-Object {
        $_.BattleNumber -eq $first.BattleNumber -and $_.Resource -ceq $first.Resource
    }).Count
    if ($_.Count -gt $completionCount) {
        [pscustomobject]@{
            BattleNumber = $first.BattleNumber
            Resource = $first.Resource
            RequestCount = $_.Count
            CompletionCount = $completionCount
            UnfinishedCount = $_.Count - $completionCount
        }
    }
})

$resourceSummary = @($resourceStarts | Group-Object Resource | ForEach-Object {
    $resource = $_.Name
    $starts = @($_.Group)
    $ends = @($resourceEnds | Where-Object { $_.Resource -ceq $resource })
    $durations = @($ends | Where-Object { $_.DurationMs -ge 0 } | ForEach-Object { $_.DurationMs })
    $nearbyLongFrames = 0
    $totalMemoryDeltas = [Collections.Generic.List[double]]::new()
    $usedHeapDeltas = [Collections.Generic.List[double]]::new()
    $privateMemoryDeltas = [Collections.Generic.List[double]]::new()
    $ppapiPrivateMemoryDeltas = [Collections.Generic.List[double]]::new()
    foreach ($end in $ends) {
        if ($end.TimeUtc) {
            $nearbyLongFrames += @($longFrames | Where-Object {
                [Math]::Abs(($_.TimeUtc - $end.TimeUtc).TotalMilliseconds) -le 1000
            }).Count
            $before = @($performance | Where-Object { $_.TimeUtc -and $_.TimeUtc -le $end.TimeUtc } |
                Sort-Object TimeUtc -Descending | Select-Object -First 1)
            $after = @($performance | Where-Object { $_.TimeUtc -and $_.TimeUtc -ge $end.TimeUtc } |
                Sort-Object TimeUtc | Select-Object -First 1)
            if ($before.Count -eq 1 -and $after.Count -eq 1 -and
                ($after[0].TimeUtc - $before[0].TimeUtc).TotalSeconds -le 15) {
                if ($null -ne $before[0].TotalMemoryMB -and $null -ne $after[0].TotalMemoryMB) {
                    $totalMemoryDeltas.Add($after[0].TotalMemoryMB - $before[0].TotalMemoryMB)
                }
                if ($null -ne $before[0].PrivateMemoryMB -and $null -ne $after[0].PrivateMemoryMB) {
                    $privateMemoryDeltas.Add($after[0].PrivateMemoryMB - $before[0].PrivateMemoryMB)
                }
                if ($null -ne $before[0].TotalMemoryMB -and $null -ne $before[0].FreeMemoryMB -and
                    $null -ne $after[0].TotalMemoryMB -and $null -ne $after[0].FreeMemoryMB) {
                    $usedHeapDeltas.Add(
                        ($after[0].TotalMemoryMB - $after[0].FreeMemoryMB) -
                        ($before[0].TotalMemoryMB - $before[0].FreeMemoryMB))
                }
            }
            $ppapiBefore = @($ppapiPerformance | Where-Object { $_.TimeUtc -and $_.TimeUtc -le $end.TimeUtc } |
                Sort-Object TimeUtc -Descending | Select-Object -First 1)
            $ppapiAfter = @($ppapiPerformance | Where-Object { $_.TimeUtc -and $_.TimeUtc -ge $end.TimeUtc } |
                Sort-Object TimeUtc | Select-Object -First 1)
            if ($ppapiBefore.Count -eq 1 -and $ppapiAfter.Count -eq 1 -and
                $ppapiBefore[0].ProcessId -ceq $ppapiAfter[0].ProcessId -and
                ($ppapiAfter[0].TimeUtc - $ppapiBefore[0].TimeUtc).TotalSeconds -le 15 -and
                $null -ne $ppapiBefore[0].PrivateMemoryMB -and $null -ne $ppapiAfter[0].PrivateMemoryMB) {
                $ppapiPrivateMemoryDeltas.Add(
                    $ppapiAfter[0].PrivateMemoryMB - $ppapiBefore[0].PrivateMemoryMB)
            }
        }
    }
    $captures = if ($captureByResource.ContainsKey($resource)) { @($captureByResource[$resource]) } else { @() }
    [pscustomobject]@{
        Resource = $resource
        RequestCount = $starts.Count
        CompletionCount = $ends.Count
        UnfinishedCount = [Math]::Max(0, $starts.Count - $ends.Count)
        DuplicateRequestsWithinBattle = [int]$duplicateLookup[$resource]
        TotalDurationMs = [int64](($durations | Measure-Object -Sum).Sum)
        MaxDurationMs = if ($durations.Count) { [int](($durations | Measure-Object -Maximum).Maximum) } else { -1 }
        LongFrames100WithinOneSecond = $nearbyLongFrames
        AverageTotalMemoryDeltaMB = if ($totalMemoryDeltas.Count) { [Math]::Round(($totalMemoryDeltas | Measure-Object -Average).Average, 3) } else { $null }
        AverageUsedHeapDeltaMB = if ($usedHeapDeltas.Count) { [Math]::Round(($usedHeapDeltas | Measure-Object -Average).Average, 3) } else { $null }
        AverageFlashPrivateMemoryDeltaMB = if ($privateMemoryDeltas.Count) { [Math]::Round(($privateMemoryDeltas | Measure-Object -Average).Average, 3) } else { $null }
        AveragePpapiPrivateMemoryDeltaMB = if ($ppapiPrivateMemoryDeltas.Count) { [Math]::Round(($ppapiPrivateMemoryDeltas | Measure-Object -Average).Average, 3) } else { $null }
        CapturedMaxBytes = if ($captures.Count) { [int64](($captures.ReceivedBytes | Measure-Object -Maximum).Maximum) } else { -1 }
        CaptureCacheEvidence = (($captures.CacheEvidence | Where-Object { $_ } | Sort-Object -Unique) -join ';')
    }
} | Sort-Object @{ Expression = 'LongFrames100WithinOneSecond'; Descending = $true },
    @{ Expression = 'TotalDurationMs'; Descending = $true }, Resource)

$latest = @($performance | Where-Object { $_.Row.BridgeAvailable -eq 'true' } | Sort-Object TimeUtc | Select-Object -Last 1)
$latestLifecycle = if ($latest.Count -eq 1) {
    $row = $latest[0].Row
    [pscustomobject]@{
        Time = $row.Time
        BattleNumber = $row.BattleNumber
        LiveFightPanels = $row.LiveFightPanels
        PanelCreatedCount = $row.PanelCreatedCount
        PanelDisposedCount = $row.PanelDisposedCount
        LiveStartMovies = $row.LiveStartMovies
        StartMovieCreatedCount = $row.StartMovieCreatedCount
        StartMovieDisposedCount = $row.StartMovieDisposedCount
        LiveApplicationDomains = $row.LiveApplicationDomains
        ReleasedApplicationDomains = $row.ReleasedApplicationDomains
        LivePreloadSessions = $row.LivePreloadSessions
        ActivePreloadSessions = $row.ActivePreloadSessions
        PreloadInFlightCount = $row.PreloadInFlightCount
        TraceDroppedCount = $row.TraceDroppedCount
    }
} else { $null }

$result = [pscustomobject]@{
    PerformanceCsv = $performancePath
    TraceJsonl = $tracePath
    ProcessPerformanceCsv = $processPerformancePath
    ResourceSummary = $resourceSummary
    DuplicateRequests = $duplicateRequests
    UnfinishedResources = $unfinishedByBattle
    LatestLifecycle = $latestLifecycle
    MaximumDroppedEventCount = [int](($events.DroppedEventCount | Measure-Object -Maximum).Maximum)
}

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
    $parent = Split-Path -Parent $resolvedOutput
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $resolvedOutput -Encoding utf8
}

$result
