namespace AolaLoader.ResourceInterception.Contracts;

internal interface IResourceInterceptionRule
{
	string Name { get; }

	int Priority { get; }

	string PathOwnership { get; }

	ResourceInterceptionPlan Evaluate(ResourceRequestContext request);
}

