using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Text;
using AolaLoader.Features.Battle.State;

namespace AolaLoader.UI.Battle;

internal interface IAolaPetPortraitProvider
{
	Image CreatePortrait(AolaBattlePetSnapshot pet, Size size);
}

internal sealed class AolaPetPortraitProvider : IAolaPetPortraitProvider
{
	public Image CreatePortrait(AolaBattlePetSnapshot pet, Size size)
	{
		int width = Math.Max(1, size.Width);
		int height = Math.Max(1, size.Height);
		Bitmap bitmap = new Bitmap(width, height);
		int seed = pet?.ViewId ?? 0;
		Color start = ColorFromSeed(seed, 0.78f, 0.94f);
		Color end = ColorFromSeed(seed + 97, 0.52f, 0.78f);
		using (Graphics graphics = Graphics.FromImage(bitmap))
		using (LinearGradientBrush background = new LinearGradientBrush(
			new Rectangle(0, 0, width, height), start, end, LinearGradientMode.ForwardDiagonal))
		using (SolidBrush circle = new SolidBrush(Color.FromArgb(170, Color.White)))
		using (Pen border = new Pen(Color.FromArgb(95, Color.White), 2f))
		using (Font initialFont = new Font("Microsoft YaHei UI", Math.Max(22f, height * 0.34f), FontStyle.Bold, GraphicsUnit.Pixel))
		using (Font idFont = new Font("Microsoft YaHei UI", 10f, FontStyle.Regular, GraphicsUnit.Pixel))
		{
			graphics.SmoothingMode = SmoothingMode.AntiAlias;
			graphics.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;
			graphics.FillRectangle(background, 0, 0, width, height);
			int circleSize = Math.Min(width, height) - 24;
			Rectangle circleBounds = new Rectangle((width - circleSize) / 2, 8, circleSize, circleSize);
			graphics.FillEllipse(circle, circleBounds);
			graphics.DrawEllipse(border, circleBounds);

			string initial = string.IsNullOrWhiteSpace(pet?.Name) ? "亚" : pet.Name.Substring(0, 1);
			StringFormat center = new StringFormat
			{
				Alignment = StringAlignment.Center,
				LineAlignment = StringAlignment.Center
			};
			using (SolidBrush textBrush = new SolidBrush(Color.FromArgb(55, 65, 85)))
			{
				graphics.DrawString(initial, initialFont, textBrush, circleBounds, center);
			}
			string idText = pet == null || pet.ViewId <= 0 ? "头像暂缺" : "View " + pet.ViewId;
			RectangleF idBounds = new RectangleF(4, height - 18, width - 8, 16);
			using (SolidBrush idBrush = new SolidBrush(Color.FromArgb(225, Color.White)))
			{
				graphics.DrawString(idText, idFont, idBrush, idBounds, center);
			}
			center.Dispose();
		}
		return bitmap;
	}

	private static Color ColorFromSeed(int seed, float saturation, float brightness)
	{
		double hue = Math.Abs(seed * 47 % 360) / 60d;
		int sector = (int)Math.Floor(hue) % 6;
		double fraction = hue - Math.Floor(hue);
		double p = brightness * (1 - saturation);
		double q = brightness * (1 - saturation * fraction);
		double t = brightness * (1 - saturation * (1 - fraction));
		double r;
		double g;
		double b;
		switch (sector)
		{
			case 0: r = brightness; g = t; b = p; break;
			case 1: r = q; g = brightness; b = p; break;
			case 2: r = p; g = brightness; b = t; break;
			case 3: r = p; g = q; b = brightness; break;
			case 4: r = t; g = p; b = brightness; break;
			default: r = brightness; g = p; b = q; break;
		}
		return Color.FromArgb((int)(r * 255), (int)(g * 255), (int)(b * 255));
	}
}
