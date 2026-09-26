// 架构角色：形态规则编辑界面，通过 IPetMorphCoordinator 读取、校验、保存和应用。
// 数据流：用户规则 -> coordinator；资源预检/持久化/推送结果 -> UI。
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using AolaLoader.Features.PetMorph;
using AolaLoader.UI.Common;

namespace AolaLoader.UI.PetMorph;

internal sealed class AolaPetMorphForm : AolaFormBase
{
	private static readonly Color WindowBackground = Color.FromArgb(245, 245, 247);
	private static readonly Color Surface = Color.White;
	private static readonly Color SecondarySurface = Color.FromArgb(242, 242, 247);
	private static readonly Color PrimaryText = Color.FromArgb(29, 29, 31);
	private static readonly Color SecondaryText = Color.FromArgb(110, 110, 115);
	private static readonly Color Separator = Color.FromArgb(226, 226, 232);
	private static readonly Color Accent = Color.FromArgb(0, 122, 255);

	private readonly TextBox _note = new TextBox();
	private readonly TextBox _originalId = new TextBox();
	private readonly TextBox _backpackId = new TextBox();
	private readonly TextBox _posterSourceId = new TextBox();
	private readonly TextBox _posterId = new TextBox();
	private readonly CheckBox _hideOriginalModel = new CheckBox();
	private readonly DataGridView _grid = new DataGridView();
	private readonly CheckBox _enabled = new CheckBox();
	private readonly Label _editorMode = new Label();
	private readonly Label _status = new Label();
	private readonly Button _saveButton = new Button();
	private readonly List<AolaPetMorphRule> _rules = new List<AolaPetMorphRule>();
	private readonly Func<AolaPetMorphRule, string> _validateRule;
	private readonly Action<IReadOnlyList<AolaPetMorphRule>, bool> _applyRules;
	private AolaPetMorphRule _editingRule;
	private bool _refreshingGrid;

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
			_rules.AddRange(initialRules
				.Where(rule => rule != null)
				.Select(NormalizeRuleDefaults));
		}
		_enabled.Checked = initialEnabled;
		Text = "功能面板 - 形态变化";
		StartPosition = FormStartPosition.CenterParent;
		MinimumSize = new Size(1040, 600);
		Size = new Size(1180, 680);
		BackColor = WindowBackground;
		ForeColor = PrimaryText;
		Font = new Font("Microsoft YaHei UI", 9F, FontStyle.Regular, GraphicsUnit.Point);
		BuildLayout();
		RefreshGrid(null);
		ClearEditor();
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
		SuspendLayout();

		TableLayoutPanel root = new TableLayoutPanel
		{
			Dock = DockStyle.Fill,
			BackColor = WindowBackground,
			ColumnCount = 1,
			RowCount = 5,
			Padding = new Padding(0)
		};
		root.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
		root.RowStyles.Add(new RowStyle(SizeType.Absolute, 84F));
		root.RowStyles.Add(new RowStyle(SizeType.Absolute, 150F));
		root.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
		root.RowStyles.Add(new RowStyle(SizeType.Absolute, 58F));
		root.RowStyles.Add(new RowStyle(SizeType.Absolute, 48F));

		Panel header = new Panel
		{
			Dock = DockStyle.Fill,
			BackColor = WindowBackground,
			Padding = new Padding(24, 16, 24, 8),
			Margin = Padding.Empty
		};
		Label title = new Label
		{
			Text = "形态变化",
			Dock = DockStyle.Top,
			Height = 34,
			ForeColor = PrimaryText,
			Font = new Font(Font.FontFamily, 18F, FontStyle.Bold)
		};
		Label subtitle = new Label
		{
			Text = "模型与皮肤映射规则",
			Dock = DockStyle.Top,
			Height = 24,
			ForeColor = SecondaryText,
			Font = new Font(Font.FontFamily, 9F, FontStyle.Regular)
		};
		header.Controls.Add(subtitle);
		header.Controls.Add(title);

		Panel editorCard = new Panel
		{
			Dock = DockStyle.Fill,
			BackColor = Surface,
			Padding = new Padding(16, 10, 16, 14),
			Margin = new Padding(20, 0, 20, 14)
		};
		TableLayoutPanel editor = new TableLayoutPanel
		{
			Dock = DockStyle.Fill,
			BackColor = Surface,
			ColumnCount = 7,
			RowCount = 3,
			Margin = Padding.Empty,
			Padding = Padding.Empty
		};
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 20F));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 12F));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 12F));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 14F));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 14F));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 12F));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 16F));
		editor.RowStyles.Add(new RowStyle(SizeType.Absolute, 30F));
		editor.RowStyles.Add(new RowStyle(SizeType.Absolute, 28F));
		editor.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

		_editorMode.Dock = DockStyle.Fill;
		_editorMode.ForeColor = Accent;
		_editorMode.Font = new Font(Font.FontFamily, 10F, FontStyle.Bold);
		_editorMode.TextAlign = ContentAlignment.MiddleLeft;
		editor.Controls.Add(_editorMode, 0, 0);
		editor.SetColumnSpan(_editorMode, 7);
		editor.Controls.Add(CreateHeader("备注"), 0, 1);
		editor.Controls.Add(CreateHeader("模型源 ID"), 1, 1);
		editor.Controls.Add(CreateHeader("模型目标 ID"), 2, 1);
		editor.Controls.Add(CreateHeader("海报源皮肤 ID"), 3, 1);
		editor.Controls.Add(CreateHeader("海报目标皮肤 ID"), 4, 1);
		editor.Controls.Add(CreateHeader("隐藏原模型"), 5, 1);
		editor.Controls.Add(CreateHeader("操作"), 6, 1);

		ConfigureEditor(_note);
		ConfigureEditor(_originalId);
		ConfigureEditor(_backpackId);
		ConfigureEditor(_posterSourceId);
		ConfigureEditor(_posterId);
		editor.Controls.Add(_note, 0, 2);
		editor.Controls.Add(_originalId, 1, 2);
		editor.Controls.Add(_backpackId, 2, 2);
		editor.Controls.Add(_posterSourceId, 3, 2);
		editor.Controls.Add(_posterId, 4, 2);

		_hideOriginalModel.Text = "隐藏";
		_hideOriginalModel.AutoSize = true;
		_hideOriginalModel.Anchor = AnchorStyles.Left;
		_hideOriginalModel.ForeColor = PrimaryText;
		_hideOriginalModel.Margin = new Padding(0, 8, 0, 0);
		editor.Controls.Add(_hideOriginalModel, 5, 2);

		_saveButton.Dock = DockStyle.Fill;
		_saveButton.Margin = new Padding(0, 3, 0, 3);
		ConfigureButton(_saveButton, true);
		_saveButton.Click += delegate { SaveRule(); };
		editor.Controls.Add(_saveButton, 6, 2);
		editorCard.Controls.Add(editor);

		Panel gridCard = new Panel
		{
			Dock = DockStyle.Fill,
			BackColor = Surface,
			Padding = new Padding(16, 12, 16, 14),
			Margin = new Padding(20, 0, 20, 12)
		};
		TableLayoutPanel gridLayout = new TableLayoutPanel
		{
			Dock = DockStyle.Fill,
			BackColor = Surface,
			ColumnCount = 1,
			RowCount = 3,
			Margin = Padding.Empty,
			Padding = Padding.Empty
		};
		gridLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
		gridLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 30F));
		gridLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 28F));
		gridLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
		gridLayout.Controls.Add(new Label
		{
			Text = "已配置规则",
			Dock = DockStyle.Fill,
			ForeColor = PrimaryText,
			Font = new Font(Font.FontFamily, 11F, FontStyle.Bold),
			TextAlign = ContentAlignment.MiddleLeft
		}, 0, 0);
		gridLayout.Controls.Add(new Label
		{
			Text = "选择一条规则后进入编辑；点击“新建规则”返回新增模式。",
			Dock = DockStyle.Fill,
			ForeColor = SecondaryText,
			Font = new Font(Font.FontFamily, 9F, FontStyle.Regular),
			TextAlign = ContentAlignment.MiddleLeft
		}, 0, 1);

		ConfigureGrid();
		gridLayout.Controls.Add(_grid, 0, 2);
		gridCard.Controls.Add(gridLayout);

		FlowLayoutPanel actions = new FlowLayoutPanel
		{
			Dock = DockStyle.Fill,
			BackColor = WindowBackground,
			Padding = new Padding(20, 8, 20, 8),
			Margin = Padding.Empty,
			FlowDirection = FlowDirection.LeftToRight,
			WrapContents = false
		};
		_enabled.Text = "启用形态变化";
		_enabled.AutoSize = true;
		_enabled.ForeColor = PrimaryText;
		_enabled.Margin = new Padding(0, 9, 22, 0);
		_enabled.CheckedChanged += delegate { PublishRules("启用状态已更新"); };
		Button newRule = new Button { Text = "新建规则", AutoSize = true };
		ConfigureButton(newRule, false);
		newRule.Click += delegate { ClearEditor(); };
		Button delete = new Button { Text = "删除选中", AutoSize = true };
		ConfigureButton(delete, false);
		delete.Click += delegate { DeleteSelectedRule(); };
		actions.Controls.Add(_enabled);
		actions.Controls.Add(newRule);
		actions.Controls.Add(delete);

		_status.Dock = DockStyle.Fill;
		_status.BackColor = SecondarySurface;
		_status.ForeColor = SecondaryText;
		_status.Padding = new Padding(22, 0, 22, 0);
		_status.Margin = Padding.Empty;
		_status.TextAlign = ContentAlignment.MiddleLeft;
		_status.Text = "模型映射会自动移除源背景并替换背包头像；海报规则与隐藏原模型规则保持兼容。";

		root.Controls.Add(header, 0, 0);
		root.Controls.Add(editorCard, 0, 1);
		root.Controls.Add(gridCard, 0, 2);
		root.Controls.Add(actions, 0, 3);
		root.Controls.Add(_status, 0, 4);
		Controls.Add(root);

		ResumeLayout(false);
	}

	private void ConfigureGrid()
	{
		_grid.Dock = DockStyle.Fill;
		_grid.AllowUserToAddRows = false;
		_grid.AllowUserToDeleteRows = false;
		_grid.AllowUserToResizeRows = false;
		_grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
		_grid.BackgroundColor = Surface;
		_grid.BorderStyle = BorderStyle.None;
		_grid.CellBorderStyle = DataGridViewCellBorderStyle.SingleHorizontal;
		_grid.ColumnHeadersBorderStyle = DataGridViewHeaderBorderStyle.None;
		_grid.ColumnHeadersHeight = 36;
		_grid.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.DisableResizing;
		_grid.EnableHeadersVisualStyles = false;
		_grid.GridColor = Separator;
		_grid.MultiSelect = false;
		_grid.ReadOnly = true;
		_grid.RowHeadersVisible = false;
		_grid.RowTemplate.Height = 34;
		_grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
		_grid.ColumnHeadersDefaultCellStyle.BackColor = SecondarySurface;
		_grid.ColumnHeadersDefaultCellStyle.ForeColor = PrimaryText;
		_grid.ColumnHeadersDefaultCellStyle.Font = new Font(Font.FontFamily, 9F, FontStyle.Bold);
		_grid.ColumnHeadersDefaultCellStyle.SelectionBackColor = SecondarySurface;
		_grid.ColumnHeadersDefaultCellStyle.SelectionForeColor = PrimaryText;
		_grid.DefaultCellStyle.BackColor = Surface;
		_grid.DefaultCellStyle.ForeColor = PrimaryText;
		_grid.DefaultCellStyle.SelectionBackColor = Color.FromArgb(225, 239, 255);
		_grid.DefaultCellStyle.SelectionForeColor = PrimaryText;
		_grid.DefaultCellStyle.Padding = new Padding(4, 0, 4, 0);
		_grid.Columns.Add("Note", "备注");
		_grid.Columns.Add("OriginalId", "模型源 ID");
		_grid.Columns.Add("BackpackId", "模型目标 ID");
		_grid.Columns.Add("PosterSourceId", "海报源 ID");
		_grid.Columns.Add("PosterId", "海报目标 ID");
		_grid.Columns.Add(new DataGridViewCheckBoxColumn
		{
			Name = "HideOriginalModel",
			HeaderText = "隐藏原模型"
		});
		_grid.Columns[0].FillWeight = 180;
		_grid.Columns[1].FillWeight = 90;
		_grid.Columns[2].FillWeight = 100;
		_grid.Columns[3].FillWeight = 105;
		_grid.Columns[4].FillWeight = 105;
		_grid.Columns[5].FillWeight = 75;
		_grid.SelectionChanged += delegate { LoadSelectedRule(); };
	}

	private Label CreateHeader(string text)
	{
		return new Label
		{
			Text = text,
			Dock = DockStyle.Fill,
			ForeColor = SecondaryText,
			TextAlign = ContentAlignment.MiddleLeft,
			Font = new Font(Font.FontFamily, 8.5F, FontStyle.Bold),
			Margin = Padding.Empty
		};
	}

	private static void ConfigureEditor(TextBox editor)
	{
		editor.Dock = DockStyle.Fill;
		editor.BorderStyle = BorderStyle.FixedSingle;
		editor.Margin = new Padding(0, 4, 10, 4);
	}

	private static void ConfigureButton(Button button, bool primary)
	{
		button.FlatStyle = FlatStyle.Flat;
		button.Cursor = Cursors.Hand;
		button.Font = new Font("Microsoft YaHei UI", 9F, FontStyle.Regular, GraphicsUnit.Point);
		button.MinimumSize = new Size(96, 34);
		button.Padding = new Padding(12, 0, 12, 0);
		button.Margin = new Padding(0, 0, 10, 0);
		button.UseVisualStyleBackColor = false;
		button.BackColor = primary ? Accent : Surface;
		button.ForeColor = primary ? Color.White : PrimaryText;
		button.FlatAppearance.BorderSize = primary ? 0 : 1;
		button.FlatAppearance.BorderColor = Separator;
		button.FlatAppearance.MouseOverBackColor = primary
			? Color.FromArgb(0, 110, 230)
			: SecondarySurface;
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
		if (posterId > 0 && posterSourceId == 0 && originalId == 0)
		{
			ShowValidationError("模型形态转海报时请填写模型源 ID；已有海报改写时请填写海报源皮肤 ID。");
			return;
		}
		if (backpackId == 0 && posterId == 0 && !_hideOriginalModel.Checked)
		{
			ShowValidationError("模型目标 ID 和海报目标 ID 至少填写一个。");
			return;
		}

		AolaPetMorphRule rule = new AolaPetMorphRule(
			_note.Text.Trim(), originalId, backpackId, posterSourceId, posterId,
			_hideOriginalModel.Checked,
			removeOriginalBackground: originalId > 0,
			replaceBackpackIcon: originalId > 0 && backpackId > 0);
		string validationError = _validateRule(rule);
		if (!string.IsNullOrEmpty(validationError))
		{
			ShowValidationError(validationError);
			return;
		}

		int existingIndex = _editingRule == null ? -1 : _rules.IndexOf(_editingRule);
		int duplicateIndex = _rules.FindIndex(item =>
			item.OriginalId == originalId && item.PosterSourceId == posterSourceId);
		if (duplicateIndex >= 0 && duplicateIndex != existingIndex)
		{
			ShowValidationError("相同模型源 ID 与海报源 ID 的规则已经存在。请在列表中选择该规则后修改。");
			return;
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
			_editingRule = rule;
			RefreshGrid(rule);
			PublishRules("规则已更新");
			return;
		}

		_rules.Add(rule);
		RefreshGrid(null);
		ClearEditor();
		PublishRules("规则已添加，可继续添加下一条");
	}

	private void DeleteSelectedRule()
	{
		if (_grid.CurrentRow == null || !(_grid.CurrentRow.Tag is AolaPetMorphRule selected))
		{
			_status.Text = "请先选择要删除的规则。";
			return;
		}
		_rules.Remove(selected);
		RefreshGrid(null);
		ClearEditor();
		PublishRules("规则已删除");
	}

	private void RefreshGrid(AolaPetMorphRule selectedRule)
	{
		_refreshingGrid = true;
		try
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
					rule.HideOriginalModel);
				_grid.Rows[index].Tag = rule;
				if (ReferenceEquals(rule, selectedRule))
				{
					_grid.Rows[index].Selected = true;
					_grid.CurrentCell = _grid.Rows[index].Cells[0];
				}
			}
			if (selectedRule == null)
			{
				_grid.CurrentCell = null;
				_grid.ClearSelection();
			}
		}
		finally
		{
			_refreshingGrid = false;
		}
	}

	private void LoadSelectedRule()
	{
		if (_refreshingGrid || _grid.CurrentRow == null ||
			!(_grid.CurrentRow.Tag is AolaPetMorphRule selected))
		{
			return;
		}
		_editingRule = selected;
		_note.Text = selected.Note;
		_originalId.Text = selected.OriginalId > 0 ? selected.OriginalId.ToString() : string.Empty;
		_backpackId.Text = selected.BackpackId > 0 ? selected.BackpackId.ToString() : string.Empty;
		_posterSourceId.Text = selected.PosterSourceId > 0 ? selected.PosterSourceId.ToString() : string.Empty;
		_posterId.Text = selected.PosterId > 0 ? selected.PosterId.ToString() : string.Empty;
		_hideOriginalModel.Checked = selected.HideOriginalModel;
		UpdateEditorMode();
	}

	private void ClearEditor()
	{
		_editingRule = null;
		_note.Clear();
		_originalId.Clear();
		_backpackId.Clear();
		_posterSourceId.Clear();
		_posterId.Clear();
		_hideOriginalModel.Checked = false;
		_refreshingGrid = true;
		try
		{
			_grid.CurrentCell = null;
			_grid.ClearSelection();
		}
		finally
		{
			_refreshingGrid = false;
		}
		UpdateEditorMode();
		_note.Focus();
	}

	private void UpdateEditorMode()
	{
		bool editing = _editingRule != null;
		_editorMode.Text = editing ? "编辑规则" : "新增规则";
		_saveButton.Text = editing ? "保存修改" : "添加规则";
	}

	private static AolaPetMorphRule NormalizeRuleDefaults(AolaPetMorphRule rule)
	{
		return new AolaPetMorphRule(
			rule.Note,
			rule.OriginalId,
			rule.BackpackId,
			rule.PosterSourceId,
			rule.PosterId,
			rule.HideOriginalModel,
			removeOriginalBackground: rule.OriginalId > 0,
			replaceBackpackIcon: rule.OriginalId > 0 && rule.BackpackId > 0);
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
