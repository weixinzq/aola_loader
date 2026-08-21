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

	private readonly TextBox _battleNote = new TextBox();
	private readonly TextBox _battleSourceId = new TextBox();
	private readonly TextBox _battleTargetId = new TextBox();
	private readonly ComboBox _battleScope = new ComboBox();
	private readonly DataGridView _battleGrid = new DataGridView();
	private readonly CheckBox _battleMorphEnabled = new CheckBox();
	private readonly CheckBox _battleDisplayEnabled = new CheckBox();
	private readonly CheckBox _hideDamageNumbers = new CheckBox();
	private readonly CheckBox _hideHealingNumbers = new CheckBox();
	private readonly CheckBox _skipPetAttackActions = new CheckBox();
	private readonly CheckBox _disableSkillEffects = new CheckBox();
	private readonly List<AolaBattleMorphRule> _battleRules = new List<AolaBattleMorphRule>();
	private readonly Func<AolaBattleMorphRule, string> _validateBattleRule;
	private readonly Action<IReadOnlyList<AolaBattleMorphRule>, bool> _applyBattleRules;
	private readonly Func<BattleDisplayState> _buildBattleDisplay;
	private readonly Action<BattleDisplayState> _applyBattleDisplay;

	public AolaPetMorphForm(
		Func<AolaPetMorphRule, string> validateRule,
		Action<IReadOnlyList<AolaPetMorphRule>, bool> applyRules,
		IReadOnlyList<AolaPetMorphRule> initialRules,
		bool initialEnabled,
		Func<AolaBattleMorphRule, string> validateBattleRule,
		Action<IReadOnlyList<AolaBattleMorphRule>, bool> applyBattleRules,
		IReadOnlyList<AolaBattleMorphRule> initialBattleRules,
		bool initialBattleMorphEnabled,
		Func<BattleDisplayState> buildBattleDisplay,
		Action<BattleDisplayState> applyBattleDisplay)
	{
		_validateRule = validateRule ?? throw new ArgumentNullException(nameof(validateRule));
		_applyRules = applyRules ?? throw new ArgumentNullException(nameof(applyRules));
		_validateBattleRule = validateBattleRule ?? throw new ArgumentNullException(nameof(validateBattleRule));
		_applyBattleRules = applyBattleRules ?? throw new ArgumentNullException(nameof(applyBattleRules));
		_buildBattleDisplay = buildBattleDisplay ?? throw new ArgumentNullException(nameof(buildBattleDisplay));
		_applyBattleDisplay = applyBattleDisplay ?? throw new ArgumentNullException(nameof(applyBattleDisplay));
		if (initialRules != null)
		{
			_rules.AddRange(initialRules);
		}
		if (initialBattleRules != null)
		{
			_battleRules.AddRange(initialBattleRules);
		}
		_enabled.Checked = initialEnabled;
		_battleMorphEnabled.Checked = initialBattleMorphEnabled;
		Text = "功能面板 - 形态变化 / 战斗表现";
		StartPosition = FormStartPosition.CenterParent;
		MinimumSize = new Size(1160, 560);
		Size = new Size(1300, 640);
		BuildLayout();
		RefreshGrid(null);
		RefreshBattleGrid(null);
		LoadBattleDisplay();
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
			Text = "功能面板",
			Dock = DockStyle.Top,
			Height = 48,
			Padding = new Padding(14, 12, 0, 0),
			Font = new Font(Font.FontFamily, 15F, FontStyle.Bold)
		};

		TabControl tabs = new TabControl
		{
			Dock = DockStyle.Fill,
			Padding = new Point(12, 6)
		};
		tabs.TabPages.Add("背包形态");
		tabs.TabPages.Add("战斗表现");
		tabs.TabPages[0].Controls.Add(BuildBackpackTab());
		tabs.TabPages[1].Controls.Add(BuildBattleTab());

		_status.Dock = DockStyle.Bottom;
		_status.Height = 40;
		_status.Padding = new Padding(12, 10, 0, 0);
		_status.Text = "战斗表现与战斗模型替换均为独立配置，默认关闭；模型替换在目标分片全部可用后于下一场战斗生效。";

		Controls.Add(_status);
		Controls.Add(tabs);
		Controls.Add(title);
	}

	private Control BuildBackpackTab()
	{
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

		ConfigureGrid(_grid);
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

		Panel body = new Panel { Dock = DockStyle.Fill, Padding = new Padding(12, 0, 12, 0) };
		body.Controls.Add(_grid);
		body.Controls.Add(actions);
		body.Controls.Add(editor);
		return body;
	}

	private Control BuildBattleTab()
	{
		TableLayoutPanel editor = new TableLayoutPanel
		{
			Dock = DockStyle.Top,
			Height = 100,
			Padding = new Padding(12, 4, 12, 8),
			ColumnCount = 6,
			RowCount = 2
		};
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 20));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 16));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 16));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 16));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 12));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 20));
		editor.RowStyles.Add(new RowStyle(SizeType.Absolute, 34));
		editor.RowStyles.Add(new RowStyle(SizeType.Absolute, 34));
		editor.Controls.Add(CreateHeader("备注"), 0, 0);
		editor.Controls.Add(CreateHeader("战斗模型源 ID"), 1, 0);
		editor.Controls.Add(CreateHeader("战斗模型目标 ID"), 2, 0);
		editor.Controls.Add(CreateHeader("生效范围"), 3, 0);
		editor.Controls.Add(CreateHeader("启用"), 4, 0);
		editor.Controls.Add(CreateHeader("操作"), 5, 0);
		ConfigureEditor(_battleNote);
		ConfigureEditor(_battleSourceId);
		ConfigureEditor(_battleTargetId);
		_battleScope.Dock = DockStyle.Fill;
		_battleScope.DropDownStyle = ComboBoxStyle.DropDownList;
		_battleScope.Items.Add("双方");
		_battleScope.Items.Add("己方");
		_battleScope.Items.Add("敌方");
		_battleScope.SelectedIndex = 0;
		editor.Controls.Add(_battleNote, 0, 1);
		editor.Controls.Add(_battleSourceId, 1, 1);
		editor.Controls.Add(_battleTargetId, 2, 1);
		editor.Controls.Add(_battleScope, 3, 1);
		_battleMorphEnabled.Text = "启用";
		_battleMorphEnabled.AutoSize = true;
		_battleMorphEnabled.Anchor = AnchorStyles.Left;
		editor.Controls.Add(_battleMorphEnabled, 4, 1);
		Button save = new Button { Text = "添加 / 更新", Dock = DockStyle.Fill };
		save.Click += delegate { SaveBattleRule(); };
		editor.Controls.Add(save, 5, 1);

		ConfigureGrid(_battleGrid);
		_battleGrid.Columns.Add("Note", "备注");
		_battleGrid.Columns.Add("SourceId", "模型源 ID");
		_battleGrid.Columns.Add("TargetId", "模型目标 ID");
		_battleGrid.Columns.Add("Scope", "生效范围");
		_battleGrid.Columns.Add(new DataGridViewCheckBoxColumn
		{
			Name = "Enabled",
			HeaderText = "启用"
		});
		_battleGrid.Columns[0].FillWeight = 140;
		_battleGrid.Columns[1].FillWeight = 90;
		_battleGrid.Columns[2].FillWeight = 90;
		_battleGrid.Columns[3].FillWeight = 70;
		_battleGrid.Columns[4].FillWeight = 50;
		_battleGrid.SelectionChanged += delegate { LoadSelectedBattleRule(); };

		FlowLayoutPanel display = new FlowLayoutPanel
		{
			Dock = DockStyle.Top,
			Height = 48,
			Padding = new Padding(12, 8, 12, 4),
			FlowDirection = FlowDirection.LeftToRight
		};
		_battleDisplayEnabled.Text = "启用战斗表现";
		_battleDisplayEnabled.AutoSize = true;
		_battleDisplayEnabled.Margin = new Padding(0, 6, 18, 0);
		_battleDisplayEnabled.CheckedChanged += delegate { PublishBattleDisplay("战斗表现开关已更新"); };
		_hideDamageNumbers.Text = "隐藏伤害数字";
		_hideDamageNumbers.AutoSize = true;
		_hideDamageNumbers.Margin = new Padding(0, 6, 12, 0);
		_hideDamageNumbers.CheckedChanged += delegate { PublishBattleDisplay("伤害数字设置已更新"); };
		_hideHealingNumbers.Text = "隐藏治疗数字";
		_hideHealingNumbers.AutoSize = true;
		_hideHealingNumbers.Margin = new Padding(0, 6, 12, 0);
		_hideHealingNumbers.CheckedChanged += delegate { PublishBattleDisplay("治疗数字设置已更新"); };
		_skipPetAttackActions.Text = "屏蔽亚比出手动作";
		_skipPetAttackActions.AutoSize = true;
		_skipPetAttackActions.Margin = new Padding(0, 6, 12, 0);
		_skipPetAttackActions.CheckedChanged += delegate { PublishBattleDisplay("出手动作设置已更新"); };
		_disableSkillEffects.Text = "屏蔽技能特效";
		_disableSkillEffects.AutoSize = true;
		_disableSkillEffects.Margin = new Padding(0, 6, 0, 0);
		_disableSkillEffects.CheckedChanged += delegate { PublishBattleDisplay("技能特效设置已更新"); };
		display.Controls.Add(_battleDisplayEnabled);
		display.Controls.Add(_hideDamageNumbers);
		display.Controls.Add(_hideHealingNumbers);
		display.Controls.Add(_skipPetAttackActions);
		display.Controls.Add(_disableSkillEffects);

		FlowLayoutPanel actions = new FlowLayoutPanel
		{
			Dock = DockStyle.Bottom,
			Height = 48,
			Padding = new Padding(10, 8, 10, 6),
			FlowDirection = FlowDirection.LeftToRight
		};
		Button delete = new Button { Text = "删除选中", AutoSize = true };
		delete.Click += delegate { DeleteSelectedBattleRule(); };
		Button clearEditor = new Button { Text = "清空输入", AutoSize = true };
		clearEditor.Click += delegate { ClearBattleEditor(); };
		actions.Controls.Add(delete);
		actions.Controls.Add(clearEditor);

		Panel body = new Panel { Dock = DockStyle.Fill, Padding = new Padding(12, 0, 12, 0) };
		body.Controls.Add(_battleGrid);
		body.Controls.Add(actions);
		body.Controls.Add(display);
		body.Controls.Add(editor);
		return body;
	}

	private static void ConfigureGrid(DataGridView grid)
	{
		grid.Dock = DockStyle.Fill;
		grid.AllowUserToAddRows = false;
		grid.AllowUserToDeleteRows = false;
		grid.AllowUserToResizeRows = false;
		grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
		grid.BackgroundColor = SystemColors.Window;
		grid.BorderStyle = BorderStyle.FixedSingle;
		grid.MultiSelect = false;
		grid.ReadOnly = true;
		grid.RowHeadersVisible = false;
		grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
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

	private void SaveBattleRule()
	{
		if (!TryParseRequiredId(_battleSourceId.Text, "战斗模型源 ID", out int sourceId) ||
			!TryParseRequiredId(_battleTargetId.Text, "战斗模型目标 ID", out int targetId))
		{
			return;
		}
		BattleScope scope = BattleScope.Both;
		switch (_battleScope.SelectedIndex)
		{
			case 1: scope = BattleScope.Self; break;
			case 2: scope = BattleScope.Enemy; break;
		}
		AolaBattleMorphRule rule = new AolaBattleMorphRule(
			_battleNote.Text.Trim(), sourceId, targetId, scope, _battleMorphEnabled.Checked);
		string validationError = _validateBattleRule(rule);
		if (!string.IsNullOrEmpty(validationError))
		{
			ShowValidationError(validationError);
			return;
		}

		int existingIndex = _battleGrid.CurrentRow != null &&
			_battleGrid.CurrentRow.Tag is AolaBattleMorphRule selectedRule
			? _battleRules.IndexOf(selectedRule)
			: -1;
		if (existingIndex < 0)
		{
			existingIndex = _battleRules.FindIndex(item => item.SourceId == sourceId);
		}
		if (existingIndex >= 0)
		{
			_battleRules[existingIndex] = rule;
		}
		else
		{
			_battleRules.Add(rule);
		}
		RefreshBattleGrid(rule);
		PublishBattleRules(existingIndex >= 0 ? "战斗规则已更新" : "战斗规则已添加");
	}

	private void DeleteSelectedBattleRule()
	{
		if (_battleGrid.CurrentRow == null || !(_battleGrid.CurrentRow.Tag is AolaBattleMorphRule selected))
		{
			_status.Text = "请先选择要删除的战斗规则。";
			return;
		}
		_battleRules.RemoveAll(item => item.SourceId == selected.SourceId);
		RefreshBattleGrid(null);
		ClearBattleEditor();
		PublishBattleRules("战斗规则已删除");
	}

	private void RefreshBattleGrid(AolaBattleMorphRule selectedRule)
	{
		_battleGrid.Rows.Clear();
		foreach (AolaBattleMorphRule rule in _battleRules
			.OrderBy(item => item.SourceId))
		{
			string scope = rule.Scope == BattleScope.Self ? "己方"
				: rule.Scope == BattleScope.Enemy ? "敌方" : "双方";
			int index = _battleGrid.Rows.Add(
				rule.Note, rule.SourceId, rule.TargetId, scope, rule.Enabled);
			_battleGrid.Rows[index].Tag = rule;
			if (selectedRule != null && rule.SourceId == selectedRule.SourceId)
			{
				_battleGrid.Rows[index].Selected = true;
				_battleGrid.CurrentCell = _battleGrid.Rows[index].Cells[0];
			}
		}
	}

	private void LoadSelectedBattleRule()
	{
		if (_battleGrid.CurrentRow == null || !(_battleGrid.CurrentRow.Tag is AolaBattleMorphRule selected))
		{
			return;
		}
		_battleNote.Text = selected.Note;
		_battleSourceId.Text = selected.SourceId.ToString();
		_battleTargetId.Text = selected.TargetId.ToString();
		_battleScope.SelectedIndex = selected.Scope == BattleScope.Self ? 1
			: selected.Scope == BattleScope.Enemy ? 2 : 0;
		_battleMorphEnabled.Checked = selected.Enabled;
	}

	private void ClearBattleEditor()
	{
		_battleNote.Clear();
		_battleSourceId.Clear();
		_battleTargetId.Clear();
		_battleScope.SelectedIndex = 0;
		_battleMorphEnabled.Checked = true;
		_battleGrid.ClearSelection();
		_battleSourceId.Focus();
	}

	private void LoadBattleDisplay()
	{
		BattleDisplayState state = _buildBattleDisplay();
		_battleDisplayEnabled.Checked = state != null && state.Enabled;
		_hideDamageNumbers.Checked = state != null && state.HideDamageNumbers;
		_hideHealingNumbers.Checked = state != null && state.HideHealingNumbers;
		_skipPetAttackActions.Checked = state != null && state.SkipPetAttackActions;
		_disableSkillEffects.Checked = state != null && state.DisableSkillEffects;
	}

	private void PublishBattleDisplay(string message)
	{
		_applyBattleDisplay(new BattleDisplayState
		{
			Enabled = _battleDisplayEnabled.Checked,
			HideDamageNumbers = _hideDamageNumbers.Checked,
			HideHealingNumbers = _hideHealingNumbers.Checked,
			SkipPetAttackActions = _skipPetAttackActions.Checked,
			DisableSkillEffects = _disableSkillEffects.Checked
		});
		_status.Text = message + "；已实时推送战斗模块，新战斗开始时再次应用。";
	}

	private void PublishBattleRules(string message)
	{
		_applyBattleRules(_battleRules.ToArray(), _battleMorphEnabled.Checked);
		_status.Text = message + "；规则数：" + _battleRules.Count +
			"。目标分片全部可用后于下一场战斗或重启后完全生效。";
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

	private bool TryParseRequiredId(string value, string fieldName, out int id)
	{
		string text = value.Trim();
		if (!int.TryParse(text, out id) || id <= 0)
		{
			ShowValidationError(fieldName + " 必须填写大于 0 的整数。");
			return false;
		}
		return true;
	}

	private void ShowValidationError(string message)
	{
		_status.Text = message;
		MessageBox.Show(this, message, "规则无效", MessageBoxButtons.OK, MessageBoxIcon.Warning);
	}

	private void PublishRules(string message)
	{
		_applyRules(_rules.ToArray(), _enabled.Checked);
		_status.Text = message + "；规则数：" + _rules.Count +
			"。规则会热推送到已打开的背包；目标资源不可用时保持原形态。";
	}
}
