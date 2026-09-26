// 架构角色：资源规则的最小策略接口；实现只评估请求并返回计划，不依赖 CefSharp 回调对象。
// 数据流：ResourceRequestContext -> ResourceInterceptionPlan。
namespace AolaLoader.ResourceInterception.Contracts;

internal interface IResourceInterceptionRule
{
	string Name { get; }

	int Priority { get; }

	string PathOwnership { get; }

	ResourceInterceptionPlan Evaluate(ResourceRequestContext request);
}

