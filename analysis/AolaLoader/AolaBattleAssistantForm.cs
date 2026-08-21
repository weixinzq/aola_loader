using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace AolaLoader;

internal sealed class AolaBattleAssistantForm : AolaFormBase
{
	private const int CardWidth = 176;
	private const int CardHeight = 448;
	private readonly AolaBattleStateTracker _tracker;
	private readonly IAolaPetPortraitProvider _portraitProvider;
	private readonly Label _stateDot = new Label();
	private readonly Label _title = new Label();
	private readonly Label _subtitle = new Label();
	private readonly TabControl _sideTabs = new TabControl();
	private readonly TabPage _enemyPage = new TabPage("敌方");
	private readonly TabPage _selfPage = new TabPage("己方");
	private readonly FlowLayoutPanel _enemyCards = CreateCardFlow();
	private readonly FlowLayoutPanel _selfCards = CreateCardFlow();
	private readonly RichTextBox _summary = new RichTextBox();
	private readonly Timer _refreshTimer = new Timer();
	private AolaBattleSnapshot _pendingSnapshot;
	private AolaBattleSnapshot _renderedSnapshot;

	public AolaBattleAssistantForm(AolaBattleStateTracker tracker)
	{
		_tracker = tracker ?? throw new ArgumentNullException(nameof(tracker));
		_portraitProvider = new AolaPetPortraitProvider();
		Text = "对战助手";
		StartPosition = FormStartPosition.CenterParent;
		MinimumSize = new Size(920, 620);
		Size = new Size(1180, 790);
		BackColor = Color.FromArgb(245, 247, 250);
		Font = new Font("Microsoft YaHei UI", 9f);

		Panel header = BuildHeader();
		Panel summaryPanel = BuildSummaryPanel();
		_enemyPage.BackColor = BackColor;
		_selfPage.BackColor = BackColor;
		_enemyPage.Padding = new Padding(5);
		_selfPage.Padding = new Padding(5);
		_enemyPage.Controls.Add(_enemyCards);
		_selfPage.Controls.Add(_selfCards);
		_sideTabs.Dock = DockStyle.Fill;
		_sideTabs.Font = new Font(Font, FontStyle.Bold);
		_sideTabs.TabPages.Add(_enemyPage);
		_sideTabs.TabPages.Add(_selfPage);
		_sideTabs.SelectedTab = _enemyPage;
		_sideTabs.SelectedIndexChanged += delegate
		{
			if (_renderedSnapshot != null)
			{
				RenderSummary(_renderedSnapshot);
			}
		};

		Controls.Add(_sideTabs);
		Controls.Add(summaryPanel);
		Controls.Add(header);

		_refreshTimer.Interval = 100;
		_refreshTimer.Tick += delegate
		{
			_refreshTimer.Stop();
			AolaBattleSnapshot snapshot = _pendingSnapshot;
			_pendingSnapshot = null;
			if (snapshot != null)
			{
				RenderSnapshot(snapshot);
			}
		};

		_tracker.SnapshotChanged += TrackerSnapshotChanged;
		Shown += delegate { QueueSnapshot(_tracker.CurrentSnapshot); };
	}

	protected override void OnFormClosed(FormClosedEventArgs e)
	{
		_tracker.SnapshotChanged -= TrackerSnapshotChanged;
		_refreshTimer.Stop();
		_refreshTimer.Dispose();
		DisposeCardControls(_enemyCards);
		DisposeCardControls(_selfCards);
		base.OnFormClosed(e);
	}

	private Panel BuildHeader()
	{
		Panel header = new Panel
		{
			Dock = DockStyle.Top,
			Height = 82,
			BackColor = Color.White,
			Padding = new Padding(18, 12, 18, 10)
		};
		_stateDot.AutoSize = false;
		_stateDot.Size = new Size(14, 14);
		_stateDot.Location = new Point(20, 24);
		_stateDot.Text = "●";
		_stateDot.ForeColor = Color.DarkGray;
		_stateDot.Font = new Font("Microsoft YaHei UI", 11f, FontStyle.Bold);
		_title.AutoSize = false;
		_title.Location = new Point(44, 13);
		_title.Size = new Size(1080, 28);
		_title.Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right;
		_title.Font = new Font("Microsoft YaHei UI", 12f, FontStyle.Bold);
		_title.Text = "等待进入战斗";
		_subtitle.AutoSize = false;
		_subtitle.Location = new Point(44, 43);
		_subtitle.Size = new Size(1080, 23);
		_subtitle.Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right;
		_subtitle.ForeColor = Color.DimGray;
		_subtitle.Text = "对战助手已就绪，将实时读取服务器返回的战斗数据。";
		header.Controls.Add(_stateDot);
		header.Controls.Add(_title);
		header.Controls.Add(_subtitle);
		return header;
	}

	private Panel BuildSummaryPanel()
	{
		Panel panel = new Panel
		{
			Dock = DockStyle.Bottom,
			Height = 194,
			BackColor = BackColor,
			Padding = new Padding(12, 7, 12, 12)
		};
		_summary.Dock = DockStyle.Fill;
		_summary.ReadOnly = true;
		_summary.BackColor = Color.White;
		_summary.BorderStyle = BorderStyle.FixedSingle;
		_summary.Font = new Font("Microsoft YaHei UI", 8.25f);
		_summary.WordWrap = false;
		_summary.ScrollBars = RichTextBoxScrollBars.Horizontal;
		_summary.Text = "亚比数据由游戏返回，仅供分析参考。";
		panel.Controls.Add(_summary);
		return panel;
	}

	private static FlowLayoutPanel CreateCardFlow()
	{
		return new FlowLayoutPanel
		{
			Dock = DockStyle.Fill,
			AutoScroll = true,
			WrapContents = false,
			FlowDirection = FlowDirection.LeftToRight,
			Padding = new Padding(8),
			BackColor = Color.FromArgb(245, 247, 250)
		};
	}

	private void TrackerSnapshotChanged(AolaBattleSnapshot snapshot)
	{
		if (snapshot == null || IsDisposed || !IsHandleCreated)
		{
			return;
		}
		if (InvokeRequired)
		{
			try
			{
				BeginInvoke(new Action<AolaBattleSnapshot>(QueueSnapshot), snapshot);
			}
			catch (InvalidOperationException)
			{
			}
			return;
		}
		QueueSnapshot(snapshot);
	}

	private void QueueSnapshot(AolaBattleSnapshot snapshot)
	{
		if (snapshot == null || IsDisposed)
		{
			return;
		}
		_pendingSnapshot = snapshot;
		_refreshTimer.Stop();
		_refreshTimer.Start();
	}

	private void RenderSnapshot(AolaBattleSnapshot snapshot)
	{
		_renderedSnapshot = snapshot;
		AolaBattleSideSnapshot selfSide = snapshot.Sides.FirstOrDefault(side => side.SideName == "己方");
		List<AolaBattleSideSnapshot> enemySides = snapshot.Sides.Where(side => side.SideName == "敌方").ToList();
		List<AolaBattlePetSnapshot> selfPets = selfSide?.Pets ?? new List<AolaBattlePetSnapshot>();
		List<AolaBattlePetSnapshot> enemyPets = enemySides.SelectMany(side => side.Pets).ToList();

		if (!snapshot.HasBattle)
		{
			_stateDot.ForeColor = Color.DarkGray;
			_title.Text = "等待进入战斗";
			_subtitle.Text = "对战助手已就绪，将实时读取服务器返回的战斗数据。";
		}
		else
		{
			_stateDot.ForeColor = snapshot.IsEnded ? Color.DarkOrange : Color.FromArgb(27, 190, 116);
			_title.Text = snapshot.IsEnded ? "战斗已结束（保留最后结果）" : "战斗数据已连接";
			List<string> parts = new List<string>();
			if (!string.IsNullOrWhiteSpace(snapshot.BattleUniqueId))
			{
				parts.Add("战斗ID：" + snapshot.BattleUniqueId);
			}
			if (snapshot.SelfPmmId.HasValue)
			{
				parts.Add("己方 pmmId：" + snapshot.SelfPmmId.Value);
			}
			if (!string.IsNullOrWhiteSpace(snapshot.LastCommand))
			{
				parts.Add("最新命令：" + snapshot.LastCommand);
			}
			if (snapshot.LastUpdatedUtc != default)
			{
				parts.Add("更新时间：" + snapshot.LastUpdatedUtc.ToLocalTime().ToString("HH:mm:ss.fff"));
			}
			_subtitle.Text = string.Join("    ", parts);
		}

		_enemyPage.Text = "敌方 (" + enemyPets.Count + ")";
		_selfPage.Text = "己方 (" + selfPets.Count + ")";
		RenderCards(_enemyCards, enemyPets, "尚未收到敌方亚比数据");
		RenderCards(_selfCards, selfPets, "尚未收到己方亚比数据");
		RenderSummary(snapshot);
	}

	private void RenderSummary(AolaBattleSnapshot snapshot)
	{
		string selectedSide = _sideTabs.SelectedTab == _selfPage ? "己方" : "敌方";
		_summary.Text = BuildSummary(snapshot, selectedSide);
		_summary.SelectionStart = 0;
		_summary.ScrollToCaret();
	}

	private void RenderCards(FlowLayoutPanel flow, IList<AolaBattlePetSnapshot> pets, string emptyText)
	{
		flow.SuspendLayout();
		DisposeCardControls(flow);
		if (pets.Count == 0)
		{
			flow.Controls.Add(new Label
			{
				AutoSize = false,
				Size = new Size(420, 70),
				Margin = new Padding(14),
				Text = emptyText,
				ForeColor = Color.Gray,
				TextAlign = ContentAlignment.MiddleCenter
			});
		}
		else
		{
			foreach (AolaBattlePetSnapshot pet in pets)
			{
				flow.Controls.Add(CreatePetCard(pet));
			}
		}
		flow.ResumeLayout(true);
	}

	private Control CreatePetCard(AolaBattlePetSnapshot pet)
	{
		bool defeated = pet.CurrentHp.HasValue && pet.CurrentHp.Value <= 0;
		Panel card = new Panel
		{
			Size = new Size(CardWidth, CardHeight),
			Margin = new Padding(6),
			Padding = new Padding(8),
			BackColor = defeated ? Color.MistyRose : Color.White,
			BorderStyle = BorderStyle.FixedSingle
		};
		PictureBox portrait = new PictureBox
		{
			Location = new Point(8, 8),
			Size = new Size(CardWidth - 18, 112),
			SizeMode = PictureBoxSizeMode.StretchImage,
			Image = _portraitProvider.CreatePortrait(pet, new Size(CardWidth - 18, 112))
		};
		Label name = new Label
		{
			Location = new Point(8, 126),
			Size = new Size(CardWidth - 18, 44),
			Text = pet.Name + (defeated ? "  [已阵亡]" : string.Empty),
			Font = new Font(Font, FontStyle.Bold),
			ForeColor = defeated ? Color.DarkRed : Color.FromArgb(35, 45, 62),
			AutoEllipsis = true
		};
		RichTextBox details = new RichTextBox
		{
			Location = new Point(8, 174),
			Size = new Size(CardWidth - 18, CardHeight - 184),
			ReadOnly = true,
			BackColor = card.BackColor,
			BorderStyle = BorderStyle.None,
			Font = new Font("Microsoft YaHei UI", 8.6f),
			WordWrap = true,
			ScrollBars = RichTextBoxScrollBars.Vertical,
			Text = BuildPetDetails(pet)
		};
		card.Controls.Add(portrait);
		card.Controls.Add(name);
		card.Controls.Add(details);
		return card;
	}

	private static string BuildPetDetails(AolaBattlePetSnapshot pet)
	{
		StringBuilder text = new StringBuilder();
		text.AppendLine("HP：" + FormatNumber(pet.CurrentHp) + "/" + FormatNumber(pet.MaximumHp));
		if (!string.IsNullOrWhiteSpace(pet.Nickname))
		{
			text.AppendLine("昵称：" + pet.Nickname);
		}
		text.AppendLine("等级：" + (pet.Level?.ToString() ?? "—"));
		text.AppendLine("性格：" + (string.IsNullOrWhiteSpace(pet.Character) ? "—" : pet.Character));
		text.AppendLine("战斗槽位：" + (pet.BattleSlotId?.ToString() ?? "—"));
		text.AppendLine("亚比ID(i)：" + (pet.PetId == 0 ? "—" : pet.PetId.ToString()));
		text.AppendLine("种族ID：" + (pet.RaceId == 0 ? "—" : pet.RaceId.ToString()));
		text.AppendLine("外观ID：" + (pet.ViewId == 0 ? "—" : pet.ViewId.ToString()));
		text.AppendLine("唯一ID(uqi)：" + (pet.UniqueId == 0 ? "—" : pet.UniqueId.ToString()));
		text.AppendLine();
		text.AppendLine("技能");
		if (pet.Skills.Count == 0)
		{
			text.AppendLine("—");
		}
		else
		{
			foreach (AolaBattleSkillSnapshot skill in pet.Skills)
			{
				text.AppendLine(skill.Name + "  #" + skill.Id);
				text.AppendLine("PP：" + (skill.PowerPoints ?? "—") + "  CD：" + (skill.Cooldown?.ToString() ?? "—"));
			}
		}
		return text.ToString();
	}

	private static string BuildSummary(AolaBattleSnapshot snapshot, string selectedSide)
	{
		StringBuilder text = new StringBuilder();
		text.AppendLine("亚比数据由游戏返回，仅供分析参考。");
		foreach (AolaBattleSideSnapshot side in snapshot.Sides.Where(side => side.SideName == selectedSide))
		{
			foreach (AolaBattlePetSnapshot pet in side.Pets)
			{
				text.Append(pet.Name);
				text.Append("  HP ").Append(FormatNumber(pet.CurrentHp)).Append('/').Append(FormatNumber(pet.MaximumHp));
				foreach (AolaBattleAbilitySnapshot ability in pet.Abilities)
				{
					text.Append("  ").Append(ability.DisplayName).Append(' ').Append(ability.Total);
				}
				text.AppendLine();
			}
		}
		return text.ToString();
	}

	private static string FormatNumber(long? value)
	{
		return value?.ToString() ?? "—";
	}

	private static void DisposeCardControls(Control container)
	{
		Control[] controls = container.Controls.Cast<Control>().ToArray();
		container.Controls.Clear();
		foreach (Control control in controls)
		{
			foreach (PictureBox picture in control.Controls.OfType<PictureBox>())
			{
				Image image = picture.Image;
				picture.Image = null;
				image?.Dispose();
			}
			control.Dispose();
		}
	}
}
