using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader;
using AolaLoader.Features.PetMorph.ResourceInterception;
using AolaLoader.Features.Theme.ResourceInterception;
using AolaLoader.ResourceInterception.Contracts;
using AolaLoader.ResourceInterception.Pipeline;
using AolaLoader.ResourceInterception.Testing;

namespace AolaSocketHack.Verify;

internal static class ResourceInterceptionContractVerifier
{
	public static bool Verify()
	{
		return VerifyRequestContext() &&
			VerifyPlansAndRuleDouble() &&
			VerifyTransformContracts() &&
			VerifyProbeContracts() &&
			VerifyRulePipeline() &&
			VerifyBoundedResponseProcessor() &&
			VerifySwfHeaderAndProbeCache() &&
			VerifyThemeLeafRule() &&
			VerifyPetPackageLiveRule() &&
			VerifyRemotePlanExecutor() &&
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
		if (!SwfResponseHeaderValidator.IsSupported(fws, 8, 8, 1024) ||
			SwfResponseHeaderValidator.IsSupported(fws, 8, 9, 1024) ||
			!SwfResponseHeaderValidator.IsSupported(cws, 8, 32, 1024) ||
			!SwfResponseHeaderValidator.IsSupported(zws, 17, 20, 1024) ||
			SwfResponseHeaderValidator.IsSupported(zws, 17, 21, 1024))
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
		string exactUrl = "https://aola.100bt.com/play/pet/newpetpackage~" +
			PetPackageLiveResourceRule.SupportedVersion + ".swf?cache=1";
		ResourceInterceptionPlan matched = rule.Evaluate(
			new ResourceRequestContext(exactUrl, "GET", "Other"));
		byte[] firstRead = matched.LocalContent;
		if (!rule.IsAvailable || matched.Outcome != ResourceInterceptionOutcome.LocalResponse ||
			matched.ContentType != "application/x-shockwave-flash" || firstRead[8] == 0 ||
			CountAscii(firstRead, "aolaMorphResolveSkinId") != 1 ||
			CountAscii(firstRead, "aolaMorphRefresh") != 1 ||
			CountAscii(firstRead, "aolaMorphShouldHideBackground") != 1 ||
			CountAscii(firstRead, "aolaMorphResolveIconId") != 1)
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
				"https://aola.100bt.com/play/pet/newpetpackage~2026081331982424.swf",
				"GET",
				"Other")).Outcome == ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(
				"https://aola.100bt.com/play/pet/newpetpackage~" +
				PetPackageLiveResourceRule.SupportedVersion + ".swf.bak",
				"GET",
				"Other")).Outcome ==
				ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(exactUrl, "POST", "Other")).Outcome ==
				ResourceInterceptionOutcome.PassThrough &&
			rule.Evaluate(new ResourceRequestContext(
				"https://example.test/play/pet/newpetpackage~" +
				PetPackageLiveResourceRule.SupportedVersion + ".swf",
				"GET",
				"Other")).Outcome == ResourceInterceptionOutcome.PassThrough &&
			Throws<ArgumentException>(() => new PetPackageLiveResourceRule(
				CreatePetPackageTemplate(includeIconMarker: false)));
	}

	private static byte[] CreatePetPackageTemplate(bool includeIconMarker)
	{
		string body = "aolaMorphResolveSkinId|aolaMorphRefresh|aolaMorphShouldHideBackground" +
			(includeIconMarker ? "|aolaMorphResolveIconId" : string.Empty);
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

	private static bool VerifyRemotePlanExecutor()
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
