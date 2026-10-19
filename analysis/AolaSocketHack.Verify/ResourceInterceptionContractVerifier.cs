using System;
using AolaLoader.Features.PetMorph;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;
using AolaLoader;
using AolaLoader.Features.ActiveSend.ResourceInterception;
using AolaLoader.Features.Battle.Coordination;
using AolaLoader.Features.Battle.ResourceInterception;
using AolaLoader.Features.Battle.Settings;
using AolaLoader.Features.PetMorph.Coordination;
using AolaLoader.Features.PetMorph.ResourceInterception;
using AolaLoader.Features.Theme.ResourceInterception;
using AolaLoader.ResourceInterception.Contracts;
using AolaLoader.ResourceInterception.Pipeline;
using AolaLoader.ResourceInterception.Rules;
using AolaLoader.ResourceInterception.Testing;
using AolaLoader.ResourceInterception.Transformers;

namespace AolaSocketHack.Verify;

internal static class ResourceInterceptionContractVerifier
{
	public static bool Verify()
	{
		return VerifyRequestContext() &&
			VerifyPlansAndRuleDouble() &&
			VerifyTransformContracts() &&
			VerifyCompressedSwfTransform() &&
			VerifyProbeContracts() &&
			VerifyRulePipeline() &&
			VerifyBoundedResponseProcessor() &&
			VerifySwfHeaderAndProbeCache() &&
			VerifyThemeLeafRule() &&
			VerifyStartBridgeRule() &&
			VerifyStartXmlRule() &&
			VerifyBattleBridgeRule() &&
			VerifyBattleBackgroundImageRule() &&
			VerifyPetPackageLiveRule() &&
			VerifyRemotePlanExecutor() &&
			VerifyBattlePetMovieRule() &&
			VerifyPetMovieRule() &&
			VerifyPetPosterRule();
	}

	private static bool VerifyRequestContext()
	{
		Dictionary<string, string> headers = new Dictionary<string, string>
		{
			["Accept"] = "application/x-shockwave-flash"
		};
		ResourceRequestContext context = new ResourceRequestContext(
			"HTTPS://AOLA.100BT.COM/play/control/skin1~123.swf?version=1",
			"get",
			"Xhr",
			headers,
			isRewrittenRequest: true,
			isFallbackRequest: false,
			internalPlanKey: "theme:skin1");
		headers["Accept"] = "changed";
		return context.Scheme == "https" &&
			context.Host == "aola.100bt.com" &&
			context.Path == "/play/control/skin1~123.swf" &&
			context.Query == "?version=1" &&
			context.Method == "GET" &&
			context.ResourceType == "Xhr" &&
			context.Headers["accept"] == "application/x-shockwave-flash" &&
			context.IsRewrittenRequest &&
			!context.IsFallbackRequest &&
			context.InternalPlanKey == "theme:skin1" &&
			Throws<ArgumentException>(() => new ResourceRequestContext("ftp://example.test/file.swf", "GET", "Other")) &&
			Throws<ArgumentException>(() => new ResourceRequestContext(
				"https://aola.100bt.com/file.swf",
				"GET",
				"Other",
				isRewrittenRequest: true));
	}

	private static bool VerifyPlansAndRuleDouble()
	{
		const string originalUrl = "https://aola.100bt.com/play/control/skin1~123.swf";
		byte[] content = { 1, 2, 3, 4 };
		ResourceInterceptionPlan local = ResourceInterceptionPlan.LocalResponse(
			originalUrl,
			content,
			"application/x-shockwave-flash",
			"theme:skin1:cache",
			"theme:skin1");
		content[0] = 99;
		byte[] firstRead = local.LocalContent;
		firstRead[1] = 88;
		if (local.Outcome != ResourceInterceptionOutcome.LocalResponse ||
			local.LocalContent[0] != 1 || local.LocalContent[1] != 2 ||
			local.MaximumResponseBytes != 4)
		{
			return false;
		}

		ResourceInterceptionPlan remote = ResourceInterceptionPlan.RewriteRemote(
			originalUrl,
			"https://aola.100bt.com/play/control/skin2~123.swf",
			"application/x-shockwave-flash",
			transformer: null,
			fallbackUrl: originalUrl,
			cacheKey: "theme:remote:cache",
			diagnosticKey: "theme:remote",
			maximumResponseBytes: 16 * 1024 * 1024);

		int evaluations = 0;
		DelegateResourceInterceptionRule rule = new DelegateResourceInterceptionRule(
			"theme.leaf",
			800,
			"aola.100bt.com:/play/control/controlbarskin/skinN~*.swf",
			request =>
			{
				evaluations++;
				return local;
			});
		ResourceInterceptionPlan evaluated = rule.Evaluate(
			new ResourceRequestContext(originalUrl, "GET", "Other"));
		return remote.Outcome == ResourceInterceptionOutcome.RewriteRemote &&
			remote.TargetUrl.EndsWith("skin2~123.swf", StringComparison.Ordinal) &&
			remote.FallbackUrl == originalUrl &&
			rule.Name == "theme.leaf" && rule.Priority == 800 &&
			!string.IsNullOrWhiteSpace(rule.PathOwnership) &&
			evaluations == 1 && ReferenceEquals(evaluated, local) &&
			ResourceInterceptionPlan.PassThrough(originalUrl).Outcome == ResourceInterceptionOutcome.PassThrough &&
			Throws<ArgumentOutOfRangeException>(() => ResourceInterceptionPlan.RewriteRemote(
				originalUrl,
				originalUrl,
				null,
				null,
				null,
				"bad-limit",
				"bad-limit",
				0));
	}

	private static bool VerifyTransformContracts()
	{
		byte[] source = { 10, 20, 30 };
		ResourceTransformInput input = new ResourceTransformInput(
			"https://aola.100bt.com/source.swf",
			200,
			"application/x-shockwave-flash",
			source);
		source[0] = 90;
		byte[] inputRead = input.Content;
		inputRead[1] = 91;

		DelegateResourceResponseTransformer rejecting = new DelegateResourceResponseTransformer(
			"swf.contract-check",
			"Complete bounded SWF response",
			value => ResourceTransformResult.Reject("swf.invalid", "candidate rejected"));
		ResourceTransformResult rejected = rejecting.Transform(input);
		byte[] transformed = { 7, 8, 9 };
		ResourceTransformResult success = ResourceTransformResult.Success(
			transformed,
			"application/x-shockwave-flash");
		transformed[0] = 0;
		byte[] resultRead = success.Content;
		resultRead[1] = 0;

		return input.Content[0] == 10 && input.Content[1] == 20 && input.ContentLength == 3 &&
			!rejected.Succeeded && rejected.Content == null && rejected.RejectionCode == "swf.invalid" &&
			success.Succeeded && success.Content[0] == 7 && success.Content[1] == 8 &&
			string.IsNullOrEmpty(success.RejectionCode) &&
			Throws<ArgumentException>(() => ResourceTransformResult.Reject(null, "invalid"));
	}

	private static bool VerifyCompressedSwfTransform()
	{
		const string sourceToken = "PetMovie6044";
		const string targetToken = "PetMovie6000";
		byte[] sourceBytes = Encoding.ASCII.GetBytes(sourceToken);
		byte[] fws = new byte[8 + sourceBytes.Length];
		fws[0] = (byte)'F';
		fws[1] = (byte)'W';
		fws[2] = (byte)'S';
		fws[3] = 18;
		Buffer.BlockCopy(BitConverter.GetBytes((uint)fws.Length), 0, fws, 4, 4);
		Buffer.BlockCopy(sourceBytes, 0, fws, 8, sourceBytes.Length);

		byte[] cws;
		using (MemoryStream output = new MemoryStream())
		{
			output.WriteByte((byte)'C');
			output.WriteByte((byte)'W');
			output.WriteByte((byte)'S');
			output.WriteByte(fws[3]);
			output.Write(fws, 4, 4);
			using (DeflateStream deflate = new DeflateStream(output, CompressionMode.Compress, true))
			{
				deflate.Write(fws, 8, fws.Length - 8);
			}
			cws = output.ToArray();
		}

		AolaSwfResourceTransformer transformer = new AolaSwfResourceTransformer(
			sourceToken,
			targetToken,
			1,
			1);
		ResourceTransformResult result = transformer.Transform(new ResourceTransformInput(
			"https://aola.100bt.com/petmovie6044.swf",
			200,
			"application/x-shockwave-flash",
			cws));
		return result.Succeeded &&
			SwfResponseHeaderValidator.IsValidCompleteFws(result.Content) &&
			Encoding.ASCII.GetString(result.Content).Contains(targetToken);
	}

	private static bool VerifyProbeContracts()
	{
		RemoteResourceProbeRequest request = new RemoteResourceProbeRequest(
			"https://aola.100bt.com/target.swf",
			"probe:target:cache",
			"probe:target",
			16 * 1024 * 1024,
			TimeSpan.FromMinutes(10),
			TimeSpan.FromSeconds(30));
		int calls = 0;
		DelegateRemoteResourceProbe probe = new DelegateRemoteResourceProbe((value, cancellationToken) =>
		{
			calls++;
			return Task.FromResult(RemoteResourceProbeResult.Success(206, 8));
		});
		RemoteResourceProbeResult result = probe.ProbeAsync(request, CancellationToken.None)
			.GetAwaiter()
			.GetResult();
		RemoteResourceProbeResult rejected = RemoteResourceProbeResult.Reject(
			"http.non_success",
			"not found",
			404,
			0);
		return calls == 1 && result.Available && result.HttpStatusCode == 206 && result.ContentLength == 8 &&
			!rejected.Available && rejected.HttpStatusCode == 404 && rejected.RejectionCode == "http.non_success" &&
			request.AvailableTimeToLive == TimeSpan.FromMinutes(10) &&
			request.UnavailableTimeToLive == TimeSpan.FromSeconds(30) &&
			Throws<ArgumentOutOfRangeException>(() => new RemoteResourceProbeRequest(
				request.TargetUrl,
				request.CacheKey,
				request.DiagnosticKey,
				0,
				TimeSpan.FromMinutes(1),
				TimeSpan.FromSeconds(1)));
	}

	private static bool VerifyRulePipeline()
	{
		const string exactUrl = "https://aola.100bt.com/play/control/controlbarskin/skin1~123.swf";
		const string nearUrl = "https://aola.100bt.com/play/control/controlbarskin/skin1~123.swf.bak";
		int lowerEvaluations = 0;
		DelegateResourceInterceptionRule precise = new DelegateResourceInterceptionRule(
			"theme.precise",
			800,
			"aola.100bt.com:/play/control/controlbarskin/skinN~*.swf",
			request => request.Path.EndsWith(".swf", StringComparison.OrdinalIgnoreCase)
				? ResourceInterceptionPlan.LocalResponse(
					request.OriginalUrl,
					new byte[] { 1, 2, 3 },
					"application/x-shockwave-flash",
					"theme:precise",
					"theme.precise")
				: ResourceInterceptionPlan.PassThrough(request.OriginalUrl));
		DelegateResourceInterceptionRule lower = new DelegateResourceInterceptionRule(
			"pet.lower",
			600,
			"aola.100bt.com:/play/pet/**",
			request =>
			{
				lowerEvaluations++;
				return ResourceInterceptionPlan.LocalResponse(
					request.OriginalUrl,
					new byte[] { 4 },
					"application/x-shockwave-flash",
					"pet:lower",
					"pet.lower");
			});
		ResourceRulePipeline pipeline = new ResourceRulePipeline(new[] { lower, precise });
		ResourceRuleEvaluation exact = pipeline.Evaluate(new ResourceRequestContext(exactUrl, "GET", "Other"));
		ResourceRuleEvaluation near = pipeline.Evaluate(new ResourceRequestContext(nearUrl, "GET", "Other"));
		if (!exact.IsMatch || exact.RuleName != "theme.precise" || lowerEvaluations != 1 ||
			!near.IsMatch || near.RuleName != "pet.lower")
		{
			return false;
		}

		DelegateResourceInterceptionRule conflict = new DelegateResourceInterceptionRule(
			"theme.conflict",
			800,
			precise.PathOwnership,
			request => ResourceInterceptionPlan.LocalResponse(
				request.OriginalUrl,
				new byte[] { 9 },
				"application/x-shockwave-flash",
				"theme:conflict",
				"theme.conflict"));
		ResourceRuleEvaluation conflicted = new ResourceRulePipeline(new[] { precise, conflict })
			.Evaluate(new ResourceRequestContext(exactUrl, "GET", "Other"));
		ResourceRuleEvaluation disabled = pipeline.Evaluate(
			new ResourceRequestContext(exactUrl, "GET", "Other"),
			enabled: false);
		ResourceRuleEvaluation rewritten = pipeline.Evaluate(new ResourceRequestContext(
			exactUrl,
			"GET",
			"Other",
			isRewrittenRequest: true,
			internalPlanKey: "theme:precise"));
		ResourceRuleEvaluation fallback = pipeline.Evaluate(new ResourceRequestContext(
			exactUrl,
			"GET",
			"Other",
			isFallbackRequest: true,
			internalPlanKey: "theme:precise"));

		return !conflicted.IsMatch && conflicted.DiagnosticCode == "pipeline.priority_conflict" &&
			!disabled.IsMatch && disabled.DiagnosticCode == "pipeline.disabled" &&
			!rewritten.IsMatch && rewritten.DiagnosticCode == "pipeline.rewrite_recursion" &&
			!fallback.IsMatch && fallback.DiagnosticCode == "pipeline.fallback" &&
			Throws<ArgumentOutOfRangeException>(() => new ResourceRulePipeline(new[]
			{
				new DelegateResourceInterceptionRule(
					"invalid.priority",
					700,
					"none",
					request => ResourceInterceptionPlan.PassThrough(request.OriginalUrl))
			}));
	}

	private static bool VerifyBoundedResponseProcessor()
	{
		const string sourceUrl = "https://aola.100bt.com/resource.swf";
		byte[] content = { 1, 2, 3, 4 };
		using BoundedResourceResponseProcessor successful = new BoundedResourceResponseProcessor(4);
		if (!successful.TryAppend(content, 0, 2) || !successful.TryAppend(content, 2, 2))
		{
			return false;
		}
		ResourceTransformResult copied = successful.Complete(
			sourceUrl,
			200,
			string.Empty,
			"application/x-shockwave-flash",
			transformer: null);
		content[0] = 99;
		if (!copied.Succeeded || copied.Content[0] != 1 || copied.Content.Length != 4)
		{
			return false;
		}

		using BoundedResourceResponseProcessor tooLarge = new BoundedResourceResponseProcessor(3);
		if (tooLarge.TryAppend(new byte[] { 1, 2, 3, 4 }, 0, 4) ||
			tooLarge.Complete(sourceUrl, 200, "application/octet-stream", null, null).RejectionCode !=
			"response.input_too_large")
		{
			return false;
		}

		using BoundedResourceResponseProcessor nonSuccess = new BoundedResourceResponseProcessor(4);
		nonSuccess.TryAppend(new byte[] { 1 }, 0, 1);
		if (nonSuccess.Complete(sourceUrl, 404, "application/octet-stream", null, null).RejectionCode !=
			"response.http_non_success")
		{
			return false;
		}

		DelegateResourceResponseTransformer throwing = new DelegateResourceResponseTransformer(
			"throwing",
			"test",
			input => throw new InvalidOperationException("failure"));
		using BoundedResourceResponseProcessor transformFailure = new BoundedResourceResponseProcessor(4);
		transformFailure.TryAppend(new byte[] { 1 }, 0, 1);
		return transformFailure.Complete(
			sourceUrl,
			200,
			"application/octet-stream",
			null,
			throwing).RejectionCode == "response.transform_exception";
	}

	private static bool VerifySwfHeaderAndProbeCache()
	{
		byte[] fws = CreateHeader('F', 8);
		byte[] cws = CreateHeader('C', 128);
		byte[] zws = CreateHeader('Z', 128, 3, 1024);
		const uint skin5436ResponseLength = 16791137;
		const uint skin5436DeclaredLength = 20971028;
		byte[] skin5436 = CreateHeader(
			'Z',
			skin5436DeclaredLength,
			skin5436ResponseLength - 17,
			16 * 1024 * 1024);
		if (!SwfResponseHeaderValidator.IsSupported(fws, 8, 8, 1024) ||
			SwfResponseHeaderValidator.IsSupported(fws, 8, 9, 1024) ||
			!SwfResponseHeaderValidator.IsSupported(cws, 8, 32, 1024) ||
			!SwfResponseHeaderValidator.IsSupported(zws, 17, 20, 1024) ||
			SwfResponseHeaderValidator.IsSupported(zws, 17, 21, 1024) ||
			SwfResponseHeaderValidator.IsSupported(
				skin5436,
				17,
				skin5436ResponseLength,
				16 * 1024 * 1024) ||
			!SwfResponseHeaderValidator.IsSupported(
				skin5436,
				17,
				skin5436ResponseLength,
				PetMorphLiveSkinMapping.MaximumBackgroundSwfBytes))
		{
			return false;
		}

		DateTime now = new DateTime(2026, 8, 22, 0, 0, 0, DateTimeKind.Utc);
		int calls = 0;
		DelegateRemoteResourceProbe inner = new DelegateRemoteResourceProbe((request, token) =>
		{
			calls++;
			return Task.FromResult(RemoteResourceProbeResult.Success(206, 128));
		});
		CachingRemoteResourceProbe cached = new CachingRemoteResourceProbe(inner, () => now);
		RemoteResourceProbeRequest probeRequest = new RemoteResourceProbeRequest(
			"https://aola.100bt.com/cached.swf",
			"cached-swf:v1",
			"cached-swf",
			1024,
			TimeSpan.FromMinutes(10),
			TimeSpan.FromSeconds(30));
		RemoteResourceProbeResult first = cached.ProbeAsync(probeRequest, CancellationToken.None)
			.GetAwaiter().GetResult();
		RemoteResourceProbeResult second = cached.ProbeAsync(probeRequest, CancellationToken.None)
			.GetAwaiter().GetResult();
		now = now.AddMinutes(11);
		RemoteResourceProbeResult expired = cached.ProbeAsync(probeRequest, CancellationToken.None)
			.GetAwaiter().GetResult();
		return first.Available && ReferenceEquals(first, second) && expired.Available && calls == 2;
	}

	private static byte[] CreateHeader(char signature, uint declaredLength, uint compressedLength = 0, uint dictionarySize = 0)
	{
		byte[] header = new byte[17];
		header[0] = (byte)signature;
		header[1] = (byte)'W';
		header[2] = (byte)'S';
		Buffer.BlockCopy(BitConverter.GetBytes(declaredLength), 0, header, 4, 4);
		Buffer.BlockCopy(BitConverter.GetBytes(compressedLength), 0, header, 8, 4);
		header[12] = 0x5D;
		Buffer.BlockCopy(BitConverter.GetBytes(dictionarySize), 0, header, 13, 4);
		return header;
	}

	private static bool VerifyThemeLeafRule()
	{
		byte[] template = CreateThemeTemplate("Skin1", 3);
		ThemeLeafResourceRule rule = new ThemeLeafResourceRule(new[]
		{
			new KeyValuePair<int, byte[]>(1, template)
		});
		template[8] = 0;
		const string exactUrl = "https://aola.100bt.com/play/control/controlbarskin/skin0~20260822.swf?version=1";
		if (rule.Evaluate(new ResourceRequestContext(exactUrl, "GET", "Other")).Outcome !=
			ResourceInterceptionOutcome.PassThrough)
		{
			return false;
		}

		rule.SelectedThemeId = 1;
		ResourceInterceptionPlan replaced = rule.Evaluate(
			new ResourceRequestContext(exactUrl, "GET", "Other"));
		byte[] content = replaced.LocalContent;
		if (replaced.Outcome != ResourceInterceptionOutcome.LocalResponse ||
			replaced.ContentType != "application/x-shockwave-flash" ||
			CountAscii(content, "Skin0") != 3 || CountAscii(content, "Skin1") != 0 ||
			BitConverter.ToUInt32(content, 4) != content.Length)
		{
			return false;
		}
		content[8] = 0;
		if (replaced.LocalContent[8] == 0)
		{
			return false;
		}

		return rule.Evaluate(new ResourceRequestContext(
			"https://aola.100bt.com/play/control/controlbarskin/skin0~20260822.swf.bak",
			"GET",
			"Other")).Outcome == ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(exactUrl, "POST", "Other")).Outcome ==
				ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(
				"https://example.test/play/control/controlbarskin/skin0~20260822.swf",
				"GET",
				"Other")).Outcome == ResourceInterceptionOutcome.PassThrough &&
			Throws<ArgumentException>(() => new ThemeLeafResourceRule(new[]
			{
				new KeyValuePair<int, byte[]>(1, CreateThemeTemplate("Skin1", 2))
			}));
	}

	private static byte[] CreateThemeTemplate(string token, int count)
	{
		byte[] body = Encoding.ASCII.GetBytes(string.Join("|", Repeat(token, count)));
		byte[] content = new byte[8 + body.Length];
		content[0] = (byte)'F';
		content[1] = (byte)'W';
		content[2] = (byte)'S';
		content[3] = 18;
		Buffer.BlockCopy(BitConverter.GetBytes((uint)content.Length), 0, content, 4, 4);
		Buffer.BlockCopy(body, 0, content, 8, body.Length);
		return content;
	}

	private static IEnumerable<string> Repeat(string value, int count)
	{
		for (int index = 0; index < count; index++)
		{
			yield return value;
		}
	}

	private static int CountAscii(byte[] content, string value)
	{
		return (Encoding.ASCII.GetString(content).Length -
			Encoding.ASCII.GetString(content).Replace(value, string.Empty).Length) / value.Length;
	}

	private static bool VerifyPetPackageLiveRule()
	{
		byte[] template = CreatePetPackageTemplate(includeIconMarker: true);
		PetPackageLiveResourceRule rule = new PetPackageLiveResourceRule(template);
		template[8] = 0;
		string exactUrl =
			"https://aola.100bt.com/play/pet/newpetpackage~2026091780747880.swf?cache=1";
		ResourceInterceptionPlan matched = rule.Evaluate(
			new ResourceRequestContext(exactUrl, "GET", "Other"));
		byte[] firstRead = matched.LocalContent;
		if (!rule.IsAvailable || matched.Outcome != ResourceInterceptionOutcome.LocalResponse ||
			matched.ContentType != "application/x-shockwave-flash" || firstRead[8] == 0 ||
			CountAscii(firstRead, "aolaMorphResolveSkinId") != 1 ||
			CountAscii(firstRead, "aolaMorphRefresh") != 1 ||
			CountAscii(firstRead, "aolaMorphShouldHideBackground") != 1 ||
			CountAscii(firstRead, "aolaMorphResolveIconId") != 1 ||
			CountAscii(firstRead, "getAolaMorphControlSkinId") != 1 ||
			CountAscii(firstRead, "getAolaMorphVisualSkinId") != 1 ||
			CountAscii(firstRead, "getAolaMorphVisualSkinIdByRace") != 1 ||
			CountAscii(firstRead, "aolaSendCommand") != 0 ||
			CountAscii(firstRead, "aolaOpenPanel") != 0 ||
			CountAscii(firstRead, "aolaSetPlayback") != 0 ||
			CountAscii(firstRead, "ensureAolaCommandBridge") != 0 ||
			CountAscii(firstRead, "aolaCommandCompleted") != 0)
		{
			return false;
		}
		firstRead[8] = 0;
		if (matched.LocalContent[8] == 0)
		{
			return false;
		}

		PetPackageLiveResourceRule unavailable = new PetPackageLiveResourceRule((string)null);
		return !unavailable.IsAvailable && unavailable.Evaluate(
				new ResourceRequestContext(exactUrl, "GET", "Other")).Outcome ==
				ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(
				"https://aola.100bt.com/play/pet/newpetpackage~2026082731219998.swf",
				"GET",
				"Other")).Outcome == ResourceInterceptionOutcome.LocalResponse &&
			rule.Evaluate(new ResourceRequestContext(
				"https://aola.100bt.com/play/pet/newpetpackage~2026091780747880.swf.bak",
				"GET",
				"Other")).Outcome ==
				ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(exactUrl, "POST", "Other")).Outcome ==
				ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(
				"https://example.test/play/pet/newpetpackage~2026091780747880.swf",
				"GET",
				"Other")).Outcome == ResourceInterceptionOutcome.PassThrough &&
			Throws<ArgumentException>(() => new PetPackageLiveResourceRule(
				CreatePetPackageTemplate(includeIconMarker: false, includeControlMarker: true))) &&
			Throws<ArgumentException>(() => new PetPackageLiveResourceRule(
				CreatePetPackageTemplate(includeIconMarker: true, includeControlMarker: false))) &&
			Throws<ArgumentException>(() => new PetPackageLiveResourceRule(
				CreatePetPackageTemplate(includeIconMarker: true, includeControlMarker: true,
					includeVisualMarker: false))) &&
			Throws<ArgumentException>(() => new PetPackageLiveResourceRule(
				CreatePetPackageTemplate(includeIconMarker: true, includeControlMarker: true,
					includeCommandMarker: true)));
	}

	private static byte[] CreatePetPackageTemplate(
		bool includeIconMarker,
		bool includeControlMarker = true,
		bool includeVisualMarker = true,
		bool includeCommandMarker = false)
	{
		string body = "aolaMorphResolveSkinId|aolaMorphRefresh|aolaMorphShouldHideBackground" +
			(includeIconMarker ? "|aolaMorphResolveIconId" : string.Empty) +
			(includeControlMarker ? "|getAolaMorphControlSkinId" : string.Empty) +
			(includeVisualMarker ? "|getAolaMorphVisualSkinIdByRace" : string.Empty) +
			(includeCommandMarker ? "|aolaSendCommand" : string.Empty);
		byte[] bodyBytes = Encoding.ASCII.GetBytes(body);
		byte[] content = new byte[8 + bodyBytes.Length];
		content[0] = (byte)'F';
		content[1] = (byte)'W';
		content[2] = (byte)'S';
		content[3] = 18;
		Buffer.BlockCopy(BitConverter.GetBytes((uint)content.Length), 0, content, 4, 4);
		Buffer.BlockCopy(bodyBytes, 0, content, 8, bodyBytes.Length);
		return content;
	}

	internal static bool VerifyStartXmlRule()
	{
		StartXmlResourceRule rule = new StartXmlResourceRule();
		foreach (string path in new[] { "start.xml", "start~1792252800000.xml?cache=1" })
		{
			string url = "https://aola.100bt.com/play/" + path;
			ResourceInterceptionPlan plan = new ResourceRulePipeline(new[] { rule })
				.Evaluate(new ResourceRequestContext(url, "GET", "Other")).Plan;
			if (plan.Outcome != ResourceInterceptionOutcome.RewriteRemote ||
				plan.TargetUrl != url || plan.ProbeRemoteResource) return false;

			int fetchCount = 0;
			RemoteResourcePlanExecutor executor = new RemoteResourcePlanExecutor(
				new DelegateRemoteResourceProbe((request, token) => throw new InvalidOperationException("XML must skip SWF probing.")),
				new DelegateRemoteResourceFetcher((request, token) =>
				{
					fetchCount++;
					string state = fetchCount == 1 ? "close" : "open";
					string version = fetchCount == 1 ? "20261015557387610" : "20261022557387610";
					return Task.FromResult(RemoteResourceFetchResult.Success(200, "text/xml",
						Encoding.UTF8.GetBytes("<r>\n<t>" + state + "</t>\n<v>" + version + "</v><u>宠物/版本</u></r>")));
				}));
			for (int index = 0; index < 2; index++)
			{
				ResourceTransformResult result = executor.ExecuteAsync(plan, CancellationToken.None).GetAwaiter().GetResult();
				string version = index == 0 ? "20261015557387610" : "20261022557387610";
				if (!result.Succeeded || result.ContentType != "text/xml" ||
					Encoding.UTF8.GetString(result.Content) != "<r>\n<t>open</t>\n<v>" + version + "</v><u>宠物/版本</u></r>") return false;
			}
			if (fetchCount != 2) return false;
		}
		foreach (string url in new[]
		{
			"https://example.test/play/start.xml",
			"https://aola.100bt.com/play/start.xml.bak",
			"https://aola.100bt.com/play/start~abc.xml",
			"https://aola.100bt.com/play/start~2107300001.swf"
		})
		{
			if (rule.Evaluate(new ResourceRequestContext(url, "GET", "Other")).Outcome !=
				ResourceInterceptionOutcome.PassThrough) return false;
		}
		return rule.Evaluate(new ResourceRequestContext("https://aola.100bt.com/play/start.xml", "POST", "Other"))
			.Outcome == ResourceInterceptionOutcome.PassThrough;
	}

	private static bool VerifyStartBridgeRule()
	{
		byte[] template = CreateStartBridgeTemplate(includeLoadBytesMarker: true);
		StartBridgeResourceRule rule = new StartBridgeResourceRule(template);
		template[8] = 0;
		string exactUrl = "https://aola.100bt.com/play/start~" +
			StartBridgeResourceRule.SupportedVersion + ".swf?cache=1";
		ResourceInterceptionPlan matched = rule.Evaluate(
			new ResourceRequestContext(exactUrl, "GET", "Other"));
		byte[] firstRead = matched.LocalContent;
		if (!rule.IsAvailable || rule.Priority != 1000 ||
			matched.Outcome != ResourceInterceptionOutcome.LocalResponse ||
			matched.ContentType != "application/x-shockwave-flash" || firstRead[8] == 0 ||
			CountAscii(firstRead, "aolaSendCommand") != 1 ||
			CountAscii(firstRead, "aolaOpenPanel") != 1 ||
			CountAscii(firstRead, "aolaSetPlayback") != 1 ||
			CountAscii(firstRead, "mmo.play.actthings.data.ActClientSender") != 1 ||
			CountAscii(firstRead, "mmo.play.activity.helper.Panel_Helper") != 1)
		{
			return false;
		}
		firstRead[8] = 0;
		if (matched.LocalContent[8] == 0)
		{
			return false;
		}

		StartBridgeResourceRule unavailable = new StartBridgeResourceRule((string)null);
		return !unavailable.IsAvailable && unavailable.Evaluate(
				new ResourceRequestContext(exactUrl, "GET", "Other")).Outcome ==
				ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(
				"https://aola.100bt.com/play/start~2107300002.swf",
				"GET", "Other")).Outcome == ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(
				"https://aola.100bt.com/play/start~" +
				StartBridgeResourceRule.SupportedVersion + ".swf.bak",
				"GET", "Other")).Outcome == ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(exactUrl, "POST", "Other")).Outcome ==
				ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(
				"https://example.test/play/start~" +
				StartBridgeResourceRule.SupportedVersion + ".swf",
				"GET", "Other")).Outcome == ResourceInterceptionOutcome.PassThrough &&
			Throws<ArgumentException>(() => new StartBridgeResourceRule(
				CreateStartBridgeTemplate(includeLoadBytesMarker: false)));
	}

	internal static bool VerifyBattleBackgroundImageRule()
	{
		string imagePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory,
			"TestData", "BattleBackground", "background.jpg");
		BattleBackgroundImageResourceRule rule = new BattleBackgroundImageResourceRule(imagePath);
		string url = "https://aola.100bt.com" + BattleBackgroundImageResourceRule.ResourcePath;
		ResourceInterceptionPlan response = rule.Evaluate(
			new ResourceRequestContext(url, "GET", "Image"));
		if (response.Outcome != ResourceInterceptionOutcome.LocalResponse ||
			response.ContentType != "image/jpeg" ||
			new BattleBackgroundImageResourceRule(imagePath + ".missing")
				.Evaluate(new ResourceRequestContext(url, "GET", "Image")).Outcome !=
				ResourceInterceptionOutcome.PassThrough ||
			rule.Evaluate(new ResourceRequestContext(url, "POST", "Image")).Outcome !=
				ResourceInterceptionOutcome.PassThrough ||
			rule.Evaluate(new ResourceRequestContext(
				"https://example.test" + BattleBackgroundImageResourceRule.ResourcePath,
				"GET", "Image")).Outcome != ResourceInterceptionOutcome.PassThrough)
		{
			return false;
		}
		using (MemoryStream content = new MemoryStream(response.LocalContent))
		using (Image image = Image.FromStream(content))
		{
			return image.Width == 960 && image.Height == 560;
		}
	}

	internal static bool VerifyBattleBridgeRule()
	{
		string testData = Path.Combine(
			AppDomain.CurrentDomain.BaseDirectory,
			"TestData");
		string path = Path.Combine(testData, PetFightBattleBridgeArtifact.CandidateFileName);
		string manifestPath = Path.Combine(testData, PetFightBattleBridgeArtifact.ManifestFileName);
		if (!File.Exists(path) || !File.Exists(manifestPath)) return false;
		byte[] template = File.ReadAllBytes(path);
		string manifestJson = File.ReadAllText(manifestPath, Encoding.UTF8);
		PetFightBattleBridgeResourceRule rule = new PetFightBattleBridgeResourceRule(manifestJson, template);
		template[8] ^= 1;
		string exactUrl = "https://aola.100bt.com/play/pet/petfightnew~" +
			rule.SupportedVersion + ".swf?cache=1";
		ResourceInterceptionPlan matched = rule.Evaluate(
			new ResourceRequestContext(exactUrl, "GET", "Other"));
		ResourceInterceptionPlan newerVersion = rule.Evaluate(new ResourceRequestContext(
			"https://aola.100bt.com/play/pet/petfightnew~2026101541804528.swf?cache=1",
			"GET", "Other"));
		ResourceRulePipeline pipeline;
		try
		{
			pipeline = new ResourceRulePipeline(new IResourceInterceptionRule[] { rule });
		}
		catch (ArgumentOutOfRangeException)
		{
			return false;
		}
		byte[] firstRead = matched.LocalContent;
		if (pipeline == null || !rule.IsAvailable || rule.Priority != 850 ||
			matched.Outcome != ResourceInterceptionOutcome.LocalResponse ||
			matched.ContentType != "application/x-shockwave-flash" ||
			CountAscii(firstRead, "aolaBattleBridgeReady") < 1 ||
			CountAscii(firstRead, "aolaBattleApplyOptions") < 1 ||
			CountAscii(firstRead, "aolaBattleGetState") < 1 ||
			CountAscii(firstRead, "noteInputReady") < 1 ||
			CountAscii(firstRead, "skipBattlePresentation") != 1 ||
			CountAscii(firstRead, "hideDamageNumbers") != 1 ||
			CountAscii(firstRead, "hideHealingNumbers") != 1 ||
			CountAscii(firstRead, "skipAttackAnimation") != 0 ||
			CountAscii(firstRead, "skipPetAttackActions") != 0 ||
			CountAscii(firstRead, "skipBattleVisualDelays") != 0)
		{
			return false;
		}
		firstRead[8] ^= 1;
		if (matched.LocalContent[8] == firstRead[8]) return false;

		byte[] tampered = File.ReadAllBytes(path);
		tampered[tampered.Length - 1] ^= 1;
		PetFightBattleBridgeResourceRule unavailable = new PetFightBattleBridgeResourceRule((string)null);
		string temporaryRoot = Path.Combine(
			Path.GetTempPath(),
			"aola-battle-bridge-manifest-" + Guid.NewGuid().ToString("N"));
		Directory.CreateDirectory(temporaryRoot);
		bool fileLoadChecks;
		try
		{
			string temporaryManifest = Path.Combine(
				temporaryRoot,
				PetFightBattleBridgeArtifact.ManifestFileName);
			string temporaryCandidate = Path.Combine(
				temporaryRoot,
				PetFightBattleBridgeArtifact.CandidateFileName);
			File.WriteAllText(temporaryManifest, manifestJson, new UTF8Encoding(false));
			File.WriteAllBytes(temporaryCandidate, File.ReadAllBytes(path));
			PetFightBattleBridgeResourceRule loaded = new PetFightBattleBridgeResourceRule(temporaryManifest);
			File.Delete(temporaryCandidate);
			PetFightBattleBridgeResourceRule missingCandidate =
				new PetFightBattleBridgeResourceRule(temporaryManifest);
			fileLoadChecks = loaded.IsAvailable && loaded.SupportedVersion == rule.SupportedVersion &&
				!missingCandidate.IsAvailable;
		}
		finally
		{
			Directory.Delete(temporaryRoot, recursive: true);
		}

		string unknownFieldManifest = manifestJson.Insert(manifestJson.IndexOf('{') + 1, "\n  \"unknown\": true,");
		string duplicateFieldManifest = manifestJson.Insert(
			manifestJson.IndexOf('{') + 1,
			"\n  \"schemaVersion\": 1,");
		string invalidSchemaManifest = manifestJson.Replace("\"schemaVersion\": 1", "\"schemaVersion\": 2");
		string traversalManifest = manifestJson.Replace(
			PetFightBattleBridgeArtifact.CandidateFileName,
			"..\\escape.swf");
		string invalidHashManifest = manifestJson.Replace(
			rule.ExpectedTemplateSha256,
			new string('0', 64));
		JObject invalidLengthDocument = JObject.Parse(manifestJson);
		invalidLengthDocument["candidateLength"] = File.ReadAllBytes(path).Length + 1;
		JObject invalidTypeDocument = JObject.Parse(manifestJson);
		invalidTypeDocument["candidateLength"] = "6555602";
		JObject missingFieldDocument = JObject.Parse(manifestJson);
		missingFieldDocument.Property("symbolClassSha256")?.Remove();
		JObject invalidUrlDocument = JObject.Parse(manifestJson);
		invalidUrlDocument["officialUrl"] = "https://example.test/petfightnew.swf";
		return fileLoadChecks && !unavailable.IsAvailable &&
			unavailable.Evaluate(new ResourceRequestContext(exactUrl, "GET", "Other")).Outcome ==
				ResourceInterceptionOutcome.PassThrough &&
			newerVersion.Outcome == ResourceInterceptionOutcome.LocalResponse &&
			newerVersion.CacheKey == matched.CacheKey &&
			newerVersion.MaximumResponseBytes == matched.MaximumResponseBytes &&
			rule.Evaluate(new ResourceRequestContext(
				"https://aola.100bt.com/play/pet/petfightnew~0.swf",
				"GET", "Other")).Outcome == ResourceInterceptionOutcome.LocalResponse &&
			rule.Evaluate(new ResourceRequestContext(
				"https://aola.100bt.com/play/pet/petfightnew~" +
				rule.SupportedVersion + ".swf.bak",
				"GET", "Other")).Outcome ==
				ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(exactUrl, "POST", "Other")).Outcome ==
				ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(
				"https://example.test/play/pet/petfightnew~" +
					rule.SupportedVersion + ".swf",
				"GET", "Other")).Outcome == ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(
				"https://aola.100bt.com/PLAY/pet/petfightnew~" +
					rule.SupportedVersion + ".swf",
				"GET", "Other")).Outcome == ResourceInterceptionOutcome.PassThrough &&
			Throws<ArgumentException>(() => new PetFightBattleBridgeResourceRule(manifestJson, tampered)) &&
			Throws<ArgumentException>(() => new PetFightBattleBridgeResourceRule(unknownFieldManifest, File.ReadAllBytes(path))) &&
			Throws<ArgumentException>(() => new PetFightBattleBridgeResourceRule(duplicateFieldManifest, File.ReadAllBytes(path))) &&
			Throws<ArgumentException>(() => new PetFightBattleBridgeResourceRule(invalidSchemaManifest, File.ReadAllBytes(path))) &&
			Throws<ArgumentException>(() => new PetFightBattleBridgeResourceRule(traversalManifest, File.ReadAllBytes(path))) &&
			Throws<ArgumentException>(() => new PetFightBattleBridgeResourceRule(invalidHashManifest, File.ReadAllBytes(path))) &&
			Throws<ArgumentException>(() => new PetFightBattleBridgeResourceRule(invalidLengthDocument.ToString(), File.ReadAllBytes(path))) &&
			Throws<ArgumentException>(() => new PetFightBattleBridgeResourceRule(invalidTypeDocument.ToString(), File.ReadAllBytes(path))) &&
			Throws<ArgumentException>(() => new PetFightBattleBridgeResourceRule(missingFieldDocument.ToString(), File.ReadAllBytes(path))) &&
			Throws<ArgumentException>(() => new PetFightBattleBridgeResourceRule(invalidUrlDocument.ToString(), File.ReadAllBytes(path)));
	}

	private static byte[] CreateStartBridgeTemplate(bool includeLoadBytesMarker)
	{
		string body = "aolaSendCommand|aolaOpenPanel|aolaSetPlayback|aolaCommandCompleted|" +
			"mmo.play.actthings.data.ActClientSender|mmo.play.activity.helper.Panel_Helper|" +
			"ApplicationDomain|loader.swf" + (includeLoadBytesMarker ? "|loadBytes" : string.Empty);
		byte[] bodyBytes = Encoding.ASCII.GetBytes(body);
		byte[] content = new byte[8 + bodyBytes.Length];
		content[0] = (byte)'F';
		content[1] = (byte)'W';
		content[2] = (byte)'S';
		content[3] = 18;
		Buffer.BlockCopy(BitConverter.GetBytes((uint)content.Length), 0, content, 4, 4);
		Buffer.BlockCopy(bodyBytes, 0, content, 8, bodyBytes.Length);
		return content;
	}

	internal static bool VerifyRemotePlanExecutor()
	{
		const string originalUrl = "https://aola.100bt.com/original.swf";
		const string targetUrl = "https://aola.100bt.com/target.swf";
		int probeCalls = 0;
		int fetchCalls = 0;
		DelegateRemoteResourceProbe probe = new DelegateRemoteResourceProbe((request, token) =>
		{
			probeCalls++;
			return Task.FromResult(RemoteResourceProbeResult.Success(206, 3));
		});
		DelegateRemoteResourceFetcher fetcher = new DelegateRemoteResourceFetcher((request, token) =>
		{
			fetchCalls++;
			byte[] fetched = { 1, 2, 3 };
			RemoteResourceFetchResult result = RemoteResourceFetchResult.Success(
				200,
				"application/x-shockwave-flash",
				fetched);
			fetched[0] = 99;
			return Task.FromResult(result);
		});
		DelegateResourceResponseTransformer transformer = new DelegateResourceResponseTransformer(
			"test.remote",
			"bounded bytes",
			input =>
			{
				byte[] transformed = input.Content;
				transformed[0] = 7;
				return ResourceTransformResult.Success(transformed, "application/x-shockwave-flash");
			});
		ResourceInterceptionPlan plan = ResourceInterceptionPlan.RewriteRemote(
			originalUrl,
			targetUrl,
			"application/x-shockwave-flash",
			transformer,
			originalUrl,
			"remote:test:v1",
			"remote.test",
			16);
		ResourceTransformResult succeeded = new RemoteResourcePlanExecutor(probe, fetcher)
			.ExecuteAsync(plan, CancellationToken.None).GetAwaiter().GetResult();
		if (!succeeded.Succeeded || succeeded.Content[0] != 7 || succeeded.Content.Length != 3 ||
			probeCalls != 1 || fetchCalls != 1)
		{
			return false;
		}

		int blockedFetchCalls = 0;
		RemoteResourcePlanExecutor unavailable = new RemoteResourcePlanExecutor(
			new DelegateRemoteResourceProbe((request, token) => Task.FromResult(
				RemoteResourceProbeResult.Reject("probe.unavailable", "missing", 404, 0))),
			new DelegateRemoteResourceFetcher((request, token) =>
			{
				blockedFetchCalls++;
				return Task.FromResult(RemoteResourceFetchResult.Success(
					200,
					"application/x-shockwave-flash",
					new byte[] { 1 }));
			}));
		ResourceTransformResult rejected = unavailable.ExecuteAsync(plan, CancellationToken.None)
			.GetAwaiter().GetResult();
		return !rejected.Succeeded && rejected.RejectionCode == "probe.unavailable" &&
			blockedFetchCalls == 0 &&
			Throws<ArgumentOutOfRangeException>(() => RemoteResourceFetchResult.Reject(
				"bad.status",
				"bad",
				99));
	}

	private static bool VerifyBattlePetMovieRule()
	{
		if (BattleMorphRuleValidation.Validate(new BattleMorphRule("ok", 6000, 6047)) != null ||
			BattleMorphRuleValidation.Validate(new BattleMorphRule("old", 4400, 6047)) == null ||
			BattleMorphRuleValidation.Validate(new BattleMorphRule("digits", 6000, 10000)) == null ||
			BattleMorphRuleValidation.Validate(new BattleMorphRule("same", 6000, 6000)) == null)
		{
			return false;
		}

		string catalogPath = Path.GetTempFileName();
		try
		{
			File.WriteAllText(catalogPath,
				"{\"schemaVersion\":1,\"versionDataVersion\":\"20260904363779370\"," +
				"\"versionDataSha256\":\"" + new string('a', 64) + "\",\"defaultVersion\":\"1210\"," +
				"\"entries\":{\"fightassets/bitmap/pet6047/pet6047_1_0\":\"777\"}}",
				new UTF8Encoding(false));
			BattlePetMovieVersionCatalog catalog = BattlePetMovieVersionCatalog.Load(catalogPath);
			if (!catalog.IsAvailable ||
				catalog.GetVersion("fightassets/bitmap/pet6047/pet6047_1_0") != "777" ||
				catalog.GetVersion("fightassets/bitmap/pet6047/pet6047_2_2") != "1210" ||
				catalog.GetVersion("pet6047_2_2") != null)
			{
				return false;
			}

			Dictionary<int, string> versions = new Dictionary<int, string>();
			Dictionary<int, byte[]> contents = new Dictionary<int, byte[]>();
			for (int face = 1; face <= 2; face++)
			{
				for (int part = 0; part <= 2; part++)
				{
					string path = "fightassets/bitmap/pet6047/pet6047_" + face + "_" + part;
					int key = face * 10 + part;
					versions[key] = catalog.GetVersion(path);
					string body = (part == 0 ? "Pet6047Config_" + face + "|" : string.Empty) +
						"mmo.petfight.bitmap.pet6047_" + face + "_stand_0|pet6047_" + face + "_attack_0";
					ResourceTransformResult transformed = new BattlePetMovieResourceTransformer(6000, 6047, face, part)
						.Transform(new ResourceTransformInput(
							"https://aola.100bt.com/play/" + path + "~" + versions[key] + ".swf",
							200,
							"application/x-shockwave-flash",
							CreateBattlePetTemplate(body)));
					if (!transformed.Succeeded) return false;
					contents[key] = transformed.Content;
				}
			}
			BattlePetMovieResourceRule rule = new BattlePetMovieResourceRule();
			const string firstUrl =
				"https://aola.100bt.com/play/fightassets/bitmap/pet6000/pet6000_1_0~999.swf?cache=1";
			if (rule.Evaluate(new ResourceRequestContext(firstUrl, "GET", "Other")).Outcome !=
				ResourceInterceptionOutcome.PassThrough)
			{
				return false;
			}
			rule.SetRules(new[]
			{
				new PreparedBattleMorphRule(new BattleMorphRule("证据", 6000, 6047), versions, contents)
			}, enabled: true);

			for (int face = 1; face <= 2; face++)
			{
				for (int part = 0; part <= 2; part++)
				{
					string originalUrl = "https://aola.100bt.com/play/fightassets/bitmap/pet6000/pet6000_" +
						face + "_" + part + "~999.swf?cache=1";
					ResourceInterceptionPlan plan = rule.Evaluate(
						new ResourceRequestContext(originalUrl, "GET", "Other"));
					string expectedVersion = face == 1 && part == 0 ? "777" : "1210";
					if (plan.Outcome != ResourceInterceptionOutcome.LocalResponse ||
						!plan.CacheKey.EndsWith(":" + expectedVersion, StringComparison.Ordinal) ||
						CountAscii(plan.LocalContent, "pet6047") != 0 ||
						CountAscii(plan.LocalContent, "pet6000") == 0)
					{
						return false;
					}
				}
			}
			string evidenceRoot = Path.Combine(
				AppDomain.CurrentDomain.BaseDirectory,
				"TestData",
				"BattlePetMovie");
			for (int face = 1; face <= 2; face++)
			{
				for (int part = 0; part <= 2; part++)
				{
					string evidencePath = Path.Combine(evidenceRoot, "pet6047_" + face + "_" + part + "~1210.swf");
					if (!File.Exists(evidencePath)) return false;
					ResourceTransformResult evidence = new BattlePetMovieResourceTransformer(6000, 6047, face, part).Transform(
						new ResourceTransformInput(
							"https://aola.100bt.com/play/fightassets/bitmap/pet6047/pet6047_" + face + "_" + part + "~1210.swf",
							200,
							"application/x-shockwave-flash",
							File.ReadAllBytes(evidencePath)));
					if (!evidence.Succeeded || evidence.Content.Length < 8 || evidence.Content[0] != (byte)'F' ||
						BitConverter.ToUInt32(evidence.Content, 4) != evidence.Content.Length ||
						CountAscii(evidence.Content, "pet6047") != 0 || CountAscii(evidence.Content, "pet6000") == 0)
					{
						return false;
					}
				}
			}

			ResourceTransformResult mixed = new BattlePetMovieResourceTransformer(6000, 6047, 1, 0).Transform(
				new ResourceTransformInput(firstUrl, 200, "application/x-shockwave-flash",
					CreateBattlePetTemplate("Pet6047|pet6047|pet6000")));
			ResourceTransformResult damaged = new BattlePetMovieResourceTransformer(6000, 6047, 1, 0).Transform(
				new ResourceTransformInput(firstUrl, 200, "application/x-shockwave-flash", new byte[] { 1, 2, 3 }));
			return !mixed.Succeeded && mixed.RejectionCode == "battle.class_contract_mixed" &&
				!damaged.Succeeded && damaged.RejectionCode == "battle.swf_decode_failed" &&
				rule.Evaluate(new ResourceRequestContext(firstUrl, "POST", "Other")).Outcome ==
					ResourceInterceptionOutcome.PassThrough &&
				rule.Evaluate(new ResourceRequestContext(
					"https://example.test/play/fightassets/bitmap/pet6000/pet6000_1_0~999.swf",
					"GET", "Other")).Outcome == ResourceInterceptionOutcome.PassThrough &&
				rule.Evaluate(new ResourceRequestContext(
					"https://aola.100bt.com/play/fightassets/bitmap/pet6000/pet6001_1_0~999.swf",
					"GET", "Other")).Outcome == ResourceInterceptionOutcome.PassThrough;
		}
		finally
		{
			File.Delete(catalogPath);
		}
	}

	private static byte[] CreateBattlePetTemplate(string body)
	{
		byte[] bodyBytes = Encoding.ASCII.GetBytes(body);
		byte[] content = new byte[8 + bodyBytes.Length];
		content[0] = (byte)'F';
		content[1] = (byte)'W';
		content[2] = (byte)'S';
		content[3] = 18;
		Buffer.BlockCopy(BitConverter.GetBytes((uint)content.Length), 0, content, 4, 4);
		Buffer.BlockCopy(bodyBytes, 0, content, 8, bodyBytes.Length);
		return content;
	}

	private static bool VerifyPetMovieRule()
	{
		const string originalUrl =
			"https://aola.100bt.com/play/peticon/movie/type0/petmovie5486/petmovie5486_0~v1.swf?cache=1";
		PetMovieResourceRule rule = new PetMovieResourceRule();
		if (rule.Evaluate(new ResourceRequestContext(originalUrl, "GET", "Other")).Outcome !=
			ResourceInterceptionOutcome.PassThrough)
		{
			return false;
		}
		rule.SetRules(new[]
		{
			new AolaPetMorphRule("swap", 5486, 5530, 0, 0)
		}, enabled: true);
		ResourceInterceptionPlan plan = rule.Evaluate(
			new ResourceRequestContext(originalUrl, "GET", "Other"));
		if (plan.Outcome != ResourceInterceptionOutcome.RewriteRemote ||
			!plan.TargetUrl.Contains("/petmovie5530/petmovie5530_0~v1.swf", StringComparison.Ordinal) ||
			!plan.TargetUrl.Contains("_aolaMorph=m-5486-5530-0", StringComparison.Ordinal) ||
			plan.FallbackUrl != originalUrl || plan.MaximumResponseBytes != 16 * 1024 * 1024)
		{
			return false;
		}

		byte[] remote = CreateThemeTemplate("PetMovie5530", 45);
		ResourceTransformResult transformed = plan.Transformer.Transform(new ResourceTransformInput(
			plan.TargetUrl,
			200,
			"application/x-shockwave-flash",
			remote));
		if (!transformed.Succeeded || CountAscii(transformed.Content, "PetMovie5486") != 45 ||
			CountAscii(transformed.Content, "PetMovie5530") != 0)
		{
			return false;
		}
		ResourceTransformResult wrongCount = plan.Transformer.Transform(new ResourceTransformInput(
			plan.TargetUrl,
			200,
			"application/x-shockwave-flash",
			CreateThemeTemplate("PetMovie5530", 44)));
		if (wrongCount.Succeeded || wrongCount.RejectionCode != "swf.class_contract_failed")
		{
			return false;
		}

		rule.SetRules(new[]
		{
			new AolaPetMorphRule("hide", 6000, 0, 0, 0, hideOriginalModel: true)
		}, enabled: true);
		ResourceInterceptionPlan hidden = rule.Evaluate(new ResourceRequestContext(
			"https://aola.100bt.com/play/peticon/movie/type0/petmovie6000/petmovie6000_2.swf",
			"GET",
			"Other"));
		return hidden.Outcome == ResourceInterceptionOutcome.RewriteRemote &&
			hidden.TargetUrl.Contains("/petmovie6025/petmovie6025_2.swf", StringComparison.Ordinal) &&
			rule.Evaluate(new ResourceRequestContext(
				"https://aola.100bt.com/play/peticon/movie/type0/petmovie6000/petmovie6001_2.swf",
				"GET",
				"Other")).Outcome == ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(
				"https://example.test/play/peticon/movie/type0/petmovie6000/petmovie6000_2.swf",
				"GET",
				"Other")).Outcome == ResourceInterceptionOutcome.PassThrough;
	}

	private static bool VerifyPetPosterRule()
	{
		string catalogPath = Path.GetTempFileName();
		try
		{
			File.WriteAllText(catalogPath,
				"{\"SchemaVersion\":1,\"Source\":\"verify\",\"SourceSha256\":\"verify\"," +
				"\"Entries\":[{\"SkinId\":5487,\"ResourceId\":733,\"Name\":\"source\"," +
				"\"HasBackground\":true,\"ShowPet\":true},{\"SkinId\":5940,\"ResourceId\":984," +
				"\"Name\":\"target\",\"HasBackground\":true,\"ShowPet\":true}]}");
			PetPosterResourceRule rule = new PetPosterResourceRule(AolaPetPosterCatalog.Load(catalogPath));
			const string originalUrl =
				"https://aola.100bt.com/play/pet/petskin/background/petskinbackground733~1210.swf?cache=1";
			if (rule.Evaluate(new ResourceRequestContext(originalUrl, "GET", "Other")).Outcome !=
				ResourceInterceptionOutcome.PassThrough)
			{
				return false;
			}
			rule.SetRules(new[]
			{
				new AolaPetMorphRule("poster", 0, 0, 5487, 5940)
			}, enabled: true);
			ResourceInterceptionPlan plan = rule.Evaluate(
				new ResourceRequestContext(originalUrl, "GET", "Other"));
			return plan.Outcome == ResourceInterceptionOutcome.RewriteRemote &&
				plan.TargetUrl.Contains("petskinbackground984~1210.swf", StringComparison.Ordinal) &&
				plan.TargetUrl.Contains("_aolaMorph=p-733-984", StringComparison.Ordinal) &&
				plan.FallbackUrl == originalUrl && plan.MaximumResponseBytes == 16 * 1024 * 1024 &&
				rule.Evaluate(new ResourceRequestContext(originalUrl, "POST", "Other")).Outcome ==
					ResourceInterceptionOutcome.PassThrough &&
				rule.Evaluate(new ResourceRequestContext(
					"https://example.test/play/pet/petskin/background/petskinbackground733~1210.swf",
					"GET",
					"Other")).Outcome == ResourceInterceptionOutcome.PassThrough;
		}
		finally
		{
			File.Delete(catalogPath);
		}
	}

	private static bool Throws<TException>(Action action) where TException : Exception
	{
		try
		{
			action();
			return false;
		}
		catch (TException)
		{
			return true;
		}
	}
}
