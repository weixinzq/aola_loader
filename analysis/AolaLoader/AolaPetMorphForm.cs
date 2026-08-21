using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;

namespace AolaLoader;

internal sealed class AolaPetMorphForm : AolaFormBase
{
	private readonly TextBox _note = new TextBox();
	private readonly TextBox _originalId = new TextBox();
	private readonly TextBox _backpackId = new TextBox();
	private readonly TextBox _posterSourceId = new TextBox();
	private readonly TextBox _posterId = new TextBox();
	private readonly CheckBox _removeOriginalBackground = new CheckBox();
	private readonly CheckBox _replaceBackpackIcon = new CheckBox();
	private readonly CheckBox _hideOriginalModel = new CheckBox();
	private readonly DataGridView _grid = new DataGridView();
	private readonly CheckBox _enabled = new CheckBox();
	private readonly Label _status = new Label();
	private readonly List<AolaPetMorphRule> _rules = new List<AolaPetMorphRule>();
	private readonly Func<AolaPetMorphRule, string> _validateRule;
	private readonly Action<IReadOnlyList<AolaPetMorphRule>, bool> _applyRules;

	public AolaPetMorphForm(
		Func<AolaPetMorphRule, string> validateRule,
		Action<IReadOnlyList<AolaPetMorphRule>, bool> applyRules,
		IReadOnlyList<AolaPetMorphRule> initialRules,
		bool initialEnabled)
	{
		_validateRule = validateRule ?? throw new ArgumentNullException(nameof(validateRule));
		_applyRules = applyRules ?? throw new ArgumentNullException(nameof(applyRules));
		if (initialRules != null)
		{
			_rules.AddRange(initialRules);
		}
		_enabled.Checked = initialEnabled;
		Text = "功能面板 - 形态变化";
		StartPosition = FormStartPosition.CenterParent;
		MinimumSize = new Size(1080, 480);
		Size = new Size(1220, 560);
		BuildLayout();
		RefreshGrid(null);
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
			Height = 100,
			Padding = new Padding(12, 4, 12, 8),
			ColumnCount = 9,
			RowCount = 2
		};
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 14));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 10));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 10));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 10));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 10));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 8));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 8));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 8));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 22));
		editor.RowStyles.Add(new RowStyle(SizeType.Absolute, 34));
		editor.RowStyles.Add(new RowStyle(SizeType.Absolute, 34));
		editor.Controls.Add(CreateHeader("备注"), 0, 0);
		editor.Controls.Add(CreateHeader("模型源 ID"), 1, 0);
		editor.Controls.Add(CreateHeader("模型目标 ID"), 2, 0);
		editor.Controls.Add(CreateHeader("海报源皮肤 ID"), 3, 0);
		editor.Controls.Add(CreateHeader("海报目标皮肤 ID"), 4, 0);
		editor.Controls.Add(CreateHeader("移除原背景"), 5, 0);
		editor.Controls.Add(CreateHeader("替换背包头像"), 6, 0);
		editor.Controls.Add(CreateHeader("隐藏原模型"), 7, 0);
		editor.Controls.Add(CreateHeader("操作"), 8, 0);
		ConfigureEditor(_note);
		ConfigureEditor(_originalId);
		ConfigureEditor(_backpackId);
		ConfigureEditor(_posterSourceId);
		ConfigureEditor(_posterId);
		editor.Controls.Add(_note, 0, 1);
		editor.Controls.Add(_originalId, 1, 1);
		editor.Controls.Add(_backpackId, 2, 1);
		editor.Controls.Add(_posterSourceId, 3, 1);
		editor.Controls.Add(_posterId, 4, 1);
		_removeOriginalBackground.Text = "移除";
		_removeOriginalBackground.AutoSize = true;
		_removeOriginalBackground.Anchor = AnchorStyles.Left;
		editor.Controls.Add(_removeOriginalBackground, 5, 1);
		_replaceBackpackIcon.Text = "替换";
		_replaceBackpackIcon.AutoSize = true;
		_replaceBackpackIcon.Anchor = AnchorStyles.Left;
		editor.Controls.Add(_replaceBackpackIcon, 6, 1);
		_hideOriginalModel.Text = "隐藏";
		_hideOriginalModel.AutoSize = true;
		_hideOriginalModel.Anchor = AnchorStyles.Left;
		editor.Controls.Add(_hideOriginalModel, 7, 1);
		Button save = new Button { Text = "添加 / 更新", Dock = DockStyle.Fill };
		save.Click += delegate { SaveRule(); };
		editor.Controls.Add(save, 8, 1);

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
		_grid.Columns.Add("OriginalId", "模型源 ID");
		_grid.Columns.Add("BackpackId", "模型目标 ID");
		_grid.Columns.Add("PosterSourceId", "海报源 ID");
		_grid.Columns.Add("PosterId", "海报目标 ID");
		_grid.Columns.Add(new DataGridViewCheckBoxColumn
		{
			Name = "RemoveOriginalBackground",
			HeaderText = "移除原背景"
		});
		_grid.Columns.Add(new DataGridViewCheckBoxColumn
		{
			Name = "ReplaceBackpackIcon",
			HeaderText = "替换背包头像"
		});
		_grid.Columns.Add(new DataGridViewCheckBoxColumn
		{
			Name = "HideOriginalModel",
			HeaderText = "隐藏原模型"
		});
		_grid.Columns[0].FillWeight = 150;
		_grid.Columns[1].FillWeight = 80;
		_grid.Columns[2].FillWeight = 90;
		_grid.Columns[3].FillWeight = 90;
		_grid.Columns[4].FillWeight = 90;
		_grid.Columns[5].FillWeight = 65;
		_grid.Columns[6].FillWeight = 75;
		_grid.Columns[7].FillWeight = 65;
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
		_status.Text = "6000→6047：可同时勾选移除原背景和替换背包头像；战斗内替换未启用。";

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
		if (!TryParseOptionalId(_originalId.Text, "模型源 ID", out int originalId) ||
			!TryParseOptionalId(_backpackId.Text, "模型目标 ID", out int backpackId) ||
			!TryParseOptionalId(_posterSourceId.Text, "海报源皮肤 ID", out int posterSourceId) ||
			!TryParseOptionalId(_posterId.Text, "海报目标皮肤 ID", out int posterId))
		{
			return;
		}
		if (backpackId > 0 && originalId == 0)
		{
			ShowValidationError("填写模型目标 ID 时必须同时填写模型源 ID。");
			return;
		}
		if (_hideOriginalModel.Checked && originalId == 0)
		{
			ShowValidationError("隐藏原模型时必须填写模型源 ID。");
			return;
		}
		if (_hideOriginalModel.Checked && backpackId > 0)
		{
			ShowValidationError("隐藏原模型时请将模型目标 ID 留空。");
			return;
		}
		if (_removeOriginalBackground.Checked && originalId == 0)
		{
			ShowValidationError("移除原背景时必须填写模型源 ID。");
			return;
		}
		if (_replaceBackpackIcon.Checked && (originalId == 0 || backpackId == 0))
		{
			ShowValidationError("替换背包头像时必须同时填写模型源 ID 和模型目标 ID。");
			return;
		}
		if (posterId > 0 && posterSourceId == 0 && originalId == 0)
		{
			ShowValidationError("模型形态转海报时请填写模型源 ID；已有海报改写时请填写海报源皮肤 ID。");
			return;
		}
		if (backpackId == 0 && posterId == 0 && !_hideOriginalModel.Checked &&
			!_removeOriginalBackground.Checked && !_replaceBackpackIcon.Checked)
		{
			ShowValidationError("模型目标 ID 和海报目标 ID 至少填写一个。");
			return;
		}

		AolaPetMorphRule rule = new AolaPetMorphRule(
			_note.Text.Trim(), originalId, backpackId, posterSourceId, posterId,
			_hideOriginalModel.Checked, _removeOriginalBackground.Checked,
			_replaceBackpackIcon.Checked);
		string validationError = _validateRule(rule);
		if (!string.IsNullOrEmpty(validationError))
		{
			ShowValidationError(validationError);
			return;
		}

		int existingIndex = _grid.CurrentRow != null &&
			_grid.CurrentRow.Tag is AolaPetMorphRule selectedRule
			? _rules.IndexOf(selectedRule)
			: -1;
		if (existingIndex < 0)
		{
			existingIndex = _rules.FindIndex(item =>
				item.OriginalId == originalId && item.PosterSourceId == posterSourceId);
		}
		if (posterId > 0)
		{
			int effectiveSourceId = posterSourceId > 0 ? posterSourceId : originalId;
			int conflictIndex = _rules.FindIndex(item =>
				(item.PosterSourceId > 0 ? item.PosterSourceId : item.OriginalId) == effectiveSourceId);
			if (conflictIndex >= 0 && conflictIndex != existingIndex)
			{
				ShowValidationError("同一个背包皮肤源 ID 只能对应一个海报目标，请先修改或删除已有规则。");
				return;
			}
		}
		if (existingIndex >= 0)
		{
			_rules[existingIndex] = rule;
		}
		else
		{
			_rules.Add(rule);
		}
		RefreshGrid(rule);
		PublishRules(existingIndex >= 0 ? "规则已更新" : "规则已添加");
	}

	private void DeleteSelectedRule()
	{
		if (_grid.CurrentRow == null || !(_grid.CurrentRow.Tag is AolaPetMorphRule selected))
		{
			_status.Text = "请先选择要删除的规则。";
			return;
		}
		_rules.RemoveAll(item => item.OriginalId == selected.OriginalId &&
			item.PosterSourceId == selected.PosterSourceId);
		RefreshGrid(null);
		ClearEditor();
		PublishRules("规则已删除");
	}

	private void RefreshGrid(AolaPetMorphRule selectedRule)
	{
		_grid.Rows.Clear();
		foreach (AolaPetMorphRule rule in _rules
			.OrderBy(item => item.OriginalId)
			.ThenBy(item => item.PosterSourceId))
		{
			int index = _grid.Rows.Add(
				rule.Note,
				rule.OriginalId > 0 ? rule.OriginalId.ToString() : "/",
				rule.BackpackId > 0 ? rule.BackpackId.ToString() : "/",
				rule.PosterSourceId > 0 ? rule.PosterSourceId.ToString() : "/",
				rule.PosterId > 0 ? rule.PosterId.ToString() : "/",
				rule.RemoveOriginalBackground,
				rule.ReplaceBackpackIcon,
				rule.HideOriginalModel);
			_grid.Rows[index].Tag = rule;
			if (selectedRule != null && rule.OriginalId == selectedRule.OriginalId &&
				rule.PosterSourceId == selectedRule.PosterSourceId)
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
		_originalId.Text = selected.OriginalId > 0 ? selected.OriginalId.ToString() : string.Empty;
		_backpackId.Text = selected.BackpackId > 0 ? selected.BackpackId.ToString() : string.Empty;
		_posterSourceId.Text = selected.PosterSourceId > 0 ? selected.PosterSourceId.ToString() : string.Empty;
		_posterId.Text = selected.PosterId > 0 ? selected.PosterId.ToString() : string.Empty;
		_removeOriginalBackground.Checked = selected.RemoveOriginalBackground;
		_replaceBackpackIcon.Checked = selected.ReplaceBackpackIcon;
		_hideOriginalModel.Checked = selected.HideOriginalModel;
	}

	private void ClearEditor()
	{
		_note.Clear();
		_originalId.Clear();
		_backpackId.Clear();
		_posterSourceId.Clear();
		_posterId.Clear();
		_removeOriginalBackground.Checked = false;
		_replaceBackpackIcon.Checked = false;
		_hideOriginalModel.Checked = false;
		_grid.ClearSelection();
		_posterSourceId.Focus();
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
		_status.Text = message + "；规则数：" + _rules.Count +
			"。规则会热推送到已打开的背包；目标资源不可用时保持原形态。";
	}
}
