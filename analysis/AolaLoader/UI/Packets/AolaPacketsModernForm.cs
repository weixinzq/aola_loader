using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace AolaLoader.UI.Packets;

internal sealed class CupertinoButton : Button
{
	private bool _hovered;
	private bool _primary;

	public CupertinoButton(string text, bool primary = false)
	{
		Text = text;
		_primary = primary;
		SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.UserPaint, true);
		FlatStyle = FlatStyle.Flat;
		FlatAppearance.BorderSize = 0;
		BackColor = Color.Transparent;
		Cursor = Cursors.Hand;
		Font = new Font("Microsoft YaHei UI", 9.5f, FontStyle.Bold);
		AutoSize = true;
		Height = 40;
		Padding = new Padding(16, 0, 16, 0);
	}

	public bool Primary
	{
		get => _primary;
		set { _primary = value; Invalidate(); }
	}

	protected override void OnMouseEnter(EventArgs e) { _hovered = true; Invalidate(); base.OnMouseEnter(e); }
	protected override void OnMouseLeave(EventArgs e) { _hovered = false; Invalidate(); base.OnMouseLeave(e); }

	protected override void OnPaint(PaintEventArgs e)
	{
		e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
		Rectangle bounds = new Rectangle(0, 0, Width - 1, Height - 1);
		Color fill = !Enabled ? Color.FromArgb(235, 235, 240)
			: Primary ? (_hovered ? Color.FromArgb(0, 105, 225) : Color.FromArgb(0, 122, 255))
			: (_hovered ? Color.FromArgb(226, 226, 232) : Color.FromArgb(242, 242, 247));
		using (GraphicsPath path = RoundedPath(bounds, 10))
		using (SolidBrush brush = new SolidBrush(fill))
		{
			e.Graphics.FillPath(brush, path);
		}
		Color foreground = !Enabled ? Color.FromArgb(150, 150, 155) : Primary ? Color.White : Color.FromArgb(35, 35, 40);
		TextRenderer.DrawText(e.Graphics, Text, Font, bounds, foreground,
			TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
	}

	internal static GraphicsPath RoundedPath(Rectangle bounds, int radius)
	{
		GraphicsPath path = new GraphicsPath();
		int diameter = Math.Max(1, Math.Min(radius * 2, Math.Min(bounds.Width, bounds.Height)));
		Rectangle arc = new Rectangle(bounds.Location, new Size(diameter, diameter));
		path.AddArc(arc, 180, 90);
		arc.X = bounds.Right - diameter;
		path.AddArc(arc, 270, 90);
		arc.Y = bounds.Bottom - diameter;
		path.AddArc(arc, 0, 90);
		arc.X = bounds.Left;
		path.AddArc(arc, 90, 90);
		path.CloseFigure();
		return path;
	}
}

internal sealed class CupertinoCard : Panel
{
	public CupertinoCard()
	{
		SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.UserPaint, true);
		BackColor = Color.White;
	}

	protected override void OnResize(EventArgs eventargs)
	{
		base.OnResize(eventargs);
		if (Width <= 0 || Height <= 0) return;
		using (GraphicsPath path = CupertinoButton.RoundedPath(new Rectangle(0, 0, Width, Height), 14))
		{
			Region previous = Region;
			Region = new Region(path);
			previous?.Dispose();
		}
	}

	protected override void OnPaint(PaintEventArgs e)
	{
		base.OnPaint(e);
		e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
		using (GraphicsPath path = CupertinoButton.RoundedPath(new Rectangle(0, 0, Width - 1, Height - 1), 14))
		using (Pen pen = new Pen(Color.FromArgb(225, 225, 230)))
		{
			e.Graphics.DrawPath(pen, path);
		}
	}
}
