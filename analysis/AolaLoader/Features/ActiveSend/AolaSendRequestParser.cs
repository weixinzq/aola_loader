// 架构角色：把用户输入的命令与 JSON 参数解析为受约束的 AolaSendRequest。
// 数据流：文本输入 -> schema/类型校验 -> 发送 DTO 或可显示错误。
using System;
using System.Collections.Generic;
using System.Linq;
using AolaSocketHack.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.ActiveSend;

internal static class AolaSendRequestParser
{
	private static readonly string[] RequiredPropertyOrder = { "id", "param", "cmd" };

	public static List<AolaSendRequest> ParseLines(string input)
	{
		List<string> lines = (input ?? string.Empty).Replace("\r\n", "\n").Split('\n')
			.Select(line => line.Trim().TrimStart('\uFEFF'))
			.Where(line => line.Length != 0)
			.ToList();
		if (lines.Count == 0)
		{
			throw new InvalidOperationException("请输入至少一条 #send={...}| 消息。");
		}

		List<AolaSendRequest> requests = new List<AolaSendRequest>();
		for (int index = 0; index < lines.Count; index++)
		{
			string line = lines[index];
			if (!line.StartsWith("#send={", StringComparison.Ordinal) ||
				!line.EndsWith("}|", StringComparison.Ordinal))
			{
				throw new InvalidOperationException(string.Format(
					"第 {0} 行必须严格使用 #send={{\"id\":42,\"param\":{{}},\"cmd\":\"CMD\"}}| 格式。",
					index + 1));
			}

			JObject message = JObject.Parse(
				line.Substring(6, line.Length - 7),
				new JsonLoadSettings { DuplicatePropertyNameHandling = DuplicatePropertyNameHandling.Error });
			if (!message.Properties().Select(property => property.Name).SequenceEqual(RequiredPropertyOrder))
			{
				throw new InvalidOperationException(string.Format(
					"第 {0} 行只能按 id、param、cmd 顺序包含这三个字段。", index + 1));
			}

			JToken idToken = message["id"];
			JToken commandToken = message["cmd"];
			JToken parametersToken = message["param"];
			if (idToken.Type != JTokenType.Integer ||
				idToken.Value<long>() < 0 || idToken.Value<long>() > ushort.MaxValue)
			{
				throw new InvalidOperationException(string.Format(
					"第 {0} 行 id 必须是 0..65535 的整数。", index + 1));
			}
			string command = commandToken.Type == JTokenType.String
				? commandToken.Value<string>()
				: null;
			if (string.IsNullOrWhiteSpace(command) || command.Length > 256 ||
				!string.Equals(command, command.Trim(), StringComparison.Ordinal))
			{
				throw new InvalidOperationException(string.Format(
					"第 {0} 行 cmd 必须是不含首尾空白且不超过 256 字符的非空字符串。", index + 1));
			}
			if (!(parametersToken is JObject parameters))
			{
				throw new InvalidOperationException(string.Format(
					"第 {0} 行 param 必须是 JSON 对象。", index + 1));
			}

			parameters = (JObject)parameters.DeepClone();
			parameters.Remove(":ext_seq;");
			requests.Add(new AolaSendRequest
			{
				ExtensionId = idToken.Value<int>(),
				Command = command,
				ParametersJson = parameters.ToString(Formatting.None)
			});
		}
		return requests;
	}
}
