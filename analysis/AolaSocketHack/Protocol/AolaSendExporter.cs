using System;
using AolaSocketHack.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Protocol;

public static class AolaSendExporter
{
	public static bool TryCreateLine(AolaPacketEvent packet, out string line)
	{
		line = null;
		if (packet == null || !packet.CanExport || !packet.ExtensionId.HasValue ||
			packet.ExtensionId.Value < 0 || packet.ExtensionId.Value > ushort.MaxValue ||
			string.IsNullOrWhiteSpace(packet.Command))
		{
			return false;
		}

		JObject parameters;
		try
		{
			parameters = string.IsNullOrWhiteSpace(packet.ParametersJson)
				? new JObject()
				: JObject.Parse(packet.ParametersJson);
		}
		catch (JsonException)
		{
			return false;
		}

		// The loader creates a fresh account-specific sequence when replaying.
		parameters.Remove(":ext_seq;");
		JObject message = new JObject
		{
			["id"] = packet.ExtensionId.Value,
			["param"] = parameters,
			["cmd"] = packet.Command
		};
		line = "#send=" + message.ToString(Formatting.None) + "|";
		return true;
	}
}
