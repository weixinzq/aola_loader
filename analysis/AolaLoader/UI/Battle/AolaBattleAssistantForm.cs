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

    // ==============================
    // 顶部区域
    // ==============================

    var header = new Panel
    {
        Dock = DockStyle.Top,
        Height = 76,
        Padding = new Padding(20),
        BackColor = Color.White
    };

    _status.SetBounds(24, 24, 600, 28);
    _status.Text = "等待敌方资料";
    _status.Font = new Font(
        Font.FontFamily,
        12,
        FontStyle.Bold
    );

    _attributes.Text = "属性";
    _configuration.Text = "配置";

    foreach (Button button in new[]
             {
                 _attributes,
                 _configuration
             })
    {
        button.Size = new Size(86, 34);

        button.FlatStyle = FlatStyle.Flat;
        button.FlatAppearance.BorderSize = 0;

        button.Anchor =
            AnchorStyles.Top |
            AnchorStyles.Right;

        header.Controls.Add(button);
    }

    header.Resize += delegate
    {
        _attributes.Location =
            new Point(
                header.ClientSize.Width - 198,
                20
            );

        _configuration.Location =
            new Point(
                header.ClientSize.Width - 110,
                20
            );

        _status.Width =
            Math.Max(
                100,
                header.ClientSize.Width - 250
            );
    };

    header.Controls.Add(_status);

    // ==============================
    // 宠物卡片区域
    // ==============================

    _cards.Dock = DockStyle.Fill;

    _cards.AutoScroll = true;

    // 不自动换行，始终横向排列
    _cards.WrapContents = false;

    // 左右 Padding 不要太大
    _cards.Padding = new Padding(
        8,
        16,
        8,
        16
    );

    // 如果是 FlowLayoutPanel，建议明确方向
    _cards.FlowDirection =
        FlowDirection.LeftToRight;

    // ==============================
    // 添加控件
    // ==============================

    Controls.Add(_cards);
    Controls.Add(_loadout);
    Controls.Add(header);

    // ==============================
    // 属性 / 配置按钮
    // ==============================

    _attributes.Click += delegate
    {
        SelectView(false);
    };

    _configuration.Click += delegate
    {
        SelectView(true);
    };

    SelectView(false);

    // ==============================
    // 刷新定时器
    // ==============================

    _refreshTimer.Tick += delegate
    {
        _refreshTimer.Stop();

        if (_pending != null &&
            _catalog != null)
        {
            AolaBattleSnapshot snapshot =
                _pending;

            _pending = null;

            Render(snapshot);
        }
    };

    // ==============================
    // 战斗数据
    // ==============================

    _tracker.SnapshotChanged += QueueSnapshot;

    Shown += async delegate
    {
        _catalog = await Task.Run(
            () => new BattleConfigurationCatalog()
        );

        if (!IsDisposed)
        {
            QueueSnapshot(
                _tracker.CurrentSnapshot
            );
        }
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

private void Render(
    AolaBattleSnapshot snapshot)
{
    var pets = snapshot.Sides
        .Where(
            side =>
                side.SideName == "敌方"
        )
        .SelectMany(
            side => side.Pets
        )
        .ToArray();

    // ==============================
    // 顶部状态
    // ==============================

    _status.Text =
        pets.Length == 0
            ? "等待敌方资料"
            : (
                snapshot.IsEnded
                    ? "战斗已结束"
                    : "战斗中"
              )
              + "   ·   敌方 "
              + pets.Length
              + " 只";

    Point scroll =
        _cards.AutoScrollPosition;

    _cards.SuspendLayout();

    BattleCardPanel.Clear(_cards);

    // ==============================
    // 动态计算卡片宽度
    // ==============================

    int cardCount =
        Math.Min(pets.Length, 6);

    const int cardGap = 5;

    int horizontalPadding =
        _cards.Padding.Left +
        _cards.Padding.Right;

    // ClientSize 才是真正的内容区域
    int availableWidth =
        _cards.ClientSize.Width
        - horizontalPadding;

    // 留出一点滚动条和边缘余量
    availableWidth -= 12;

    int cardWidth = 170;

    if (cardCount > 0)
    {
        cardWidth =
            (
                availableWidth
                - cardGap * cardCount
            )
            / cardCount;

        // 防止窗口缩小时卡片太窄
        cardWidth =
            Math.Max(
                145,
                cardWidth
            );

        // 防止窗口很大时卡片过宽
        cardWidth =
            Math.Min(
                180,
                cardWidth
            );
    }

    // ==============================
    // 创建宠物卡
    // ==============================

    foreach (var pet in pets)
    {
        var card =
            new BattleCardPanel
            {
                Width = cardWidth,

                Height = 610,

                Margin =
                    new Padding(
                        0,
                        0,
                        cardGap,
                        0
                    )
            };

        // --------------------------
        // 头像
        // --------------------------

        const int portraitWidth = 80;
        const int portraitHeight = 80;

        // 水平居中
        int portraitX =
            (cardWidth - portraitWidth)
            / 2;

        card.Controls.Add(
            BattleCardPanel.Portrait(
                pet,
                new Point(
                    portraitX,
                    18
                ),
                new Size(
                    portraitWidth,
                    portraitHeight
                )
            )
        );

        // --------------------------
        // 宠物名称
        // --------------------------

        const int contentLeft = 12;
        const int contentRight = 12;

        int contentWidth =
            cardWidth
            - contentLeft
            - contentRight;

        var name =
            new Label
            {
                Text = pet.Name,

                Location =
                    new Point(
                        contentLeft,
                        110
                    ),

                Size =
                    new Size(
                        contentWidth,
                        42
                    ),

                Font =
                    new Font(
                        Font,
                        FontStyle.Bold
                    ),

                TextAlign =
                    ContentAlignment.MiddleCenter
            };

        card.Controls.Add(name);

        // ==============================
        // 构造详情文字
        // ==============================

        var text =
            new StringBuilder();

        text.AppendLine(
            "HP   "
            + (
                pet.CurrentHp?.ToString()
                ?? "—"
              )
            + " / "
            + (
                pet.MaximumHp?.ToString()
                ?? "—"
              )
        );

        text.AppendLine(
            "等级   "
            + (
                pet.Level?.ToString()
                ?? "—"
              )
        );

        text.AppendLine(
            "性格   "
            + (
                pet.Character
                ?? "—"
              )
        );

        // 属性前只留一空行
        text.AppendLine();

        foreach (
            var ability
            in pet.Abilities
        )
        {
            text.AppendLine(
                ability.DisplayName
                + "   "
                + ability.Total
            );
        }

        // 技能区域前留一空行
        text.AppendLine();

        // ==============================
        // 技能
        // ==============================

        for (
            int i = 0;
            i < pet.Skills.Count;
            i++
        )
        {
            var skill =
                pet.Skills[i];

            text.AppendLine(
                skill.Name
            );

            text.AppendLine(
                "PP "
                + (
                    skill.PowerPoints
                    ?? "—"
                  )
                + "   CD "
                + (
                    skill.Cooldown?.ToString()
                    ?? "—"
                  )
            );

            // 不再：
            //
            // text.AppendLine();
            //
            // 所以技能之间不会多一整行
        }

        // ==============================
        // 详情 Label
        // ==============================

        var details =
            new Label
            {
                Text =
                    text
                        .ToString()
                        .TrimEnd(),

                Font = Font,

                Location =
                    new Point(
                        contentLeft,
                        160
                    ),

                MaximumSize =
                    new Size(
                        contentWidth,
                        0
                    ),

                AutoSize = true,

                ForeColor =
                    Color.FromArgb(
                        65,
                        67,
                        73
                    )
            };

        card.Controls.Add(details);

        _cards.Controls.Add(card);

        // 根据内容动态决定卡片高度
        card.Height =
            Math.Max(
                560,
                details.Bottom + 20
            );

        if (DeviceDpi != 96)
        {
            float scale =
                DeviceDpi / 96f;

            card.Scale(
                new SizeF(
                    scale,
                    scale
                )
            );
        }
    }

    _cards.ResumeLayout(true);

    // ==============================
    // 恢复滚动位置
    // ==============================

    _cards.AutoScrollPosition =
        new Point(
            -scroll.X,
            -scroll.Y
        );

    _loadout.Render(
        pets,
        _catalog
    );

    SelectView(
        _showConfiguration
    );
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
