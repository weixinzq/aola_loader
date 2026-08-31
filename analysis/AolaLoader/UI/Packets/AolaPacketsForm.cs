using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using AolaLoader.BrowserHost.Contracts;
using AolaLoader.Features.ActiveSend;
using AolaLoader.Features.Battle.Bridge;
using AolaLoader.Features.Battle.Replay;
using AolaLoader.PacketHost;
using AolaLoader.UI.Common;
using AolaSocketHack.Contracts;
using AolaSocketHack.Protocol;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.UI.Packets;

internal sealed class AolaPacketsForm : AolaFormBase
{
	private const int MaximumVisiblePackets = 5000;
	private const int MaximumPendingPackets = 8192;
	private const int MaximumPacketsPerFlush = 256;
	private static readonly Color Background = Color.FromArgb(245, 245, 247);
	private static readonly Color SecondaryText = Color.FromArgb(110, 110, 115);
	private readonly IAolaPacketEventSource _packetEventSource;
	private readonly IAolaCommandSender _commandSender;
	private readonly IPageBridge _pageBridge;
	private readonly List<AolaPacketEvent> _packets = new List<AolaPacketEvent>();
	private readonly object _pendingPacketSync = new object();
	private readonly Queue<AolaPacketEvent> _pendingPackets = new Queue<AolaPacketEvent>();
	private readonly HashSet<AolaPacketEvent> _checkedPackets = new HashSet<AolaPacketEvent>();
	private readonly System.Windows.Forms.Timer _packetFlushTimer = new System.Windows.Forms.Timer { Interval = 50 };
	private readonly DataGridView _packetGrid = new DataGridView();
	private readonly TextBox _sendInput = new TextBox();
	private readonly TextBox _panelResourceInput = new TextBox();
	private readonly TextBox _panelClassInput = new TextBox();
	private readonly CupertinoButton _sendButton = new CupertinoButton("发送", true);
	private readonly CheckBox _battleStateMode = new CheckBox
	{
		Text = "按战斗状态逐条发送",
		AutoSize = true,
		Margin = new Padding(12, 10, 0, 0)
	};
	private readonly CupertinoButton _openPanelButton = new CupertinoButton("打开映射面板", true);
	private readonly CupertinoButton _captureNavigation = new CupertinoButton("抓包", true);
	private readonly CupertinoButton _sendNavigation = new CupertinoButton("发包");
	private readonly CupertinoButton _panelNavigation = new CupertinoButton("打开映射面板");
	private readonly Label _status = new Label { Text = "等待奥拉星发送消息" };
	private readonly Panel _contentHost = new Panel();
	private Control _captureView;
	private Control _sendView;
	private Control _panelView;
	private readonly BattleSequenceRunner _battleSequenceRunner;
	private CancellationTokenSource _sequenceCancellation;
	private int _pendingPacketDrops;
	private int _closed;

	public AolaPacketsForm(
		IAolaPacketEventSource packetEventSource,
		IAolaCommandSender commandSender,
		IPageBridge pageBridge)
	{
		_packetEventSource = packetEventSource ?? throw new ArgumentNullException(nameof(packetEventSource));
		_commandSender = commandSender ?? throw new ArgumentNullException(nameof(commandSender));
		_pageBridge = pageBridge ?? throw new ArgumentNullException(nameof(pageBridge));
		_battleSequenceRunner = new BattleSequenceRunner(
			_packetEventSource,
			_commandSender,
			new BattleBridgeClient(_pageBridge));
		Text = "奥拉星抓包 / 发包";
		StartPosition = FormStartPosition.CenterParent;
		MinimumSize = new Size(920, 620);
		Size = new Size(1180, 780);
		BackColor = Background;
		Font = new Font("Microsoft YaHei UI", 9.5f);

		ConfigureInputs();
		BuildInterface();
		_packetEventSource.PacketReceived += OnPacketReceived;
		_packetEventSource.StatusReceived += OnStatusReceived;
		_commandSender.StatusChanged += OnCommandStatusChanged;
		_battleSequenceRunner.StatusChanged += OnBattleSequenceStatusChanged;
		_packetFlushTimer.Tick += delegate { FlushPendingPackets(); };
		_packetFlushTimer.Start();
	}

	protected override void OnFormClosed(FormClosedEventArgs e)
	{
		Interlocked.Exchange(ref _closed, 1);
		_packetFlushTimer.Stop();
		_packetFlushTimer.Dispose();
		lock (_pendingPacketSync)
		{
			_pendingPackets.Clear();
		}
		_packetEventSource.PacketReceived -= OnPacketReceived;
		_packetEventSource.StatusReceived -= OnStatusReceived;
		_commandSender.StatusChanged -= OnCommandStatusChanged;
		_battleSequenceRunner.StatusChanged -= OnBattleSequenceStatusChanged;
		_sequenceCancellation?.Cancel();
		_sequenceCancellation?.Dispose();
		base.OnFormClosed(e);
	}

	private void ConfigureInputs()
	{
		_sendInput.Multiline = true;
		_sendInput.AcceptsReturn = true;
		_sendInput.AcceptsTab = true;
		_sendInput.ScrollBars = ScrollBars.Both;
		_sendInput.WordWrap = false;
		_sendInput.BorderStyle = BorderStyle.FixedSingle;
		_sendInput.BackColor = Color.FromArgb(251, 251, 253);
		_sendInput.Font = new Font("Consolas", 10f);

		_panelResourceInput.BorderStyle = BorderStyle.FixedSingle;
		_panelResourceInput.Font = new Font("Consolas", 10f);
		_panelResourceInput.Text = "activityres/activity241101/challengeandtrialentrance/challengeandtrialentrance_code";
		_panelClassInput.BorderStyle = BorderStyle.FixedSingle;
		_panelClassInput.Font = new Font("Consolas", 10f);
		_panelClassInput.Text = "mmo.activity241101.challengeandtrialentrance.panel.CATE_MainPl";
		_sendButton.Click += delegate { QueueSends(); };
		_openPanelButton.Click += delegate { OpenMappedPanel(); };
	}

	private void BuildInterface()
	{
		TableLayoutPanel shell = new TableLayoutPanel
		{
			Dock = DockStyle.Fill,
			ColumnCount = 1,
			RowCount = 3,
			Padding = new Padding(16, 14, 16, 14),
			BackColor = Background
		};
		shell.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100f));
		shell.RowStyles.Add(new RowStyle(SizeType.Absolute, 78f));
		shell.RowStyles.Add(new RowStyle(SizeType.Percent, 100f));
		shell.RowStyles.Add(new RowStyle(SizeType.Absolute, 42f));
		shell.Controls.Add(BuildNavigation(), 0, 0);

		_contentHost.Dock = DockStyle.Fill;
		_contentHost.Margin = new Padding(0, 12, 0, 12);
		_contentHost.BackColor = Background;
		_captureView = BuildCaptureView();
		_sendView = BuildSendView();
		_panelView = BuildPanelView();
		_contentHost.Controls.AddRange(new[] { _captureView, _sendView, _panelView });
		shell.Controls.Add(_contentHost, 0, 1);
		shell.Controls.Add(BuildStatusBar(), 0, 2);
		Controls.Add(shell);
		ShowView(_captureView, _captureNavigation);
	}

	private Control BuildNavigation()
	{
		CupertinoCard card = new CupertinoCard { Dock = DockStyle.Fill, Padding = new Padding(16, 12, 16, 12) };
		FlowLayoutPanel row = ActionRow();
		ConfigureNavigation(_captureNavigation, 170);
		ConfigureNavigation(_sendNavigation, 170);
		ConfigureNavigation(_panelNavigation, 220);
		_captureNavigation.Click += delegate { ShowView(_captureView, _captureNavigation); };
		_sendNavigation.Click += delegate { ShowView(_sendView, _sendNavigation); };
		_panelNavigation.Click += delegate { ShowView(_panelView, _panelNavigation); };
		row.Controls.AddRange(new Control[] { _captureNavigation, _sendNavigation, _panelNavigation });
		card.Controls.Add(row);
		return card;
	}

	private static void ConfigureNavigation(CupertinoButton button, int width)
	{
		button.AutoSize = false;
		button.Size = new Size(width, 48);
		button.Margin = new Padding(0, 0, 12, 0);
		button.Font = new Font("Microsoft YaHei UI", 11f, FontStyle.Bold);
	}

	private Control BuildCaptureView()
	{
		CupertinoCard card = PageCard();
		TableLayoutPanel layout = PageLayout(72, 54);
		layout.Controls.Add(Header("抓包消息", "仅显示能够转换为严格 #send 格式的客户端发送消息。"), 0, 0);
		FlowLayoutPanel actions = ActionRow();
		actions.Controls.Add(ActionButton("全选", delegate { SetAllPacketsChecked(true); }));
		actions.Controls.Add(ActionButton("取消全选", delegate { SetAllPacketsChecked(false); }));
		actions.Controls.Add(ActionButton("选中内容加入发包", AppendCheckedToSend, true));
		actions.Controls.Add(ActionButton("导出所选", ExportPackets));
		actions.Controls.Add(ActionButton("清空消息", ClearPackets));
		layout.Controls.Add(actions, 0, 1);
		ConfigurePacketGrid();
		layout.Controls.Add(_packetGrid, 0, 2);
		card.Controls.Add(layout);
		return card;
	}

	private void ConfigurePacketGrid()
	{
		_packetGrid.Dock = DockStyle.Fill;
		_packetGrid.Margin = new Padding(0);
		_packetGrid.BackgroundColor = Color.White;
		_packetGrid.BorderStyle = BorderStyle.None;
		_packetGrid.CellBorderStyle = DataGridViewCellBorderStyle.SingleHorizontal;
		_packetGrid.GridColor = Color.FromArgb(235, 235, 240);
		_packetGrid.AllowUserToAddRows = false;
		_packetGrid.AllowUserToDeleteRows = false;
		_packetGrid.AllowUserToResizeRows = false;
		_packetGrid.RowHeadersVisible = false;
		_packetGrid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
		_packetGrid.RowTemplate.Height = 34;
		_packetGrid.EnableHeadersVisualStyles = false;
		_packetGrid.ColumnHeadersHeight = 38;
		_packetGrid.ColumnHeadersDefaultCellStyle = new DataGridViewCellStyle
		{
			BackColor = Color.FromArgb(248, 248, 250),
			ForeColor = Color.FromArgb(40, 40, 45),
			Font = new Font("Microsoft YaHei UI", 9.5f, FontStyle.Bold),
			SelectionBackColor = Color.FromArgb(248, 248, 250),
			SelectionForeColor = Color.FromArgb(40, 40, 45)
		};
		_packetGrid.DefaultCellStyle = new DataGridViewCellStyle
		{
			BackColor = Color.White,
			ForeColor = Color.FromArgb(35, 35, 40),
			SelectionBackColor = Color.FromArgb(225, 239, 255),
			SelectionForeColor = Color.FromArgb(20, 70, 125),
			Font = new Font("Consolas", 9.5f),
			Padding = new Padding(4, 0, 4, 0)
		};
		_packetGrid.Columns.Add(new DataGridViewCheckBoxColumn
		{
			Name = "Selected",
			HeaderText = string.Empty,
			Width = 48,
			Resizable = DataGridViewTriState.False,
			SortMode = DataGridViewColumnSortMode.NotSortable
		});
		_packetGrid.Columns.Add(new DataGridViewTextBoxColumn
		{
			Name = "Time",
			HeaderText = "时间",
			Width = 125,
			ReadOnly = true,
			SortMode = DataGridViewColumnSortMode.NotSortable
		});
		_packetGrid.Columns.Add(new DataGridViewTextBoxColumn
		{
			Name = "SendLine",
			HeaderText = "解析后的 #send 消息",
			AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill,
			ReadOnly = true,
			SortMode = DataGridViewColumnSortMode.NotSortable
		});
		_packetGrid.CurrentCellDirtyStateChanged += delegate
		{
			if (_packetGrid.IsCurrentCellDirty)
			{
				_packetGrid.CommitEdit(DataGridViewDataErrorContexts.Commit);
			}
		};
		_packetGrid.CellValueChanged += delegate(object sender, DataGridViewCellEventArgs e)
		{
			if (e.RowIndex >= 0 && e.ColumnIndex == 0 && e.RowIndex < _packetGrid.Rows.Count &&
				_packetGrid.Rows[e.RowIndex].Tag is AolaPacketEvent packet)
			{
				if (Convert.ToBoolean(_packetGrid.Rows[e.RowIndex].Cells[0].Value))
				{
					_checkedPackets.Add(packet);
				}
				else
				{
					_checkedPackets.Remove(packet);
				}
				UpdateCountStatus();
			}
		};
	}

	private Control BuildSendView()
	{
		CupertinoCard card = PageCard();
		TableLayoutPanel layout = PageLayout(72, 0);
		layout.RowStyles.Clear();
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 72f));
		layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100f));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 60f));
		layout.Controls.Add(Header("发包", "直接编写严格 #send 消息，或从 UTF-8 文本文件导入。"), 0, 0);
		_sendInput.Dock = DockStyle.Fill;
		_sendInput.Margin = new Padding(0, 0, 0, 10);
		layout.Controls.Add(_sendInput, 0, 1);

		TableLayoutPanel actions = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, RowCount = 1, Margin = new Padding(0) };
		actions.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100f));
		actions.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
		FlowLayoutPanel left = ActionRow();
		left.AutoSize = true;
		left.Controls.Add(ActionButton("从文件导入", LoadSendFile));
		left.Controls.Add(ActionButton("清空", ClearSendEditor));
		left.Controls.Add(_battleStateMode);
		FlowLayoutPanel right = ActionRow();
		right.AutoSize = true;
		right.FlowDirection = FlowDirection.RightToLeft;
		_sendButton.MinimumSize = new Size(120, 44);
		_sendButton.Margin = new Padding(10, 0, 0, 0);
		right.Controls.Add(_sendButton);
		actions.Controls.Add(left, 0, 0);
		actions.Controls.Add(right, 1, 0);
		layout.Controls.Add(actions, 0, 2);
		card.Controls.Add(layout);
		return card;
	}

	private Control BuildPanelView()
	{
		CupertinoCard card = PageCard();
		TableLayoutPanel layout = PageLayout(72, 260);
		layout.Controls.Add(Header("打开映射面板", "将资源键或 URL 与 CLS 类名提交给已加载的 Flash 面板桥。"), 0, 0);
		TableLayoutPanel fields = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 1, RowCount = 5, Margin = new Padding(0) };
		fields.RowStyles.Add(new RowStyle(SizeType.AutoSize));
		fields.RowStyles.Add(new RowStyle(SizeType.Absolute, 42f));
		fields.RowStyles.Add(new RowStyle(SizeType.AutoSize));
		fields.RowStyles.Add(new RowStyle(SizeType.Absolute, 42f));
		fields.RowStyles.Add(new RowStyle(SizeType.Absolute, 64f));
		fields.Controls.Add(FieldLabel("URL / 资源键"), 0, 0);
		_panelResourceInput.Dock = DockStyle.Fill;
		fields.Controls.Add(_panelResourceInput, 0, 1);
		fields.Controls.Add(FieldLabel("CLS 类名"), 0, 2);
		_panelClassInput.Dock = DockStyle.Fill;
		fields.Controls.Add(_panelClassInput, 0, 3);
		FlowLayoutPanel openRow = ActionRow();
		_openPanelButton.MinimumSize = new Size(170, 44);
		_openPanelButton.Margin = new Padding(0, 12, 0, 0);
		openRow.Controls.Add(_openPanelButton);
		fields.Controls.Add(openRow, 0, 4);
		layout.Controls.Add(fields, 0, 1);
		card.Controls.Add(layout);
		return card;
	}

	private Control BuildStatusBar()
	{
		CupertinoCard card = new CupertinoCard { Dock = DockStyle.Fill, Padding = new Padding(14, 4, 14, 4) };
		_status.Dock = DockStyle.Fill;
		_status.TextAlign = ContentAlignment.MiddleLeft;
		_status.ForeColor = SecondaryText;
		_status.BackColor = Color.Transparent;
		_status.AutoEllipsis = true;
		card.Controls.Add(_status);
		return card;
	}

	private static CupertinoCard PageCard() => new CupertinoCard { Dock = DockStyle.Fill, Padding = new Padding(24) };

	private static TableLayoutPanel PageLayout(float firstHeight, float secondHeight)
	{
		TableLayoutPanel layout = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 1, RowCount = 3, Margin = new Padding(0) };
		layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100f));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, firstHeight));
		layout.RowStyles.Add(secondHeight == 0 ? new RowStyle(SizeType.Percent, 100f) : new RowStyle(SizeType.Absolute, secondHeight));
		layout.RowStyles.Add(secondHeight == 0 ? new RowStyle(SizeType.Absolute, 0) : new RowStyle(SizeType.Percent, 100f));
		return layout;
	}

	private static Control Header(string title, string subtitle)
	{
		TableLayoutPanel panel = new TableLayoutPanel
		{
			Dock = DockStyle.Fill,
			ColumnCount = 1,
			RowCount = 2,
			Margin = new Padding(0)
		};
		panel.RowStyles.Add(new RowStyle(SizeType.Absolute, 40f));
		panel.RowStyles.Add(new RowStyle(SizeType.Percent, 100f));
		panel.Controls.Add(new Label
		{
			Text = title,
			Dock = DockStyle.Fill,
			Font = new Font("Microsoft YaHei UI", 17f, FontStyle.Bold),
			ForeColor = Color.FromArgb(20, 20, 24),
			TextAlign = ContentAlignment.MiddleLeft
		}, 0, 0);
		panel.Controls.Add(new Label
		{
			Text = subtitle,
			Dock = DockStyle.Fill,
			ForeColor = SecondaryText,
			TextAlign = ContentAlignment.MiddleLeft
		}, 0, 1);
		return panel;
	}

	private static Label FieldLabel(string text) => new Label
	{
		Text = text,
		AutoSize = true,
		Margin = new Padding(0, 8, 0, 6),
		ForeColor = Color.FromArgb(55, 55, 60),
		Font = new Font("Microsoft YaHei UI", 9.5f, FontStyle.Bold)
	};

	private static FlowLayoutPanel ActionRow() => new FlowLayoutPanel
	{
		Dock = DockStyle.Fill,
		FlowDirection = FlowDirection.LeftToRight,
		WrapContents = false,
		Margin = new Padding(0),
		BackColor = Color.Transparent
	};

	private static CupertinoButton ActionButton(string text, Action action, bool primary = false)
	{
		CupertinoButton button = new CupertinoButton(text, primary) { MinimumSize = new Size(96, 40), Margin = new Padding(0, 0, 10, 0) };
		button.Click += delegate { action(); };
		return button;
	}

	private void ShowView(Control view, CupertinoButton selected)
	{
		if (view == null)
		{
			return;
		}
		foreach (Control control in _contentHost.Controls)
		{
			control.Visible = control == view;
		}
		_captureNavigation.Primary = selected == _captureNavigation;
		_sendNavigation.Primary = selected == _sendNavigation;
		_panelNavigation.Primary = selected == _panelNavigation;
		view.BringToFront();
	}

	private void OnPacketReceived(AolaPacketEvent packet)
	{
		if (!SendPacketVisibility.IsVisible(packet) || Volatile.Read(ref _closed) != 0)
		{
			return;
		}
		lock (_pendingPacketSync)
		{
			if (_closed != 0)
			{
				return;
			}
			if (_pendingPackets.Count >= MaximumPendingPackets)
			{
				_pendingPackets.Dequeue();
				_pendingPacketDrops++;
			}
			_pendingPackets.Enqueue(packet);
		}
	}

	private void FlushPendingPackets()
	{
		if (IsDisposed || Volatile.Read(ref _closed) != 0)
		{
			return;
		}
		List<AolaPacketEvent> batch = new List<AolaPacketEvent>(MaximumPacketsPerFlush);
		int dropped;
		lock (_pendingPacketSync)
		{
			while (batch.Count < MaximumPacketsPerFlush && _pendingPackets.Count > 0)
			{
				batch.Add(_pendingPackets.Dequeue());
			}
			dropped = _pendingPacketDrops;
			_pendingPacketDrops = 0;
		}
		foreach (AolaPacketEvent packet in batch)
		{
			AppendPacketToGrid(packet);
		}
		if (dropped > 0)
		{
			_status.Text = string.Format("已捕获可发包消息 {0} 条，已选择 {1} 条；刷新队列丢弃 {2} 条。", _packets.Count, _checkedPackets.Count, dropped);
		}
		else if (batch.Count > 0)
		{
			UpdateCountStatus();
		}
	}

	private void AppendPacketToGrid(AolaPacketEvent packet)
	{
		if (!packet.CanExport || !AolaSendExporter.TryCreateLine(packet, out string sendLine))
		{
			return;
		}
		_packets.Add(packet);
		int index = _packetGrid.Rows.Add(false, packet.TimestampUtc.ToLocalTime().ToString("HH:mm:ss.fff"), sendLine);
		_packetGrid.Rows[index].Tag = packet;
		while (_packetGrid.Rows.Count > MaximumVisiblePackets)
		{
			DataGridViewRow removed = _packetGrid.Rows[0];
			if (Convert.ToBoolean(removed.Cells[0].Value) && removed.Tag is AolaPacketEvent removedPacket)
			{
				_checkedPackets.Remove(removedPacket);
			}
			_packetGrid.Rows.RemoveAt(0);
			_packets.RemoveAt(0);
		}
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

	private void OnCommandStatusChanged(AolaCommandSendUpdate update)
	{
		if (update == null || IsDisposed)
		{
			return;
		}
		if (InvokeRequired)
		{
			BeginInvoke(new Action<AolaCommandSendUpdate>(OnCommandStatusChanged), update);
			return;
		}
		_status.Text = "[" + update.Status + "] " + update.Message;
	}

	private void OnBattleSequenceStatusChanged(BattleSequenceUpdate update)
	{
		if (update == null || IsDisposed) return;
		if (InvokeRequired)
		{
			BeginInvoke(new Action<BattleSequenceUpdate>(OnBattleSequenceStatusChanged), update);
			return;
		}
		_status.Text = "[" + update.Status + "] " + update.Message;
	}

	private void SetAllPacketsChecked(bool value)
	{
		foreach (DataGridViewRow row in _packetGrid.Rows)
		{
			row.Cells[0].Value = value;
		}
		UpdateCountStatus();
	}

	private List<DataGridViewRow> CheckedRows() => _packetGrid.Rows.Cast<DataGridViewRow>()
		.Where(row => Convert.ToBoolean(row.Cells[0].Value)).ToList();

	private void AppendCheckedToSend()
	{
		List<string> lines = CheckedRows().Select(row => Convert.ToString(row.Cells["SendLine"].Value))
			.Where(line => !string.IsNullOrWhiteSpace(line)).ToList();
		if (lines.Count == 0)
		{
			_status.Text = "请选择至少一条消息后再加入发包。";
			return;
		}
		string separator = _sendInput.TextLength == 0 || _sendInput.Text.EndsWith("\n", StringComparison.Ordinal)
			? string.Empty
			: Environment.NewLine;
		_sendInput.AppendText(separator + string.Join(Environment.NewLine, lines));
		_status.Text = string.Format("已将 {0} 条消息追加到发包区。", lines.Count);
	}

	private void ClearPackets()
	{
		_packets.Clear();
		_checkedPackets.Clear();
		_packetGrid.Rows.Clear();
		UpdateCountStatus();
	}

	private void ClearSendEditor()
	{
		_sendInput.Clear();
		_status.Text = "发包编辑区已清空。";
	}

	private void LoadSendFile()
	{
		using (OpenFileDialog dialog = new OpenFileDialog { Filter = "奥拉星消息文件 (*.txt)|*.txt|所有文件 (*.*)|*.*" })
		{
			if (dialog.ShowDialog(this) == DialogResult.OK)
			{
				_sendInput.Text = File.ReadAllText(dialog.FileName, Encoding.UTF8);
				_status.Text = "已导入发包文件：" + dialog.FileName;
			}
		}
	}

	private async void QueueSends()
	{
		_sendButton.Enabled = false;
		_battleStateMode.Enabled = false;
		try
		{
			List<AolaSendRequest> requests = AolaSendRequestParser.ParseLines(_sendInput.Text);
			if (_battleStateMode.Checked)
			{
				BattleSequencePlan plan = BattleSequenceValidator.Validate(requests);
				_sequenceCancellation?.Dispose();
				_sequenceCancellation = new CancellationTokenSource();
				await _battleSequenceRunner.RunAsync(plan, _sequenceCancellation.Token);
				return;
			}
			foreach (AolaSendRequest request in requests)
			{
				await _commandSender.SendAsync(request, CancellationToken.None);
			}
		}
		catch (Exception ex) when (ex is JsonException || ex is InvalidOperationException || ex is ArgumentException)
		{
			MessageBox.Show(this, ex.Message, "#send 格式错误", MessageBoxButtons.OK, MessageBoxIcon.Warning);
		}
		finally
		{
			if (!IsDisposed)
			{
				_sendButton.Enabled = true;
				_battleStateMode.Enabled = true;
			}
		}
	}

	private async void OpenMappedPanel()
	{
		string resourceUrl = _panelResourceInput.Text;
		string resourceClass = _panelClassInput.Text;
		if (string.IsNullOrEmpty(resourceUrl) || string.IsNullOrEmpty(resourceClass) || resourceUrl.Length > 2048 || resourceClass.Length > 2048)
		{
			_status.Text = "[PanelRejected] URL/资源键和 CLS 类名必须为 1 到 2048 个字符。";
			return;
		}
		_openPanelButton.Enabled = false;
		try
		{
			PageBridgeResult result = await _pageBridge.InvokeAsync(
				new PageBridgeRequest("panel.open", new JObject { ["resourceUrl"] = resourceUrl, ["resourceClass"] = resourceClass }, TimeSpan.FromSeconds(5)),
				CancellationToken.None);
			_status.Text = result.Succeeded
				? "[PanelOpenRequested] 已提交给 Flash：" + resourceUrl + " → " + resourceClass
				: "[PanelRejected] " + result.Message;
		}
		catch (Exception ex)
		{
			_status.Text = "[PanelRejected] " + ex.Message;
		}
		finally
		{
			if (!IsDisposed)
			{
				_openPanelButton.Enabled = true;
			}
		}
	}

	private void ExportPackets()
	{
		List<DataGridViewRow> selected = CheckedRows();
		IEnumerable<AolaPacketEvent> source = selected.Count == 0 ? _packets : selected.Select(row => row.Tag as AolaPacketEvent);
		List<string> lines = source.Where(packet => packet != null && packet.CanExport)
			.Select(packet => AolaSendExporter.TryCreateLine(packet, out string line) ? line : null)
			.Where(line => line != null).ToList();
		if (lines.Count == 0)
		{
			_status.Text = "当前没有可导出的客户端 EXT 消息。";
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
		_status.Text = string.Format("已捕获可发包消息 {0} 条，已选择 {1} 条。", _packets.Count, _checkedPackets.Count);
	}
}
