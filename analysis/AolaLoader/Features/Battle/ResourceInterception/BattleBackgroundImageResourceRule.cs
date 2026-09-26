using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.Features.Battle.ResourceInterception;

internal sealed class BattleBackgroundImageResourceRule : IResourceInterceptionRule
{
	internal const string ResourcePath = "/play/petfightbackground/aola-custom.jpg";
	private const int Width = 960;
	private const int Height = 560;
	private readonly string _imagePath;

	public BattleBackgroundImageResourceRule(string imagePath)
	{
		_imagePath = imagePath ?? throw new ArgumentNullException(nameof(imagePath));
	}

	public string Name => "battle.background.image";

	public int Priority => 860;

	public string PathOwnership => "aola.100bt.com:" + ResourcePath;

	public ResourceInterceptionPlan Evaluate(ResourceRequestContext request)
	{
		if (request == null) throw new ArgumentNullException(nameof(request));
		if (request.Method != "GET" ||
			!string.Equals(request.Host, "aola.100bt.com", StringComparison.OrdinalIgnoreCase) ||
			!string.Equals(request.Path, ResourcePath, StringComparison.Ordinal) ||
			!File.Exists(_imagePath))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		try
		{
			using (Image source = Image.FromFile(_imagePath))
			using (Bitmap canvas = new Bitmap(Width, Height, PixelFormat.Format24bppRgb))
			using (Graphics graphics = Graphics.FromImage(canvas))
			using (MemoryStream output = new MemoryStream())
			{
				float scale = Math.Max((float)Width / source.Width, (float)Height / source.Height);
				float imageWidth = source.Width * scale;
				float imageHeight = source.Height * scale;
				graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
				graphics.DrawImage(source,
					new RectangleF((Width - imageWidth) / 2, (Height - imageHeight) / 2,
						imageWidth, imageHeight));
				canvas.Save(output, ImageFormat.Jpeg);
				return ResourceInterceptionPlan.LocalResponse(
					request.OriginalUrl,
					output.ToArray(),
					"image/jpeg",
					"battle.background.image",
					"battle.background.image");
			}
		}
		catch (Exception)
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}
	}
}
