// 架构角色：独立显示游戏内面板调用；不订阅 packet，不执行打开或发送操作。
using System;
using System.Drawing;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using AolaLoader.BrowserHost.Contracts;
using AolaLoader.Features.PanelCapture;
using AolaLoader.UI.Common;
using AolaLoader.UI.Packets;
using Newtonsoft.Json.Linq;

namespace AolaLoader.UI.PanelCapture;

internal sealed class PanelCaptureForm : AolaFormBase
{
	private readonly PanelCaptureClient _client;
	private readonly System.Windows.Forms.Timer _timer = new System.Windows.Forms.Timer { Interval = 500 };
	private readonly CancellationTokenSource _lifetime = new CancellationTokenSource();
	private readonly DataGridView _grid = new DataGridView();
	private readonly Label _status = new Label { Dock = DockStyle.Bottom, Height = 32, TextAlign = ContentAlignment.MiddleLeft };
	private readonly Button _pause = new CupertinoButton("暂停采集");
	private bool _enabled = true;
	private bool _polling;
	private int _dropped;

	public PanelCaptureForm(PanelCaptureClient client)
	{
		_client = client;
		Text = "面板调用采集";
		Size = new Size(1050, 580);
		MinimumSize = new Size(720, 380);
		StartPosition = FormStartPosition.CenterScreen;
		AutoScaleMode = AutoScaleMode.Dpi;
		Font = new Font("Microsoft YaHei UI", 9f);
		BackColor = Color.FromArgb(245, 245, 247);
		Padding = new Padding(16);
		var heading = new Label
		{
			Text = "点击游戏内按钮后，在这里查看资源路径和 CLS。仅记录经过公共面板入口的调用。",
			Dock = DockStyle.Top, Height = 36, ForeColor = Color.FromArgb(110, 110, 115)
		};
		var actions = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 52, WrapContents = false };
		var copy = new CupertinoButton("复制 URL / CLS");
		var clear = new CupertinoButton("清空列表");
		actions.Controls.AddRange(new Control[] { _pause, copy, clear });
		_pause.Click += async delegate
		{
			_enabled = !_enabled;
			_pause.Text = _enabled ? "暂停采集" : "继续采集";
			await PollAsync();
		};
		copy.Click += delegate
		{
			string text = string.Join(Environment.NewLine + Environment.NewLine,
				_grid.SelectedRows.Cast<DataGridViewRow>().OrderBy(row => row.Index)
					.Select(row => "URL=" + row.Cells[1].Value + Environment.NewLine + "CLS=" + row.Cells[2].Value));
			if (text.Length > 0) Clipboard.SetText(text);
		};
		clear.Click += delegate { _grid.Rows.Clear(); _dropped = 0; UpdateStatus(); };
		_grid.Dock = DockStyle.Fill;
		_grid.ReadOnly = true;
		_grid.AllowUserToAddRows = false;
		_grid.AllowUserToDeleteRows = false;
		_grid.RowHeadersVisible = false;
		_grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
		_grid.BackgroundColor = Color.White;
		_grid.BorderStyle = BorderStyle.None;
		_grid.CellBorderStyle = DataGridViewCellBorderStyle.SingleHorizontal;
		_grid.GridColor = Color.FromArgb(235, 235, 240);
		_grid.EnableHeadersVisualStyles = false;
		_grid.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(242, 242, 247);
		_grid.ColumnHeadersDefaultCellStyle.ForeColor = Color.FromArgb(29, 29, 31);
		_grid.DefaultCellStyle.SelectionBackColor = Color.FromArgb(226, 239, 255);
		_grid.DefaultCellStyle.SelectionForeColor = Color.FromArgb(29, 29, 31);
		_grid.RowTemplate.Height = 28;
		_grid.Columns.Add(new DataGridViewTextBoxColumn { HeaderText = "时间", Width = 100, SortMode = DataGridViewColumnSortMode.NotSortable });
		_grid.Columns.Add(new DataGridViewTextBoxColumn { HeaderText = "URL / 资源路径", AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill, FillWeight = 48, SortMode = DataGridViewColumnSortMode.NotSortable });
		_grid.Columns.Add(new DataGridViewTextBoxColumn { HeaderText = "CLS", AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill, FillWeight = 52, SortMode = DataGridViewColumnSortMode.NotSortable });
		Controls.Add(_grid);
		Controls.Add(_status);
		Controls.Add(actions);
		Controls.Add(heading);
		_timer.Tick += async delegate { await PollAsync(); };
		UpdateStatus();
	}

	protected override async void OnShown(EventArgs e)
	{
		base.OnShown(e);
		_timer.Start();
		await PollAsync();
	}

	private async Task PollAsync()
	{
		if (_polling || _lifetime.IsCancellationRequested) return;
		_polling = true;
		try
		{
			PageBridgeResult result = await _client.PollAsync(_enabled, _lifetime.Token);
			if (_lifetime.IsCancellationRequested) return;
			if (!result.Succeeded)
			{
				_status.Text = "等待页面就绪：" + result.Message;
				return;
			}
			JToken value = result.Value;
			_dropped += value.Value<int>("dropped");
			foreach (JToken item in value["items"])
			{
				while (_grid.Rows.Count >= 1000) _grid.Rows.RemoveAt(0);
				string time = DateTime.Parse(item.Value<string>("time")).ToLocalTime().ToString("HH:mm:ss.fff");
				_grid.Rows.Add(time, item.Value<string>("url"), item.Value<string>("cls"));
			}
			UpdateStatus();
		}
		finally { _polling = false; }
	}

	private void UpdateStatus()
	{
		_status.Text = (_enabled ? "采集中" : "已暂停") + " · " + _grid.Rows.Count + " 条（最多保留 1000 条）" +
			(_dropped > 0 ? " · 页面队列已丢弃 " + _dropped + " 条旧记录" : "") +
			" · 首次使用请重启游戏加载采集补丁";
	}

	protected override async void OnFormClosed(FormClosedEventArgs e)
	{
		_timer.Stop();
		_lifetime.Cancel();
		base.OnFormClosed(e);
		await _client.StopAsync();
	}

	protected override void Dispose(bool disposing)
	{
		if (disposing)
		{
			_timer.Dispose();
			_lifetime.Cancel();
		}
		base.Dispose(disposing);
	}
}
