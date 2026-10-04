// 架构角色：解析文本序列，完整检查后返回宿主步骤，不产生发送副作用。
// 数据流：文本 -> Send/WaitBattleEnd/Delay；只有 Send 承载网络 DTO。
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using AolaSocketHack.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
namespace AolaLoader.Features.ActiveSend;

internal enum AolaTextStepKind { Send, WaitBattleEnd, Delay }
internal sealed class AolaTextStep
{
	public AolaTextStep(AolaTextStepKind kind, int line, AolaSendRequest request = null, double seconds = 0)
	{ Kind = kind; Line = line; Request = request; Seconds = seconds; }
	public AolaTextStepKind Kind { get; }
	public int Line { get; }
	public AolaSendRequest Request { get; }
	public double Seconds { get; }
}

internal static class AolaSendRequestParser
{
	public static List<AolaSendRequest> ParseLines(string input)
	{
		var steps = ParseSequence(input);
		if (steps.Any(step => step.Kind != AolaTextStepKind.Send))
			throw new InvalidOperationException("本地指令必须通过文本序列执行器执行。");
		return steps.Select(step => step.Request).ToList();
	}
	public static List<AolaTextStep> ParseSequence(string input)
	{
		string text = string.Join("\n", (input ?? "").Replace("\r\n", "\n").Split('\n')
			.Select(line => line.TrimStart('\uFEFF').TrimStart().StartsWith("//", StringComparison.Ordinal) ? "" : line)).TrimStart('\uFEFF');
		var steps = new List<AolaTextStep>();
		bool quoted = false, escaped = false;
		int start = 0, lineNumber = 1, startLine = 1;
		for (int index = 0; index <= text.Length; index++)
		{
			char c = index < text.Length ? text[index] : '|';
			if (index == text.Length || (c == '|' && !quoted))
			{
				string segment = text.Substring(start, index - start);
				int line = startLine + segment.TakeWhile(char.IsWhiteSpace).Count(ch => ch == '\n');
				if (!string.IsNullOrWhiteSpace(segment)) steps.Add(ParseStep(segment.Trim(), line));
				start = index + 1; startLine = lineNumber;
			}
			else if (quoted)
			{
				if (escaped) escaped = false;
				else if (c == '\\') escaped = true;
				else if (c == '"') quoted = false;
			}
			else if (c == '"') quoted = true;
			if (c == '\n') lineNumber++;
		}
		if (steps.Count == 0) throw new InvalidOperationException("请输入至少一条 #send、#wait 或 #time 指令。");
		return steps;
	}
	private static AolaTextStep ParseStep(string text, int line)
	{
		try
		{
			if (text == "#wait") return new AolaTextStep(AolaTextStepKind.WaitBattleEnd, line);
			if (text.StartsWith("#time", StringComparison.Ordinal))
			{
				string value = text.Substring(5).Trim();
				if (!value.StartsWith("=", StringComparison.Ordinal) ||
					!double.TryParse(value.Substring(1).Trim(), NumberStyles.AllowDecimalPoint | NumberStyles.AllowLeadingSign,
						CultureInfo.InvariantCulture, out double seconds) || double.IsNaN(seconds) || double.IsInfinity(seconds) || seconds < 0)
					throw new InvalidOperationException("#time = 秒数 必须指定有限、非负的十进制秒数。");
				return new AolaTextStep(AolaTextStepKind.Delay, line, seconds: seconds);
			}
			if (!text.StartsWith("#send=", StringComparison.Ordinal)) throw new InvalidOperationException("未知文本指令。");
			JObject message = JObject.Parse(text.Substring(6),
				new JsonLoadSettings { DuplicatePropertyNameHandling = DuplicatePropertyNameHandling.Error });
			if (message.Count != 3 || message["id"] == null || message["cmd"] == null || message["param"] == null)
				throw new InvalidOperationException("#send 必须包含 id、param、cmd 三个字段。");
			JToken id = message["id"];
			if (id.Type != JTokenType.Integer || id.Value<long>() < 0 || id.Value<long>() > ushort.MaxValue)
				throw new InvalidOperationException("id 必须是 0..65535 的整数。");
			string command = message["cmd"].Type == JTokenType.String ? message.Value<string>("cmd") : null;
			if (string.IsNullOrWhiteSpace(command) || command.Length > 256 || command != command.Trim())
				throw new InvalidOperationException("cmd 必须是不含首尾空白且不超过 256 字符的非空字符串。");
			if (!(message["param"] is JObject parameters)) throw new InvalidOperationException("param 必须是 JSON 对象。");
			parameters.Remove(":ext_seq;");
			return new AolaTextStep(AolaTextStepKind.Send, line, new AolaSendRequest
			{ ExtensionId = id.Value<int>(), Command = command, ParametersJson = parameters.ToString(Formatting.None) });
		}
		catch (Exception ex) when (ex is JsonException || ex is InvalidOperationException || ex is OverflowException)
		{ throw new InvalidOperationException(string.Format("第 {0} 行：{1}", line, ex.Message), ex); }
	}
}
