// 架构角色：独立的面板调用采集脚本，拥有自己的回调和队列。
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.BrowserHost;

internal static class PanelCapturePageScript
{
	public static string Build(string operation, JObject arguments)
	{
		return @"(function (operation, args) {
	var state = window.__aolaPanelCapture;
	if (!state) state = window.__aolaPanelCapture = { enabled: false, items: [], dropped: 0 };
	if (operation === 'panelCapture.poll') {
		state.enabled = !!args.enabled;
		window.aolaPanelCaptured = function (url, cls) {
			if (!state.enabled) return;
			if (state.items.length >= 1000) { state.items.shift(); state.dropped++; }
			state.items.push({ time: new Date().toISOString(), url: url, cls: cls });
		};
	} else if (operation === 'panelCapture.stop') {
		state.enabled = false;
	}
	var items = state.items.splice(0);
	var dropped = state.dropped;
	state.dropped = 0;
	return JSON.stringify({ ok: true, value: { items: items, dropped: dropped }, failure: '', message: '' });
})(" + JsonConvert.SerializeObject(operation) + "," + (arguments ?? new JObject()).ToString(Formatting.None) + ")";
	}
}
