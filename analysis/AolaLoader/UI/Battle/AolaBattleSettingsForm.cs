using System;
using System.Drawing;
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
	private readonly CheckBox _skipAttack = new CheckBox
	{
		Text = "跳过精灵出手动画",
		AutoSize = true
	};
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
		ClientSize = new Size(520, 330);
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
			RowCount = 6,
			Margin = new Padding(0)
		};
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 54));
		for (int index = 0; index < 3; index++) layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 36));
		layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 52));
		layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
		layout.Controls.Add(new Label
		{
			Text = "战斗表现",
			Dock = DockStyle.Fill,
			Font = new Font("Microsoft YaHei UI", 17f, FontStyle.Bold),
			TextAlign = ContentAlignment.MiddleLeft
		}, 0, 0);
		layout.Controls.Add(_hideDamage, 0, 1);
		layout.Controls.Add(_hideHealing, 0, 2);
		layout.Controls.Add(_skipAttack, 0, 3);

		FlowLayoutPanel actions = new FlowLayoutPanel
		{
			Dock = DockStyle.Fill,
			FlowDirection = FlowDirection.LeftToRight,
			WrapContents = false,
			Margin = new Padding(0)
		};
		actions.Controls.Add(_save);
		layout.Controls.Add(actions, 0, 4);
		_status.Dock = DockStyle.Fill;
		_status.TextAlign = ContentAlignment.TopLeft;
		_status.Text = "仅跳过攻击者出手动作；技能结算、受击、换宠和对战信息仍走官方流程。";
		layout.Controls.Add(_status, 0, 5);
		card.Controls.Add(layout);
		Controls.Add(card);
	}

	private void LoadCurrent()
	{
		BattleSettings current = _coordinator.Current;
		_hideDamage.Checked = current.HideDamageNumbers;
		_hideHealing.Checked = current.HideHealingNumbers;
		_skipAttack.Checked = current.SkipAttackAnimation;
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
				_skipAttack.Checked,
				current.MorphRules);
			BattlePresentationApplyResult result = await _coordinator.SaveAndApplyAsync(
				candidate,
				CancellationToken.None);
			if (!result.Saved)
			{
				_status.Text = "保存失败：" + result.Message;
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
