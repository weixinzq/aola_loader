// 架构角色：编辑战斗表现和模型规则的 WinForms 界面，只通过协调器保存与应用。
// 数据流：控件值 -> BattleSettings -> BattlePresentationCoordinator -> 分项结果提示。
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
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
		Text = "播放战斗过场（出场、替换及技能额外动画）",
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
	private readonly Label _backgroundSource = new Label { AutoSize = false, ForeColor = Color.FromArgb(105, 105, 112) };
	private readonly Label _status = new Label { AutoSize = false, ForeColor = Color.FromArgb(105, 105, 112) };

	public AolaBattleSettingsForm(BattlePresentationCoordinator coordinator)
	{
		_coordinator = coordinator ?? throw new ArgumentNullException(nameof(coordinator));
		Text = "战斗表现";
		StartPosition = FormStartPosition.CenterParent;
		FormBorderStyle = FormBorderStyle.FixedDialog;
		MaximizeBox = false;
		MinimizeBox = false;
		ClientSize = new Size(820, 700);
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
			RowCount = 9,
			Margin = new Padding(0)
		};
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 54));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 42));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 56));
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
		TableLayoutPanel backgroundRow = new TableLayoutPanel
		{
			Dock = DockStyle.Fill,
			ColumnCount = 3,
			Margin = new Padding(0)
		};
		backgroundRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 110));
		backgroundRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 130));
		backgroundRow.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
		backgroundRow.Controls.Add(new Label
		{
			Text = "战斗背景",
			Dock = DockStyle.Fill,
			Font = new Font(Font, FontStyle.Bold),
			TextAlign = ContentAlignment.MiddleLeft
		}, 0, 0);
		CupertinoButton chooseBackground = new CupertinoButton("选择 JPEG", false)
		{
			MinimumSize = new Size(112, 36),
			Margin = new Padding(0, 8, 12, 0)
		};
		chooseBackground.Click += delegate { ChooseBackgroundImage(); };
		backgroundRow.Controls.Add(chooseBackground, 1, 0);
		_backgroundSource.Dock = DockStyle.Fill;
		_backgroundSource.TextAlign = ContentAlignment.MiddleLeft;
		_backgroundSource.AutoEllipsis = true;
		_backgroundSource.Text = "当前：background.jpg · 按比例铺满画面";
		backgroundRow.Controls.Add(_backgroundSource, 2, 0);
		layout.Controls.Add(backgroundRow, 0, 2);
		layout.Controls.Add(new Label
		{
			Text = "战斗模型替换",
			Dock = DockStyle.Fill,
			Font = new Font(Font, FontStyle.Bold),
			TextAlign = ContentAlignment.MiddleLeft
		}, 0, 3);
		layout.Controls.Add(_battleMorphEnabled, 0, 4);

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
		CupertinoButton add = new CupertinoButton("添加", true);
		CupertinoButton remove = new CupertinoButton("删除", false);
		add.Click += delegate { AddRule(); };
		remove.Click += delegate { RemoveSelectedRule(); };
		ruleActions.Controls.Add(add);
		ruleActions.Controls.Add(remove);
		editor.Controls.Add(ruleActions, 3, 1);
		layout.Controls.Add(editor, 0, 5);

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
		layout.Controls.Add(_morphGrid, 0, 6);

		FlowLayoutPanel actions = new FlowLayoutPanel
		{
			Dock = DockStyle.Fill,
			FlowDirection = FlowDirection.LeftToRight,
			WrapContents = false,
			Margin = new Padding(0)
		};
		actions.Controls.Add(_save);
		layout.Controls.Add(actions, 0, 7);
		_status.Dock = DockStyle.Fill;
		_status.TextAlign = ContentAlignment.TopLeft;
		_status.Text = "战斗模型只修改本地画面；保存前检查双方六分片，战斗中修改会在结束清理后用于下一场。";
		layout.Controls.Add(_status, 0, 8);
		card.Controls.Add(layout);
		Controls.Add(card);
	}

	private void ChooseBackgroundImage()
	{
		using (OpenFileDialog dialog = new OpenFileDialog
		{
			Title = "选择战斗背景",
			Filter = "JPEG 图片 (*.jpg;*.jpeg)|*.jpg;*.jpeg",
			CheckFileExists = true
		})
		{
			if (dialog.ShowDialog(this) != DialogResult.OK) return;
			try
			{
				using (Image image = Image.FromFile(dialog.FileName))
				{
					if (!image.RawFormat.Equals(ImageFormat.Jpeg))
					{
						_status.Text = "请选择 JPEG 图片。";
						return;
					}
				}
				string destination = Path.Combine(AppDomain.CurrentDomain.BaseDirectory,
					"Resources", "Battle", "background.jpg");
				Directory.CreateDirectory(Path.GetDirectoryName(destination));
				if (!string.Equals(Path.GetFullPath(dialog.FileName), destination,
					StringComparison.OrdinalIgnoreCase))
				{
					File.Copy(dialog.FileName, destination, true);
				}
				_backgroundSource.Text = "已选：" + Path.GetFileName(dialog.FileName);
				_status.Text = "背景图片已导入；进入下一场战斗查看，当前战斗不会重新加载。";
			}
			catch (Exception error)
			{
				_status.Text = "背景图片导入失败：" + error.Message;
			}
		}
	}

	private void LoadCurrent()
	{
		BattleSettings current = _coordinator.Current;
		_hideDamage.Checked = current.HideDamageNumbers;
		_hideHealing.Checked = current.HideHealingNumbers;
		_skipPresentation.Checked = !current.SkipBattlePresentation;
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

	private void AddRule()
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
		if (_morphRules.Any(rule => rule.SourceViewId == sourceId))
		{
			_status.Text = "同一个战斗模型源 ID 只能配置一次；如需更换目标，请先删除原规则。";
			return;
		}
		_morphRules.Add(candidate);
		RefreshMorphGrid();
		_morphNote.Clear();
		_morphSourceId.Clear();
		_morphTargetId.Clear();
		_morphNote.Focus();
		_status.Text = "已添加规则；点击“保存并应用”将全部规则保存到程序目录的 settings.json。";
	}

	private void RemoveSelectedRule()
	{
		if (!(_morphGrid.CurrentRow?.Tag is BattleMorphRule selected)) return;
		_morphRules.Remove(selected);
		if (_morphRules.Count == 0) _battleMorphEnabled.Checked = false;
		RefreshMorphGrid();
		_morphNote.Clear();
		_morphSourceId.Clear();
		_morphTargetId.Clear();
		_status.Text = "已删除规则；点击“保存并应用”保存剩余规则。";
	}

	private void RefreshMorphGrid()
	{
		_morphGrid.Rows.Clear();
		foreach (BattleMorphRule rule in _morphRules)
		{
			int index = _morphGrid.Rows.Add(rule.Note, rule.SourceViewId, rule.TargetViewId);
			_morphGrid.Rows[index].Tag = rule;
		}
		_morphGrid.CurrentCell = null;
		_morphGrid.ClearSelection();
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
				!_skipPresentation.Checked,
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
				_status.Text = "设置已保存；演出桥尚未就绪。进入战斗后仍不生效时，请检查战斗桥资源版本。";
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
