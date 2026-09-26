// 架构角色：阵容方案的读取、保存和恢复界面，将长操作交给 LineupCoordinator/Session。
// 数据流：用户选择 -> coordinator；阶段更新/结果 -> UI 状态。
using System;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using AolaLoader.Features.Lineup;
using AolaLoader.UI.Common;
using Newtonsoft.Json.Linq;

namespace AolaLoader.UI.Lineup;

internal sealed class LineupPresetsForm : AolaFormBase
{
	private readonly LineupCoordinator _coordinator;
	private readonly TextBox _name = new TextBox { Width = 200, MaxLength = 100, Text = "阵容方案" };
	private readonly Button _read = new Button { Text = "读取当前背包", AutoSize = true };
	private readonly Button _save = new Button { Text = "保存为 JSON", AutoSize = true };
	private readonly Button _open = new Button { Text = "打开 JSON", AutoSize = true };
	private readonly Button _restore = new Button { Text = "恢复阵容", AutoSize = true };
	private readonly Button _stop = new Button { Text = "停止", AutoSize = true, Enabled = false };
	private readonly Label _summary = new Label { Dock = DockStyle.Fill, AutoEllipsis = true, TextAlign = ContentAlignment.MiddleLeft };
	private readonly TextBox _progress = new TextBox { Dock = DockStyle.Fill, Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Vertical };
	private readonly DataGridView _grid = new DataGridView
	{
		Dock = DockStyle.Fill, ReadOnly = true, AllowUserToAddRows = false, AllowUserToDeleteRows = false,
		RowHeadersVisible = false, AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
		AutoSizeRowsMode = DataGridViewAutoSizeRowsMode.AllCells, SelectionMode = DataGridViewSelectionMode.FullRowSelect,
		BackgroundColor = Color.White, MultiSelect = false
	};
	private JObject _catalog;
	private LineupPreset _preset;
	private CancellationTokenSource _operation;
	private bool _closing;
	private readonly string _directory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AolaLoader", "Lineups");

	public LineupPresetsForm(LineupCoordinator coordinator)
	{
		_coordinator = coordinator ?? throw new ArgumentNullException(nameof(coordinator));
		Text = "阵容方案";
		Size = new Size(1080, 650);
		MinimumSize = new Size(850, 500);
		StartPosition = FormStartPosition.CenterScreen;
		var layout = new TableLayoutPanel { Dock = DockStyle.Fill, RowCount = 5, ColumnCount = 1, Padding = new Padding(12) };
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 45));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 30));
		layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 42));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 130));
		var toolbar = new FlowLayoutPanel { Dock = DockStyle.Fill, WrapContents = false, AutoScroll = true };
		toolbar.Controls.Add(new Label { Text = "方案名称", AutoSize = true, Margin = new Padding(0, 9, 8, 0) });
		toolbar.Controls.Add(_name);
		toolbar.Controls.AddRange(new Control[] { _read, _save, _open, _restore, _stop });
		layout.Controls.Add(toolbar, 0, 0);
		layout.Controls.Add(_summary, 0, 1);
		layout.Controls.Add(_grid, 0, 2);
		layout.Controls.Add(new Label
		{
			Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft,
			Text = "恢复原亚比及顺序、魂卡、魂器和已绑定晶钥。装备不变；空魂器槽跳过。\r\n执行期间请勿手动换宠、修改配置或使用其他发包功能。"
		}, 0, 3);
		layout.Controls.Add(_progress, 0, 4);
		Controls.Add(layout);
		_grid.DefaultCellStyle.WrapMode = DataGridViewTriState.True;
		_grid.Columns.Add("position", "顺序");
		_grid.Columns.Add("pet", "亚比");
		_grid.Columns.Add("cards", "魂卡（按槽位）");
		_grid.Columns.Add("artifacts", "魂器（按槽位）");
		_grid.Columns.Add("keys", "晶钥（按槽位）");
		_grid.Columns[0].FillWeight = 25;
		_grid.Columns[1].FillWeight = 95;
		_grid.Columns[2].FillWeight = 150;
		_grid.Columns[3].FillWeight = 120;
		_grid.Columns[4].FillWeight = 95;
		foreach (DataGridViewColumn column in _grid.Columns) column.SortMode = DataGridViewColumnSortMode.NotSortable;
		try
		{
			string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Resources", "BattleAssistant", "catalog.json");
			if (File.Exists(path)) _catalog = JObject.Parse(File.ReadAllText(path));
		}
		catch (Exception ex) when (ex is IOException || ex is UnauthorizedAccessException || ex is Newtonsoft.Json.JsonException)
		{
			Report("名称目录不可用，配置将显示编号。");
		}
		_read.Click += async delegate
		{
			await RunAsync(async token =>
			{
				LineupPreset preset = await _coordinator.ReadAsync(Report, token);
				if (_closing) return;
				preset.Name = string.IsNullOrWhiteSpace(_name.Text) ? "阵容方案" : _name.Text.Trim();
				_preset = preset;
				Render();
			});
		};
		_restore.Click += async delegate
		{
			if (_preset == null) return;
			_preset.Name = _name.Text.Trim();
			await RunAsync(token => _coordinator.RestoreAsync(_preset, Report, token));
		};
		_open.Click += delegate { OpenPreset(); };
		_save.Click += delegate { SavePreset(); };
		_stop.Click += delegate { _operation?.Cancel(); Report("已请求停止；已提交操作仍可能生效。"); };
		UpdateButtons();
		_summary.Text = "读取当前背包，或打开已有方案。";
	}

	private string ItemName(string category, int id)
	{
		if (id == 0) return "空";
		return _catalog?[category + ":" + id]?.Value<string>("name") ?? ("#" + id);
	}

	private void Render()
	{
		_grid.Rows.Clear();
		_name.Text = _preset.Name;
		_summary.Text = "方案：" + _preset.Name + "    所属玩家：" + _preset.OwnerPlayerId + "    保存时间：" + _preset.SavedAt.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss");
		for (int i = 0; i < _preset.Pets.Count; i++)
		{
			LineupPet pet = _preset.Pets[i];
			string cards = pet.SoulCards == null ? "不参与恢复" : string.Join("\r\n", pet.SoulCards.Select((id, slot) => (slot + 1) + ". " + ItemName("soul-card", id)));
			string artifacts = pet.SoulArtifacts == null ? "不参与恢复" : string.Join("\r\n", pet.SoulArtifacts.Select((item, slot) => (slot + 1) + ". " + (item == null ? "空（跳过）" : ItemName("soul-artifact", item.ConfigId) + " · " + item.InstanceId)));
			string keys = pet.CrystalKeys == null ? "不参与恢复" : string.Join("\r\n", pet.CrystalKeys.Select((id, slot) => (slot + 1) + ". " + ItemName("crystal-key", id)));
			_grid.Rows.Add(i + 1, (pet.Name ?? "亚比") + "\r\n编号 " + pet.PetId, cards, artifacts, keys);
		}
		UpdateButtons();
	}

	private void OpenPreset()
	{
		using (var dialog = new OpenFileDialog { Filter = "阵容方案 (*.json)|*.json", InitialDirectory = Directory.Exists(_directory) ? _directory : AppDomain.CurrentDomain.BaseDirectory })
		{
			if (dialog.ShowDialog(this) != DialogResult.OK) return;
			try { _preset = LineupPresetStore.Load(dialog.FileName); Render(); Report("已打开方案：" + dialog.FileName); }
			catch (Exception ex) { Report("打开失败：" + ex.Message); }
		}
	}

	private void SavePreset()
	{
		if (_preset == null) return;
		try
		{
			_preset.Name = _name.Text.Trim();
			LineupPresetStore.Validate(_preset);
			Directory.CreateDirectory(_directory);
			string filename = string.Concat(_preset.Name.Select(c => Path.GetInvalidFileNameChars().Contains(c) ? '_' : c));
			using (var dialog = new SaveFileDialog { Filter = "阵容方案 (*.json)|*.json", DefaultExt = "json", AddExtension = true, FileName = filename + ".json", InitialDirectory = _directory })
			{
				if (dialog.ShowDialog(this) != DialogResult.OK) return;
				LineupPresetStore.Save(dialog.FileName, _preset);
				Render();
				Report("已保存：" + dialog.FileName);
			}
		}
		catch (Exception ex) { Report("保存失败：" + ex.Message); }
	}

	private async Task RunAsync(Func<CancellationToken, Task> run)
	{
		if (_operation != null) return;
		_operation = new CancellationTokenSource();
		UpdateButtons();
		_progress.Clear();
		try { await run(_operation.Token); }
		catch (OperationCanceledException) { Report("已停止。已完成步骤见上方记录；再次恢复将重新读取现状。"); }
		catch (Exception ex) { Report("已停止：" + ex.Message + "\r\n尚未开始的步骤未执行；已提交操作未回滚，请按进度核对。"); }
		finally
		{
			_operation.Dispose();
			_operation = null;
			if (!_closing && !IsDisposed) UpdateButtons();
		}
	}

	private void UpdateButtons()
	{
		bool idle = _operation == null;
		_read.Enabled = _open.Enabled = _name.Enabled = idle;
		_restore.Enabled = _save.Enabled = idle && _preset != null;
		_stop.Enabled = !idle;
	}

	private void Report(string message)
	{
		if (_closing || IsDisposed) return;
		if (InvokeRequired)
		{
			try { BeginInvoke(new Action<string>(Report), message); }
			catch (InvalidOperationException) { }
			return;
		}
		if (_progress.TextLength > 40000) _progress.Clear();
		_progress.AppendText(DateTime.Now.ToString("HH:mm:ss") + "  " + message + Environment.NewLine);
	}

	protected override void OnFormClosing(FormClosingEventArgs e)
	{
		base.OnFormClosing(e);
		if (e.Cancel) return;
		_closing = true;
		_operation?.Cancel();
	}
	protected override void Dispose(bool disposing)
	{
		if (disposing) { _closing = true; _operation?.Cancel(); }
		base.Dispose(disposing);
	}
}

