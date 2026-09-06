using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Linq;
using System.Windows.Forms;
using AolaLoader.Features.Battle.Data;
using AolaLoader.Features.Battle.State;

namespace AolaLoader.UI.Battle;

internal sealed class BattleLoadoutView : FlowLayoutPanel
{
	private readonly ToolTip _tips = new ToolTip { AutoPopDelay = 20000, InitialDelay = 350, ReshowDelay = 100 };
	public BattleLoadoutView()
	{
		Dock = DockStyle.Fill;
		AutoScroll = true;
		WrapContents = false;
		FlowDirection = FlowDirection.TopDown;
		Padding = new Padding(16);
	}
	public void Render(AolaBattlePetSnapshot[] pets, BattleConfigurationCatalog catalog)
	{
		Point scroll = AutoScrollPosition;
		SuspendLayout();
		BattleCardPanel.Clear(this);
		int[] widths = AolaBattleLoadoutParser.Categories.Select(category => Math.Max(148, pets.Select(pet => pet.Loadout.TryGetValue(category, out var group) ? group.Items.Count : 0).DefaultIfEmpty(0).Max() * 46 + 24)).ToArray();
		foreach (var pet in pets)
		{
			var row = new BattleCardPanel { Size = new Size(1080, 138), Margin = new Padding(0, 0, 0, 12) };
			row.Controls.Add(BattleCardPanel.Portrait(pet, new Point(16, 20), new Size(64, 64)));
			row.Controls.Add(new Label { Text = pet.Name, Location = new Point(92, 22), Size = new Size(142, 95), AutoEllipsis = true });
			string[] names = { "装备", "魂卡", "魂器", "晶钥" };
			int left = 248;
			for (int i = 0; i < names.Length; i++)
			{
				string category = AolaBattleLoadoutParser.Categories[i];
				pet.Loadout.TryGetValue(category, out var group);
				int count = Math.Max(1, group?.Items.Count ?? 0);
				row.Controls.Add(new Label { Text = names[i], ForeColor = Color.DimGray, Location = new Point(left, 16), Size = new Size(150, 24) });
				for (int index = 0; index < count; index++)
				{
					var item = group != null && index < group.Items.Count ? group.Items[index] : null;
					var picture = new PictureBox { Location = new Point(left + index * 46, 48), Size = new Size(42, 48), SizeMode = PictureBoxSizeMode.Zoom };
					string tip = group == null ? "本包未提供配置" : group.State == BattleConfigurationState.Invalid ? "配置无法解析" : item == null || item.Id <= 0 ? "未配置" : catalog.Describe(category, item.Id);
					if (item?.Id > 0 && category != "soul-artifact" && !string.IsNullOrEmpty(item.Details)) tip += "\n" + item.Details;
					if (item?.Id > 0 && category == "soul-artifact") tip += "\n" + catalog.DescribeActualArtifactEntries(item.Details);
					_tips.SetToolTip(picture, tip);
					row.Controls.Add(picture);
					AolaPetPortraitProvider.Load(picture, category, item?.Id ?? 0, found =>
					{
						if (!found && item?.Id > 0) _tips.SetToolTip(picture, tip + "\n图片缓存缺失或损坏，已记录待补项");
					});
				}
				left += widths[i];
			}
			row.Width = left + 16;
			if (DeviceDpi != 96) row.Scale(new SizeF(DeviceDpi / 96f, DeviceDpi / 96f));
			Controls.Add(row);
		}
		ResumeLayout(true);
		AutoScrollPosition = new Point(-scroll.X, -scroll.Y);
	}
	protected override void Dispose(bool disposing) { if (disposing) _tips.Dispose(); base.Dispose(disposing); }
}

internal sealed class BattleCardPanel : Panel
{
	public BattleCardPanel() { DoubleBuffered = true; BackColor = Color.FromArgb(245, 245, 247); }
	protected override void OnPaint(PaintEventArgs e)
	{
		base.OnPaint(e);
		if (Width < 24 || Height < 24) return;
		using (var path = new GraphicsPath())
		{
			path.AddArc(0, 0, 24, 24, 180, 90);
			path.AddArc(Width - 24, 0, 24, 24, 270, 90);
			path.AddArc(Width - 24, Height - 24, 24, 24, 0, 90);
			path.AddArc(0, Height - 24, 24, 24, 90, 90);
			path.CloseFigure();
			e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
			e.Graphics.FillPath(Brushes.White, path);
		}
	}
	protected override void OnControlAdded(ControlEventArgs e)
	{
		base.OnControlAdded(e);
		e.Control.BackColor = Color.White;
	}
	public static PictureBox Portrait(AolaBattlePetSnapshot pet, Point location, Size size)
	{
		var picture = new PictureBox { Location = location, Size = size, SizeMode = PictureBoxSizeMode.Zoom };
		AolaPetPortraitProvider.Load(picture, "pet", pet.RaceId);
		return picture;
	}
	public static void Clear(Control control)
	{
		foreach (Control child in control.Controls.Cast<Control>().ToArray()) child.Dispose();
		control.Controls.Clear();
	}
	protected override void Dispose(bool disposing)
	{
		if (disposing)
			foreach (PictureBox picture in Controls.OfType<PictureBox>()) { picture.Image?.Dispose(); picture.Image = null; }
		base.Dispose(disposing);
	}
}
