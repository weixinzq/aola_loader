using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;

namespace AolaLoader;

internal sealed class AolaPetMorphForm : Form
{
	private readonly TextBox _note = new TextBox();
	private readonly TextBox _originalId = new TextBox();
	private readonly TextBox _backpackId = new TextBox();
	private readonly TextBox _posterId = new TextBox();
	private readonly DataGridView _grid = new DataGridView();
	private readonly CheckBox _enabled = new CheckBox();
	private readonly Label _status = new Label();
	private readonly List<AolaPetMorphRule> _rules = new List<AolaPetMorphRule>();
	private readonly Func<AolaPetMorphRule, string> _validateRule;
	private readonly Action<IReadOnlyList<AolaPetMorphRule>, bool> _applyRules;

	public AolaPetMorphForm(
		Func<AolaPetMorphRule, string> validateRule,
		Action<IReadOnlyList<AolaPetMorphRule>, bool> applyRules)
	{
		_validateRule = validateRule ?? throw new ArgumentNullException(nameof(validateRule));
		_applyRules = applyRules ?? throw new ArgumentNullException(nameof(applyRules));
		Text = "功能面板 - 形态变化";
		StartPosition = FormStartPosition.CenterParent;
		MinimumSize = new Size(760, 480);
		Size = new Size(900, 560);
		BuildLayout();
	}

	protected override void OnFormClosing(FormClosingEventArgs e)
	{
		if (e.CloseReason == CloseReason.UserClosing)
		{
			e.Cancel = true;
			Hide();
			return;
		}
		base.OnFormClosing(e);
	}

	private void BuildLayout()
	{
		Label title = new Label
		{
			Text = "形态变化",
			Dock = DockStyle.Top,
			Height = 48,
			Padding = new Padding(14, 12, 0, 0),
			Font = new Font(Font.FontFamily, 15F, FontStyle.Bold)
		};

		TableLayoutPanel editor = new TableLayoutPanel
		{
			Dock = DockStyle.Top,
			Height = 92,
			Padding = new Padding(12, 4, 12, 8),
			ColumnCount = 5,
			RowCount = 2
		};
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 28));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 18));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 18));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 18));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 18));
		editor.RowStyles.Add(new RowStyle(SizeType.Absolute, 28));
		editor.RowStyles.Add(new RowStyle(SizeType.Absolute, 34));
		editor.Controls.Add(CreateHeader("备注"), 0, 0);
		editor.Controls.Add(CreateHeader("原型 ID"), 1, 0);
		editor.Controls.Add(CreateHeader("替换 ID（背包）"), 2, 0);
		editor.Controls.Add(CreateHeader("替换 ID（海报）"), 3, 0);
		editor.Controls.Add(CreateHeader("操作"), 4, 0);
		ConfigureEditor(_note);
		ConfigureEditor(_originalId);
		ConfigureEditor(_backpackId);
		ConfigureEditor(_posterId);
		editor.Controls.Add(_note, 0, 1);
		editor.Controls.Add(_originalId, 1, 1);
		editor.Controls.Add(_backpackId, 2, 1);
		editor.Controls.Add(_posterId, 3, 1);
		Button save = new Button { Text = "添加 / 更新", Dock = DockStyle.Fill };
		save.Click += delegate { SaveRule(); };
		editor.Controls.Add(save, 4, 1);

		_grid.Dock = DockStyle.Fill;
		_grid.AllowUserToAddRows = false;
		_grid.AllowUserToDeleteRows = false;
		_grid.AllowUserToResizeRows = false;
		_grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
		_grid.BackgroundColor = SystemColors.Window;
		_grid.BorderStyle = BorderStyle.FixedSingle;
		_grid.MultiSelect = false;
		_grid.ReadOnly = true;
		_grid.RowHeadersVisible = false;
		_grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
		_grid.Columns.Add("Note", "备注");
		_grid.Columns.Add("OriginalId", "原型 ID");
		_grid.Columns.Add("BackpackId", "目标 ID（背包）");
		_grid.Columns.Add("PosterId", "目标 ID（海报）");
		_grid.Columns[0].FillWeight = 180;
		_grid.Columns[1].FillWeight = 80;
		_grid.Columns[2].FillWeight = 100;
		_grid.Columns[3].FillWeight = 100;
		_grid.SelectionChanged += delegate { LoadSelectedRule(); };

		FlowLayoutPanel actions = new FlowLayoutPanel
		{
			Dock = DockStyle.Bottom,
			Height = 48,
			Padding = new Padding(10, 8, 10, 6),
			FlowDirection = FlowDirection.LeftToRight
		};
		_enabled.Text = "启用功能";
		_enabled.AutoSize = true;
		_enabled.Margin = new Padding(0, 6, 18, 0);
		_enabled.CheckedChanged += delegate { PublishRules("启用状态已更新"); };
		Button delete = new Button { Text = "删除选中", AutoSize = true };
		delete.Click += delegate { DeleteSelectedRule(); };
		Button clearEditor = new Button { Text = "清空输入", AutoSize = true };
		clearEditor.Click += delegate { ClearEditor(); };
		actions.Controls.Add(_enabled);
		actions.Controls.Add(delete);
		actions.Controls.Add(clearEditor);

		_status.Dock = DockStyle.Bottom;
		_status.Height = 40;
		_status.Padding = new Padding(12, 10, 0, 0);
		_status.Text = "背包模型和海报将改写到官方替换资源；战斗内替换未启用。";

		Panel body = new Panel { Dock = DockStyle.Fill, Padding = new Padding(12, 0, 12, 0) };
		body.Controls.Add(_grid);
		body.Controls.Add(actions);
		body.Controls.Add(_status);
		Controls.Add(body);
		Controls.Add(editor);
		Controls.Add(title);
	}

	private static Label CreateHeader(string text)
	{
		return new Label
		{
			Text = text,
			Dock = DockStyle.Fill,
			TextAlign = ContentAlignment.MiddleLeft,
			Font = new Font(SystemFonts.MessageBoxFont, FontStyle.Bold)
		};
	}

	private static void ConfigureEditor(TextBox editor)
	{
		editor.Dock = DockStyle.Fill;
		editor.Margin = new Padding(0, 2, 8, 2);
	}

	private void SaveRule()
	{
		if (!TryParseRequiredId(_originalId.Text, "原型 ID", out int originalId) ||
			!TryParseOptionalId(_backpackId.Text, "背包替换 ID", out int backpackId) ||
			!TryParseOptionalId(_posterId.Text, "海报替换 ID", out int posterId))
		{
			return;
		}
		if (backpackId == 0 && posterId == 0)
		{
			ShowValidationError("背包替换 ID 和海报替换 ID 至少填写一个。");
			return;
		}

		AolaPetMorphRule rule = new AolaPetMorphRule(_note.Text.Trim(), originalId, backpackId, posterId);
		string validationError = _validateRule(rule);
		if (!string.IsNullOrEmpty(validationError))
		{
			ShowValidationError(validationError);
			return;
		}

		int existingIndex = _rules.FindIndex(item => item.OriginalId == originalId);
		if (existingIndex >= 0)
		{
			_rules[existingIndex] = rule;
		}
		else
		{
			_rules.Add(rule);
		}
		RefreshGrid(originalId);
		PublishRules(existingIndex >= 0 ? "规则已更新" : "规则已添加");
	}

	private void DeleteSelectedRule()
	{
		if (_grid.CurrentRow == null || !(_grid.CurrentRow.Tag is AolaPetMorphRule selected))
		{
			_status.Text = "请先选择要删除的规则。";
			return;
		}
		_rules.RemoveAll(item => item.OriginalId == selected.OriginalId);
		RefreshGrid(-1);
		ClearEditor();
		PublishRules("规则已删除");
	}

	private void RefreshGrid(int selectedOriginalId)
	{
		_grid.Rows.Clear();
		foreach (AolaPetMorphRule rule in _rules.OrderBy(item => item.OriginalId))
		{
			int index = _grid.Rows.Add(
				rule.Note,
				rule.OriginalId,
				rule.BackpackId > 0 ? rule.BackpackId.ToString() : "/",
				rule.PosterId > 0 ? rule.PosterId.ToString() : "/");
			_grid.Rows[index].Tag = rule;
			if (rule.OriginalId == selectedOriginalId)
			{
				_grid.Rows[index].Selected = true;
				_grid.CurrentCell = _grid.Rows[index].Cells[0];
			}
		}
	}

	private void LoadSelectedRule()
	{
		if (_grid.CurrentRow == null || !(_grid.CurrentRow.Tag is AolaPetMorphRule selected))
		{
			return;
		}
		_note.Text = selected.Note;
		_originalId.Text = selected.OriginalId.ToString();
		_backpackId.Text = selected.BackpackId > 0 ? selected.BackpackId.ToString() : string.Empty;
		_posterId.Text = selected.PosterId > 0 ? selected.PosterId.ToString() : string.Empty;
	}

	private void ClearEditor()
	{
		_note.Clear();
		_originalId.Clear();
		_backpackId.Clear();
		_posterId.Clear();
		_grid.ClearSelection();
		_originalId.Focus();
	}

	private bool TryParseRequiredId(string value, string fieldName, out int id)
	{
		if (!int.TryParse(value.Trim(), out id) || id <= 0)
		{
			ShowValidationError(fieldName + " 必须是大于 0 的整数。");
			return false;
		}
		return true;
	}

	private bool TryParseOptionalId(string value, string fieldName, out int id)
	{
		string text = value.Trim();
		if (text.Length == 0 || text == "/")
		{
			id = 0;
			return true;
		}
		if (!int.TryParse(text, out id) || id <= 0)
		{
			ShowValidationError(fieldName + " 必须留空、填写 /，或填写大于 0 的整数。");
			return false;
		}
		return true;
	}

	private void ShowValidationError(string message)
	{
		_status.Text = message;
		MessageBox.Show(this, message, "形态变化规则无效", MessageBoxButtons.OK, MessageBoxIcon.Warning);
	}

	private void PublishRules(string message)
	{
		_applyRules(_rules.ToArray(), _enabled.Checked);
		_status.Text = message + "；规则数：" + _rules.Count + "。目标资源不可用时恢复原始请求。";
	}
}
