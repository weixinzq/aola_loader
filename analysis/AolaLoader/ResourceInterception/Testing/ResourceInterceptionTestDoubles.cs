// 架构角色：资源管线各端口的委托式测试替身，支持精确注入规则、探测、获取和变换行为。
// 数据流：测试 Lambda <-> pipeline，被测调用与结果均可观察。
using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.ResourceInterception.Testing;

internal sealed class DelegateResourceInterceptionRule : IResourceInterceptionRule
{
	private readonly Func<ResourceRequestContext, ResourceInterceptionPlan> _evaluate;

	public DelegateResourceInterceptionRule(
		string name,
		int priority,
		string pathOwnership,
		Func<ResourceRequestContext, ResourceInterceptionPlan> evaluate)
	{
		if (string.IsNullOrWhiteSpace(name))
		{
			throw new ArgumentException("Rule name is required.", nameof(name));
		}
		if (string.IsNullOrWhiteSpace(pathOwnership))
		{
			throw new ArgumentException("Path ownership is required.", nameof(pathOwnership));
		}
		Name = name;
		Priority = priority;
		PathOwnership = pathOwnership;
		_evaluate = evaluate ?? throw new ArgumentNullException(nameof(evaluate));
	}

	public string Name { get; }

	public int Priority { get; }

	public string PathOwnership { get; }

	public ResourceInterceptionPlan Evaluate(ResourceRequestContext request)
	{
		return _evaluate(request);
	}
}

internal sealed class DelegateResourceResponseTransformer : IResourceResponseTransformer
{
	private readonly Func<ResourceTransformInput, ResourceTransformResult> _transform;

	public DelegateResourceResponseTransformer(
		string name,
		string inputContract,
		Func<ResourceTransformInput, ResourceTransformResult> transform)
	{
		if (string.IsNullOrWhiteSpace(name))
		{
			throw new ArgumentException("Transformer name is required.", nameof(name));
		}
		if (string.IsNullOrWhiteSpace(inputContract))
		{
			throw new ArgumentException("Input contract is required.", nameof(inputContract));
		}
		Name = name;
		InputContract = inputContract;
		_transform = transform ?? throw new ArgumentNullException(nameof(transform));
	}

	public string Name { get; }

	public string InputContract { get; }

	public ResourceTransformResult Transform(ResourceTransformInput input)
	{
		return _transform(input);
	}
}

internal sealed class DelegateRemoteResourceProbe : IRemoteResourceProbe
{
	private readonly Func<RemoteResourceProbeRequest, CancellationToken, Task<RemoteResourceProbeResult>> _probe;

	public DelegateRemoteResourceProbe(
		Func<RemoteResourceProbeRequest, CancellationToken, Task<RemoteResourceProbeResult>> probe)
	{
		_probe = probe ?? throw new ArgumentNullException(nameof(probe));
	}

	public Task<RemoteResourceProbeResult> ProbeAsync(
		RemoteResourceProbeRequest request,
		CancellationToken cancellationToken)
	{
		return _probe(request, cancellationToken);
	}
}

internal sealed class DelegateRemoteResourceFetcher : IRemoteResourceFetcher
{
	private readonly Func<RemoteResourceFetchRequest, CancellationToken, Task<RemoteResourceFetchResult>> _fetch;

	public DelegateRemoteResourceFetcher(
		Func<RemoteResourceFetchRequest, CancellationToken, Task<RemoteResourceFetchResult>> fetch)
	{
		_fetch = fetch ?? throw new ArgumentNullException(nameof(fetch));
	}

	public Task<RemoteResourceFetchResult> FetchAsync(
		RemoteResourceFetchRequest request,
		CancellationToken cancellationToken)
	{
		return _fetch(request, cancellationToken);
	}
}
