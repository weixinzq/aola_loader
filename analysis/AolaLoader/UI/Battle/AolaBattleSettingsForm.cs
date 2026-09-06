using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Threading;
using System.Windows.Forms;
using AolaLoader.Features.Battle.Coordination;
using AolaLoader.Features.Battle.Settings;
using AolaLoader.UI.Common;
using AolaLoader.UI.Packets;

namespace AolaLoader.UI.Battle;

internal sealed class AolaBattleSettingsForm : AolaFormBase
{
	private readonly BattlePresentationCoordinator _coordinator;
	private readonly CheckBox _hideDamage = new CheckBox { Text = "隐藏伤害数字", AutoSize = true };
	private readonly CheckBox _hideHealing = new CheckBox { Text = "隐藏治疗数字", AutoSize = true };
	private readonly CheckBox _skipPresentation = new CheckBox
	{
		Text = "跳过每回合战斗演出",
		AutoSize = true
	};
	private readonly CheckBox _battleMorphEnabled = new CheckBox
	{
		Text = "启用战斗模型替换（己方和敌方）",
		AutoSize = true
	};
	private readonly TextBox _morphNote = new TextBox();
	private readonly TextBox _morphSourceId = new TextBox();
	private readonly TextBox _morphTargetId = new TextBox();
	private readonly DataGridView _morphGrid = new DataGridView();
	private readonly List<BattleMorphRule> _morphRules = new List<BattleMorphRule>();
	private readonly CupertinoButton _save = new CupertinoButton("保存并应用", true);
	private readonly Label _status = new Label { AutoSize = false, ForeColor = Color.FromArgb(105, 105, 112) };

	public AolaBattleSettingsForm(BattlePresentationCoordinator coordinator)
	{
		_coordinator = coordinator ?? throw new ArgumentNullException(nameof(coordinator));
		Text = "战斗表现";
		StartPosition = FormStartPosition.CenterParent;
		FormBorderStyle = FormBorderStyle.FixedDialog;
		MaximizeBox = false;
		MinimizeBox = false;
		ClientSize = new Size(820, 650);
		BackColor = Color.FromArgb(245, 245, 247);
		Font = new Font("Microsoft YaHei UI", 10f);

		_save.MinimumSize = new Size(130, 42);
		_save.Click += async delegate { await SaveAsync(); };
		BuildInterface();
		LoadCurrent();
	}

	private void BuildInterface()
	{
		CupertinoCard card = new CupertinoCard
		{
			Dock = DockStyle.Fill,
			Padding = new Padding(28),
			Margin = new Padding(18)
		};
		TableLayoutPanel layout = new TableLayoutPanel
		{
			Dock = DockStyle.Fill,
			ColumnCount = 1,
			RowCount = 8,
			Margin = new Padding(0)
		};
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 54));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 42));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 34));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 42));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 72));
		layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 52));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 58));
		layout.Controls.Add(new Label
		{
			Text = "战斗表现",
			Dock = DockStyle.Fill,
			Font = new Font("Microsoft YaHei UI", 17f, FontStyle.Bold),
			TextAlign = ContentAlignment.MiddleLeft
		}, 0, 0);
		FlowLayoutPanel presentationOptions = new FlowLayoutPanel
		{
			Dock = DockStyle.Fill,
			FlowDirection = FlowDirection.LeftToRight,
			WrapContents = false
		};
		presentationOptions.Controls.Add(_hideDamage);
		presentationOptions.Controls.Add(_hideHealing);
		presentationOptions.Controls.Add(_skipPresentation);
		layout.Controls.Add(presentationOptions, 0, 1);
		layout.Controls.Add(new Label
		{
			Text = "战斗模型替换",
			Dock = DockStyle.Fill,
			Font = new Font(Font, FontStyle.Bold),
			TextAlign = ContentAlignment.MiddleLeft
		}, 0, 2);
		layout.Controls.Add(_battleMorphEnabled, 0, 3);

		TableLayoutPanel editor = new TableLayoutPanel
		{
			Dock = DockStyle.Fill,
			ColumnCount = 4,
			RowCount = 2,
			Margin = new Padding(0)
		};
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 40));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 130));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 130));
		editor.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 250));
		editor.Controls.Add(new Label { Text = "备注", Dock = DockStyle.Fill }, 0, 0);
		editor.Controls.Add(new Label { Text = "模型源 ID", Dock = DockStyle.Fill }, 1, 0);
		editor.Controls.Add(new Label { Text = "模型目标 ID", Dock = DockStyle.Fill }, 2, 0);
		editor.Controls.Add(_morphNote, 0, 1);
		editor.Controls.Add(_morphSourceId, 1, 1);
		editor.Controls.Add(_morphTargetId, 2, 1);
		FlowLayoutPanel ruleActions = new FlowLayoutPanel { Dock = DockStyle.Fill, WrapContents = false };
		CupertinoButton addOrUpdate = new CupertinoButton("添加/更新", true);
		CupertinoButton remove = new CupertinoButton("删除", false);
		addOrUpdate.Click += delegate { AddOrUpdateRule(); };
		remove.Click += delegate { RemoveSelectedRule(); };
		ruleActions.Controls.Add(addOrUpdate);
		ruleActions.Controls.Add(remove);
		editor.Controls.Add(ruleActions, 3, 1);
		layout.Controls.Add(editor, 0, 4);

		_morphGrid.Dock = DockStyle.Fill;
		_morphGrid.AllowUserToAddRows = false;
		_morphGrid.AllowUserToDeleteRows = false;
		_morphGrid.AllowUserToResizeRows = false;
		_morphGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
		_morphGrid.BackgroundColor = Color.White;
		_morphGrid.BorderStyle = BorderStyle.FixedSingle;
		_morphGrid.MultiSelect = false;
		_morphGrid.ReadOnly = true;
		_morphGrid.RowHeadersVisible = false;
		_morphGrid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
		_morphGrid.Columns.Add("Note", "备注");
		_morphGrid.Columns.Add("Source", "模型源 ID");
		_morphGrid.Columns.Add("Target", "模型目标 ID");
		_morphGrid.SelectionChanged += delegate { LoadSelectedRule(); };
		layout.Controls.Add(_morphGrid, 0, 5);

		FlowLayoutPanel actions = new FlowLayoutPanel
		{
			Dock = DockStyle.Fill,
			FlowDirection = FlowDirection.LeftToRight,
			WrapContents = false,
			Margin = new Padding(0)
		};
		actions.Controls.Add(_save);
		layout.Controls.Add(actions, 0, 6);
		_status.Dock = DockStyle.Fill;
		_status.TextAlign = ContentAlignment.TopLeft;
		_status.Text = "战斗模型只修改本地画面；保存前检查双方六分片，战斗中修改会在结束清理后用于下一场。";
		layout.Controls.Add(_status, 0, 7);
		card.Controls.Add(layout);
		Controls.Add(card);
	}

	private void LoadCurrent()
	{
		BattleSettings current = _coordinator.Current;
		_hideDamage.Checked = current.HideDamageNumbers;
		_hideHealing.Checked = current.HideHealingNumbers;
		_skipPresentation.Checked = current.SkipBattlePresentation;
		_battleMorphEnabled.Checked = current.BattleMorphEnabled;
		_morphRules.Clear();
		_morphRules.AddRange(current.MorphRules.Select(rule =>
			new BattleMorphRule(rule.Note, rule.SourceViewId, rule.TargetViewId)));
		RefreshMorphGrid();
		if (current.IgnoredLegacyMorphRuleCount > 0)
		{
			_status.Text = "已忽略 " + current.IgnoredLegacyMorphRuleCount + " 条无法识别的旧战斗模型规则；模型替换保持关闭。";
		}
	}

	private void AddOrUpdateRule()
	{
		if (!int.TryParse(_morphSourceId.Text.Trim(), out int sourceId) ||
			!int.TryParse(_morphTargetId.Text.Trim(), out int targetId))
		{
			_status.Text = "模型源 ID 和目标 ID 必须是整数。";
			return;
		}
		BattleMorphRule candidate = new BattleMorphRule(_morphNote.Text.Trim(), sourceId, targetId);
		string error = _coordinator.ValidateMorphRule(candidate);
		if (error != null)
		{
			_status.Text = error;
			return;
		}
		BattleMorphRule selected = _morphGrid.CurrentRow?.Tag as BattleMorphRule;
		if (_morphRules.Any(rule => rule != selected && rule.SourceViewId == sourceId))
		{
			_status.Text = "同一个战斗模型源 ID 只能配置一次。";
			return;
		}
		if (selected == null) _morphRules.Add(candidate);
		else _morphRules[_morphRules.IndexOf(selected)] = candidate;
		RefreshMorphGrid(candidate);
	}

	private void RemoveSelectedRule()
	{
		if (!(_morphGrid.CurrentRow?.Tag is BattleMorphRule selected)) return;
		_morphRules.Remove(selected);
		RefreshMorphGrid();
		_morphNote.Clear();
		_morphSourceId.Clear();
		_morphTargetId.Clear();
	}

	private void LoadSelectedRule()
	{
		if (!(_morphGrid.CurrentRow?.Tag is BattleMorphRule selected)) return;
		_morphNote.Text = selected.Note;
		_morphSourceId.Text = selected.SourceViewId.ToString();
		_morphTargetId.Text = selected.TargetViewId.ToString();
	}

	private void RefreshMorphGrid(BattleMorphRule selected = null)
	{
		_morphGrid.Rows.Clear();
		foreach (BattleMorphRule rule in _morphRules)
		{
			int index = _morphGrid.Rows.Add(rule.Note, rule.SourceViewId, rule.TargetViewId);
			_morphGrid.Rows[index].Tag = rule;
			if (rule == selected) _morphGrid.Rows[index].Selected = true;
		}
	}

	private async System.Threading.Tasks.Task SaveAsync()
	{
		_save.Enabled = false;
		try
		{
			BattleSettings current = _coordinator.Current;
			BattleSettings candidate = new BattleSettings(
				_hideDamage.Checked,
				_hideHealing.Checked,
				_skipPresentation.Checked,
				_battleMorphEnabled.Checked,
				_morphRules);
			BattlePresentationApplyResult result = await _coordinator.SaveAndApplyAsync(
				candidate,
				CancellationToken.None);
			if (!result.Saved)
			{
				_status.Text = "保存失败：" + result.Message;
			}
			else if (result.BattleMorphActivationPending)
			{
				_status.Text = "规则已保存；当前战斗完成资源清理后自动用于下一场，重启也可生效。";
			}
			else if (result.Applied)
			{
				_status.Text = "设置已保存，并已应用到当前战斗。";
			}
			else if (result.Submitted)
			{
				_status.Text = "设置已保存；进入战斗后自动应用。";
			}
			else
			{
				_status.Text = "设置已保存，但页面桥暂不可用：" + result.Message;
			}
		}
		finally
		{
			if (!IsDisposed) _save.Enabled = true;
		}
	}
}
