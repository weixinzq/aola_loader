using System;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using AolaLoader.Features.Battle.Data;
using AolaLoader.Features.Battle.State;
using AolaLoader.UI.Common;

namespace AolaLoader.UI.Battle;

internal sealed class AolaBattleAssistantForm : AolaFormBase
{
	private readonly AolaBattleStateTracker _tracker;
	private readonly Label _status = new Label();
	private readonly Button _attributes = new Button();
	private readonly Button _configuration = new Button();
	private readonly FlowLayoutPanel _cards = new FlowLayoutPanel();
	private readonly BattleLoadoutView _loadout = new BattleLoadoutView();
	private readonly Timer _refreshTimer = new Timer { Interval = 100 };
	private AolaBattleSnapshot _pending;
	private BattleConfigurationCatalog _catalog;
	private bool _showConfiguration;

	public AolaBattleAssistantForm(AolaBattleStateTracker tracker)
	{
		_tracker = tracker ?? throw new ArgumentNullException(nameof(tracker));
		Text = "对战助手";
		StartPosition = FormStartPosition.CenterParent;
		MinimumSize = new Size(920, 620);
		Size = new Size(1110, 790);
		BackColor = Color.FromArgb(245, 245, 247);
		Font = new Font("Microsoft YaHei UI", 10f);
		AutoScaleMode = AutoScaleMode.Dpi;
		var header = new Panel { Dock = DockStyle.Top, Height = 76, Padding = new Padding(20), BackColor = Color.White };
		_status.SetBounds(24, 24, 600, 28);
		_status.Text = "等待敌方资料";
		_status.Font = new Font(Font.FontFamily, 12, FontStyle.Bold);
		_attributes.Text = "属性";
		_configuration.Text = "配置";
		foreach (Button button in new[] { _attributes, _configuration })
		{
			button.Size = new Size(86, 34);
			button.FlatStyle = FlatStyle.Flat;
			button.FlatAppearance.BorderSize = 0;
			button.Anchor = AnchorStyles.Top | AnchorStyles.Right;
			header.Controls.Add(button);
		}
		header.Resize += delegate
		{
			_attributes.Location = new Point(header.Width - 198, 20);
			_configuration.Location = new Point(header.Width - 110, 20);
			_status.Width = Math.Max(100, header.Width - 250);
		};
		header.Controls.Add(_status);
		_cards.Dock = DockStyle.Fill;
		_cards.AutoScroll = true;
		_cards.WrapContents = false;
		_cards.Padding = new Padding(16);
		Controls.Add(_cards);
		Controls.Add(_loadout);
		Controls.Add(header);
		_attributes.Click += delegate { SelectView(false); };
		_configuration.Click += delegate { SelectView(true); };
		SelectView(false);
		_refreshTimer.Tick += delegate
		{
			_refreshTimer.Stop();
			if (_pending != null && _catalog != null)
			{
				AolaBattleSnapshot snapshot = _pending;
				_pending = null;
				Render(snapshot);
			}
		};
		_tracker.SnapshotChanged += QueueSnapshot;
		Shown += async delegate
		{
			_catalog = await Task.Run(() => new BattleConfigurationCatalog());
			if (!IsDisposed) QueueSnapshot(_tracker.CurrentSnapshot);
		};
	}

	private void SelectView(bool configuration)
	{
		_showConfiguration = configuration;
		_cards.Visible = !configuration;
		_loadout.Visible = configuration;
		_attributes.BackColor = configuration ? Color.FromArgb(240, 241, 244) : Color.FromArgb(0, 122, 255);
		_configuration.BackColor = configuration ? Color.FromArgb(0, 122, 255) : Color.FromArgb(240, 241, 244);
		_attributes.ForeColor = configuration ? Color.DimGray : Color.White;
		_configuration.ForeColor = configuration ? Color.White : Color.DimGray;
	}

	private void QueueSnapshot(AolaBattleSnapshot snapshot)
	{
		if (IsDisposed || !IsHandleCreated) return;
		if (InvokeRequired)
		{
			try { BeginInvoke(new Action<AolaBattleSnapshot>(QueueSnapshot), snapshot); }
			catch (InvalidOperationException) { }
			return;
		}
		_pending = snapshot;
		_refreshTimer.Start();
	}

	private void Render(AolaBattleSnapshot snapshot)
	{
		var pets = snapshot.Sides.Where(side => side.SideName == "敌方").SelectMany(side => side.Pets).ToArray();
		_status.Text = pets.Length == 0 ? "等待敌方资料" : (snapshot.IsEnded ? "战斗已结束" : "战斗中") + "   ·   敌方 " + pets.Length + " 只";
		Point scroll = _cards.AutoScrollPosition;
		_cards.SuspendLayout();
		BattleCardPanel.Clear(_cards);
		foreach (var pet in pets)
		{
			var card = new BattleCardPanel { Width = 180, Height = 610, Margin = new Padding(0, 0, 5, 0) };
			card.Controls.Add(BattleCardPanel.Portrait(pet, new Point(50, 18), new Size(80, 80)));
			var name = new Label { Text = pet.Name, Location = new Point(16, 116), Size = new Size(153, 50), Font = new Font(Font, FontStyle.Bold) };
			card.Controls.Add(name);
			var text = new StringBuilder();
			text.AppendLine("HP   " + (pet.CurrentHp?.ToString() ?? "—") + " / " + (pet.MaximumHp?.ToString() ?? "—"));
			text.AppendLine("等级   " + (pet.Level?.ToString() ?? "—"));
			text.AppendLine("性格   " + (pet.Character ?? "—"));
			text.AppendLine();
			foreach (var ability in pet.Abilities) text.AppendLine(ability.DisplayName + "   " + ability.Total);
			text.AppendLine();
			foreach (var skill in pet.Skills)
			{
				text.AppendLine(skill.Name);
				text.AppendLine("PP " + (skill.PowerPoints ?? "—") + "   CD " + (skill.Cooldown?.ToString() ?? "—"));
				text.AppendLine();
			}
			var details = new Label { Text = text.ToString().TrimEnd(), Font = Font, Location = new Point(16, 174), MaximumSize = new Size(196, 0), AutoSize = true, ForeColor = Color.FromArgb(65, 67, 73) };
			card.Controls.Add(details);
			_cards.Controls.Add(card);
			card.Height = Math.Max(560, details.Bottom + 20);
			if (DeviceDpi != 96) card.Scale(new SizeF(DeviceDpi / 96f, DeviceDpi / 96f));
		}
		_cards.ResumeLayout(true);
		_cards.AutoScrollPosition = new Point(-scroll.X, -scroll.Y);
		_loadout.Render(pets, _catalog);
		SelectView(_showConfiguration);
	}

	protected override void OnFormClosed(FormClosedEventArgs e)
	{
		_tracker.SnapshotChanged -= QueueSnapshot;
		_refreshTimer.Stop();
		_refreshTimer.Dispose();
		BattleCardPanel.Clear(_cards);
		BattleCardPanel.Clear(_loadout);
		base.OnFormClosed(e);
	}
}
