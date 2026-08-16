using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using AolaSocketHack.Contracts;
using AolaSocketHack.Protocol;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader;

internal sealed class AolaPacketsForm : Form
{
	private const int MaximumVisiblePackets = 5000;
	private readonly ListView _packetList = new ListView();
	private readonly RichTextBox _details = new RichTextBox();
	private readonly TextBox _sendInput = new TextBox();
	private readonly ToolStripStatusLabel _status = new ToolStripStatusLabel("等待奥拉星发送消息");
	private readonly List<AolaPacketEvent> _packets = new List<AolaPacketEvent>();

	public AolaPacketsForm()
	{
		Text = "奥拉星抓包 / 发包";
		StartPosition = FormStartPosition.CenterParent;
		MinimumSize = new Size(920, 620);
		Size = new Size(1180, 780);

		ToolStrip toolbar = new ToolStrip { GripStyle = ToolStripGripStyle.Hidden };
		ToolStripButton clearButton = new ToolStripButton("清空");
		ToolStripButton exportButton = new ToolStripButton("导出 #send");
		ToolStripButton useSelectedButton = new ToolStripButton("选中项填入发包区");
		ToolStripButton loadButton = new ToolStripButton("载入 #send 文件");
		ToolStripButton sendButton = new ToolStripButton("发送");
		clearButton.Click += delegate { ClearPackets(); };
		exportButton.Click += delegate { ExportPackets(); };
		useSelectedButton.Click += delegate { FillFromSelected(); };
		loadButton.Click += delegate { LoadSendFile(); };
		sendButton.Click += delegate { QueueSends(); };
		toolbar.Items.AddRange(new ToolStripItem[] { clearButton, exportButton, new ToolStripSeparator(), useSelectedButton, loadButton, sendButton });

		_packetList.Dock = DockStyle.Fill;
		_packetList.View = View.Details;
		_packetList.FullRowSelect = true;
		_packetList.HideSelection = false;
		_packetList.MultiSelect = true;
		_packetList.Columns.Add("时间", 95);
		_packetList.Columns.Add("长度", 60);
		_packetList.Columns.Add("OuterSeq", 105);
		_packetList.Columns.Add("Action", 70);
		_packetList.Columns.Add("ExtID", 65);
		_packetList.Columns.Add("Cmd", 210);
		_packetList.Columns.Add("摘要", 430);
		_packetList.SelectedIndexChanged += delegate { ShowSelectedPacket(); };

		_details.Dock = DockStyle.Fill;
		_details.ReadOnly = true;
		_details.Font = new Font("Consolas", 9f);
		_details.WordWrap = false;
		_sendInput.Dock = DockStyle.Fill;
		_sendInput.Multiline = true;
		_sendInput.AcceptsReturn = true;
		_sendInput.AcceptsTab = true;
		_sendInput.ScrollBars = ScrollBars.Both;
		_sendInput.WordWrap = false;
		_sendInput.Font = new Font("Consolas", 9f);
		_sendInput.Text = "#send={\"id\":42,\"param\":{},\"cmd\":\"\"}|";

		TabControl tabs = new TabControl { Dock = DockStyle.Fill };
		TabPage detailsPage = new TabPage("Inner 明文详情");
		TabPage sendPage = new TabPage("#send 发包");
		detailsPage.Controls.Add(_details);
		sendPage.Controls.Add(_sendInput);
		tabs.TabPages.Add(detailsPage);
		tabs.TabPages.Add(sendPage);

		SplitContainer split = new SplitContainer
		{
			Dock = DockStyle.Fill,
			Orientation = Orientation.Horizontal,
			SplitterDistance = 430
		};
		split.Panel1.Controls.Add(_packetList);
		split.Panel2.Controls.Add(tabs);
		StatusStrip statusStrip = new StatusStrip();
		statusStrip.Items.Add(_status);
		Controls.Add(split);
		Controls.Add(toolbar);
		Controls.Add(statusStrip);
		toolbar.Dock = DockStyle.Top;
		statusStrip.Dock = DockStyle.Bottom;

		AolaHookHostService.PacketReceived += OnPacketReceived;
		AolaHookHostService.StatusReceived += OnStatusReceived;
		AolaHookHostService.SendCompleted += OnSendCompleted;
	}

	protected override void OnFormClosed(FormClosedEventArgs e)
	{
		AolaHookHostService.PacketReceived -= OnPacketReceived;
		AolaHookHostService.StatusReceived -= OnStatusReceived;
		AolaHookHostService.SendCompleted -= OnSendCompleted;
		base.OnFormClosed(e);
	}

	private void OnPacketReceived(AolaPacketEvent packet)
	{
		if (packet == null || packet.Direction != "发送" || IsDisposed)
		{
			return;
		}
		if (InvokeRequired)
		{
			BeginInvoke(new Action<AolaPacketEvent>(OnPacketReceived), packet);
			return;
		}
		_packets.Add(packet);
		ListViewItem item = new ListViewItem(packet.TimestampUtc.ToLocalTime().ToString("HH:mm:ss.fff"));
		item.SubItems.Add(packet.FrameLength.ToString());
		item.SubItems.Add(packet.OuterSequence?.ToString() ?? string.Empty);
		item.SubItems.Add(packet.Action?.ToString() ?? string.Empty);
		item.SubItems.Add(packet.ExtensionId?.ToString() ?? string.Empty);
		item.SubItems.Add(packet.Command ?? string.Empty);
		item.SubItems.Add(packet.Summary ?? string.Empty);
		item.Tag = packet;
		item.ForeColor = !packet.DecodeSucceeded ? Color.DarkRed : packet.CanExport ? Color.DarkBlue : SystemColors.WindowText;
		_packetList.Items.Add(item);
		while (_packetList.Items.Count > MaximumVisiblePackets)
		{
			_packetList.Items.RemoveAt(0);
			_packets.RemoveAt(0);
		}
		UpdateCountStatus();
	}

	private void OnStatusReceived(AolaHookStatus status)
	{
		if (status == null || IsDisposed)
		{
			return;
		}
		if (InvokeRequired)
		{
			BeginInvoke(new Action<AolaHookStatus>(OnStatusReceived), status);
			return;
		}
		_status.Text = string.Format("[{0}] {1}", status.Level, status.Message);
	}

	private void OnSendCompleted(AolaSendResult result)
	{
		if (result == null || IsDisposed)
		{
			return;
		}
		if (InvokeRequired)
		{
			BeginInvoke(new Action<AolaSendResult>(OnSendCompleted), result);
			return;
		}
		_status.Text = (result.Succeeded ? "[发送成功] " : "[发送失败] ") + result.Message;
		if (!result.Succeeded)
		{
			MessageBox.Show(this, result.Message, "奥拉星发包", MessageBoxButtons.OK, MessageBoxIcon.Warning);
		}
	}

	private void ShowSelectedPacket()
	{
		if (_packetList.SelectedItems.Count == 0 || !(_packetList.SelectedItems[0].Tag is AolaPacketEvent packet))
		{
			return;
		}
		StringBuilder text = new StringBuilder();
		text.AppendLine("Socket: " + packet.SocketHandle);
		text.AppendLine("长度: " + packet.FrameLength);
		text.AppendLine("OuterSeq: " + (packet.OuterSequence?.ToString() ?? "-"));
		text.AppendLine("Type/Action: " + (packet.MessageType?.ToString() ?? "-") + "/" + (packet.Action?.ToString() ?? "-"));
		text.AppendLine("ExtID/Cmd: " + (packet.ExtensionId?.ToString() ?? "-") + "/" + (packet.Command ?? "-"));
		text.AppendLine("摘要: " + packet.Summary);
		if (!string.IsNullOrWhiteSpace(packet.ParametersJson))
		{
			text.AppendLine();
			text.AppendLine("Inner 参数明文（JSON）:");
			try
			{
				text.AppendLine(JToken.Parse(packet.ParametersJson).ToString(Formatting.Indented));
			}
			catch (JsonException)
			{
				text.AppendLine(packet.ParametersJson);
			}
		}
		if (!string.IsNullOrWhiteSpace(packet.InnerPlainHex))
		{
			text.AppendLine();
			text.AppendLine("Inner 明文（AMF3 HEX）:");
			text.AppendLine(packet.InnerPlainHex);
		}
		_details.Text = text.ToString();
	}

	private void ClearPackets()
	{
		_packets.Clear();
		_packetList.Items.Clear();
		_details.Clear();
		UpdateCountStatus();
	}

	private void FillFromSelected()
	{
		IEnumerable<AolaPacketEvent> selected = _packetList.SelectedItems.Cast<ListViewItem>()
			.Select(item => item.Tag as AolaPacketEvent)
			.Where(packet => packet != null && packet.CanExport);
		List<string> lines = selected.Select(packet => AolaSendExporter.TryCreateLine(packet, out string line) ? line : null)
			.Where(line => line != null).ToList();
		if (lines.Count == 0)
		{
			MessageBox.Show(this, "请选择至少一条可导出的 EXT 消息。", "填入发包区", MessageBoxButtons.OK, MessageBoxIcon.Information);
			return;
		}
		_sendInput.Lines = lines.ToArray();
	}

	private void LoadSendFile()
	{
		using (OpenFileDialog dialog = new OpenFileDialog { Filter = "奥拉星消息文件 (*.txt)|*.txt|所有文件 (*.*)|*.*" })
		{
			if (dialog.ShowDialog(this) == DialogResult.OK)
			{
				_sendInput.Text = File.ReadAllText(dialog.FileName, Encoding.UTF8);
			}
		}
	}

	private void QueueSends()
	{
		try
		{
			List<AolaSendRequest> requests = ParseSendLines(_sendInput.Text);
			AolaPacketEvent target = GetTargetPacket();
			foreach (AolaSendRequest request in requests)
			{
				request.ProcessId = target?.ProcessId ?? 0;
				request.SocketHandle = target?.SocketHandle ?? 0;
				AolaHookHostService.QueueSend(request);
			}
			_status.Text = string.Format("已排队 {0} 条消息，等待独立游戏连接发送", requests.Count);
		}
		catch (Exception ex) when (ex is JsonException || ex is InvalidOperationException || ex is ArgumentException)
		{
			MessageBox.Show(this, ex.Message, "#send 格式错误", MessageBoxButtons.OK, MessageBoxIcon.Warning);
		}
	}

	private AolaPacketEvent GetTargetPacket()
	{
		AolaPacketEvent selected = _packetList.SelectedItems.Cast<ListViewItem>()
			.Select(item => item.Tag as AolaPacketEvent)
			.FirstOrDefault(packet => packet != null && packet.SocketHandle != 0);
		return selected ?? _packets.LastOrDefault(packet => packet.SocketHandle != 0);
	}

	private static List<AolaSendRequest> ParseSendLines(string input)
	{
		List<string> lines = (input ?? string.Empty).Replace("\r\n", "\n").Split('\n')
			.Select(line => line.Trim().TrimStart('\uFEFF'))
			.Where(line => line.Length != 0 && !line.StartsWith("//", StringComparison.Ordinal))
			.ToList();
		if (lines.Count == 0)
		{
			throw new InvalidOperationException("请输入至少一条 #send={...}| 消息。");
		}
		List<AolaSendRequest> requests = new List<AolaSendRequest>();
		for (int index = 0; index < lines.Count; index++)
		{
			string line = lines[index];
			if (!line.StartsWith("#send=", StringComparison.Ordinal) || !line.EndsWith("|", StringComparison.Ordinal))
			{
				throw new InvalidOperationException(string.Format("第 {0} 行必须使用 #send={{...}}| 格式。", index + 1));
			}
			JObject message = JObject.Parse(line.Substring(6, line.Length - 7));
			JToken idToken = message["id"];
			JToken commandToken = message["cmd"];
			JToken parametersToken = message["param"];
			if (idToken == null || idToken.Type != JTokenType.Integer || idToken.Value<long>() < 0 || idToken.Value<long>() > ushort.MaxValue)
			{
				throw new InvalidOperationException(string.Format("第 {0} 行 id 必须是 0..65535 的整数。", index + 1));
			}
			if (commandToken == null || commandToken.Type != JTokenType.String || string.IsNullOrWhiteSpace(commandToken.Value<string>()))
			{
				throw new InvalidOperationException(string.Format("第 {0} 行 cmd 必须是非空字符串。", index + 1));
			}
			if (!(parametersToken is JObject parameters))
			{
				throw new InvalidOperationException(string.Format("第 {0} 行 param 必须是 JSON 对象。", index + 1));
			}
			parameters = (JObject)parameters.DeepClone();
			parameters.Remove(":ext_seq;");
			requests.Add(new AolaSendRequest
			{
				ExtensionId = idToken.Value<int>(),
				Command = commandToken.Value<string>(),
				ParametersJson = parameters.ToString(Formatting.None)
			});
		}
		return requests;
	}

	private void ExportPackets()
	{
		IEnumerable<AolaPacketEvent> source = _packetList.SelectedItems.Count == 0
			? _packets
			: _packetList.SelectedItems.Cast<ListViewItem>().Select(item => item.Tag as AolaPacketEvent);
		List<string> lines = source.Where(packet => packet != null && packet.CanExport)
			.Select(packet => AolaSendExporter.TryCreateLine(packet, out string line) ? line : null)
			.Where(line => line != null).ToList();
		if (lines.Count == 0)
		{
			MessageBox.Show(this, "当前没有可导出的客户端 EXT 消息。", "导出 #send", MessageBoxButtons.OK, MessageBoxIcon.Information);
			return;
		}
		using (SaveFileDialog dialog = new SaveFileDialog
		{
			Filter = "奥拉星消息文件 (*.txt)|*.txt|所有文件 (*.*)|*.*",
			FileName = "aola-send-" + DateTime.Now.ToString("yyyyMMdd-HHmmss") + ".txt"
		})
		{
			if (dialog.ShowDialog(this) == DialogResult.OK)
			{
				File.WriteAllLines(dialog.FileName, lines, new UTF8Encoding(false));
				_status.Text = string.Format("已导出 {0} 条消息：{1}", lines.Count, dialog.FileName);
			}
		}
	}

	private void UpdateCountStatus()
	{
		_status.Text = string.Format("发送消息 {0} 条，可导出 {1} 条", _packets.Count, _packets.Count(packet => packet.CanExport));
	}
}
