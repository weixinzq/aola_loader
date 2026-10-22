using Newtonsoft.Json.Linq;

namespace AolaTestServer;

internal static class TestPlayer
{
	public const int Id = 10001;
	public const string Session = "aola-local-test-session";
	public const string Zone = "local-test";
	public const string Scene = "chunqingmuchang";
	public const string Name = "测试奥拉";
	public const string Avatar = "0#6;7;72;73;741;742";

	public static JObject Variables() => new JObject
	{
		["nns"] = Name, ["avatar"] = Avatar, ["c"] = Avatar, ["mtype"] = 0,
		["pt"] = "480,320", ["action"] = "", ["ms"] = "", ["dir"] = 0
	};

	public static JObject Response(string command)
	{
		JObject data;
		switch (command)
		{
			case "getCurrentTime": data = new JObject { ["t"] = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() }; break;
			case "getStartInfo": data = new JObject { ["dd"] = Id.ToString(), ["vfl"] = false }; break;
			case "11_1":
				data = new JObject
				{
					["open"] = false, ["privileges"] = "", ["services"] = new JArray(),
					["memberType"] = 0, ["vipLevel"] = 0, ["vipScore"] = 0, ["oym"] = 0,
					["fop"] = 0, ["hbm"] = 0, ["isRmember"] = false, ["rlevel"] = 0,
					["cd"] = 0, ["rSc"] = 0
				};
				break;
			case "getOneOffState": data = new JObject { ["state"] = "0,0" }; break;
			case "getLifeDay": data = new JObject { ["life"] = 1 }; break;
			case "10-0": data = JObject.Parse("{\"t\":[{\"s\":\"150,1/10491,1\",\"a\":0,\"f\":0}],\"ou\":false,\"lv\":1}"); break;
			case "1101":
				data = new JObject
				{
					["simpleView"] = new JObject { ["pmmId"] = Id, ["slotId"] = 0, ["pmCanBattle"] = 0, ["pmExp"] = 0, ["access"] = true, ["maxce"] = 0 },
					["clv"] = 1, ["ccle"] = 0, ["clu%"] = 0, ["cnx"] = 0
				};
				break;
			case "1212": data = new JObject { ["pmList"] = new JArray(), ["pms"] = "", ["cui"] = 0, ["prv"] = new JArray() }; break;
			case "getUserClothes":
				data = new JObject
				{
					["cl"] = "6,1;7,1;72,1;73,1;741,1;742,1;6534,2;6536,2;6541,2;6542,2;6543,2;6544,2;6545,2;6546,2;6547,2;6563,2;6548,4;6550,4;6556,4;6557,4;6558,4;6559,4;6560,4;6561,4;6562,4;6564,4",
					["uds"] = new JArray(), ["idp"] = 0, ["dp"] = new JArray(0, 0, 0), ["mi"] = 0, ["csl"] = new JArray()
				};
				break;
			case "14_2": data = new JObject { ["userms"] = new JArray(), ["period"] = new JArray() }; break;
			case "61_6": data = new JObject { ["clothes"] = new JArray() }; break;
			case "61_7":
			case "61-8": data = new JObject { ["cards"] = new JArray() }; break;
			case "80_1": data = new JObject { ["userPlants"] = new JArray() }; break;
			case "61_1": data = new JObject { ["furnitures"] = new JArray() }; break;
			case "81_2": data = new JObject { ["items"] = new JArray() }; break;
			case "getUserInscription": data = new JObject { ["inscriptions"] = new JArray() }; break;
			case "MaxInscriptionResponder_1": data = new JObject { ["r"] = 1, ["amount"] = new JArray() }; break;
			case "21_30": data = new JObject { ["gal"] = new JArray() }; break;
			case "77_1": data = new JObject { ["index"] = 0, ["equips"] = new JArray(), ["redefinetimes"] = 0 }; break;
			case "21_20": data = new JObject { ["xl"] = new JArray(), ["nxl"] = new JArray() }; break;
			case "2-6": data = new JObject { ["i"] = new JArray() }; break;
			case "ASC221104_0":
			case "ACK241227_0": data = new JObject { ["cl"] = new JArray() }; break;
			case "ASC221104_3": data = new JObject { ["gs"] = new JArray() }; break;
			case "UiSkinStyle240927_0": data = new JObject { ["uss"] = new JArray() }; break;
			case "ATT231229_0": data = new JObject { ["utl"] = new JArray() }; break;
			case "APTT250829_0": data = new JObject { ["pts"] = new JArray() }; break;
			case "71_20": data = new JObject { ["vList"] = new JArray(), ["vc"] = 0 }; break;
			case "64_5": data = new JObject { ["cards"] = new JArray() }; break;
			case "70-1": data = new JObject { ["b"] = new JArray() }; break;
			case "71_5": data = new JObject { ["ti"] = "" }; break;
			case "PMMLevelSystem_p": data = new JObject { ["ce"] = 0, ["pmme"] = 0, ["sid"] = -1, ["ltUp"] = 0, ["slv"] = new JArray() }; break;
			case "55_9":
				data = new JObject
				{
					["GameRealInfo"] = new JObject { ["duoduoId"] = Id.ToString(), ["needRealName"] = false, ["speakLimit"] = false, ["onlineLimit"] = false, ["onlineLimitMinute"] = 0, ["onlineLimitTime"] = "" },
					["NppaRealNameStatus"] = new JObject { ["nppaStatus"] = 0 }, ["state"] = 1
				};
				break;
			case "55_1": data = new JObject { ["time"] = 120, ["loginTime"] = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(), ["day"] = 1, ["ih"] = false, ["fake"] = false, ["forceAnti"] = false, ["off_anti"] = false }; break;
			case "gethbclothes": data = new JObject { ["s"] = 0, ["bi"] = 0, ["cl"] = "70001,1;70002,1;70003,1;70004,1;70016,1;70017,1" }; break;
			case "1-7":
			case "1-8": data = new JObject { ["es"] = new JArray(), ["pmList"] = new JArray() }; break;
			case "ConnectTest": data = new JObject(); break;
			default: return null;
		}
		data["_cmd"] = command == "11_1" ? "11_1r" : command == "1101" ? "2101" : command == "1212" ? "2212" : command;
		return data;
	}
}
