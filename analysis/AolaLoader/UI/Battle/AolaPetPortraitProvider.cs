// 架构角色：战斗 UI 的宠物头像资源提供器，负责路径解析、缓存与缺失回退。
// 数据流：petId/resource catalog -> Image；不参与战斗状态解析。
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Forms;
using AolaLoader.Features.Battle.State;

namespace AolaLoader.UI.Battle;

internal interface IAolaPetPortraitProvider
{
	Image CreatePortrait(AolaBattlePetSnapshot pet, Size size);
}

internal sealed class AolaPetPortraitProvider : IAolaPetPortraitProvider
{
	private static readonly HashSet<string> Missing = new HashSet<string>();
	public Image CreatePortrait(AolaBattlePetSnapshot pet, Size size) => ReadImage("pet", pet?.RaceId ?? 0, size, out _);

	public static async void Load(PictureBox picture, string category, int id, Action<bool> completed = null)
	{
		Size size = picture.Size;
		var result = await Task.Run(() => { Image bitmap = ReadImage(category, id, size, out bool found); return Tuple.Create(bitmap, found); });
		Image image = result.Item1;
		if (picture.IsDisposed) { image.Dispose(); return; }
		Image previous = picture.Image;
		picture.Image = image;
		previous?.Dispose();
		completed?.Invoke(result.Item2);
	}

	private static Image ReadImage(string category, int id, Size size, out bool found)
	{
		found = false;
		string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Resources", "BattleAssistant", category, id + ".png");
		if (id > 0)
		{
			try { using (var input = Image.FromFile(path)) { var loadedBitmap = new Bitmap(input); found = true; return loadedBitmap; } }
			catch (IOException) { }
			catch (UnauthorizedAccessException) { }
			catch (ArgumentException) { }
			catch (OutOfMemoryException) { }
			lock (Missing)
			{
				if (Missing.Add(category + ":" + id))
				{
					try
					{
						string directory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AolaLoader");
						Directory.CreateDirectory(directory);
						File.AppendAllText(Path.Combine(directory, "battle-assets-missing.txt"), category + ":" + id + Environment.NewLine);
					}
					catch (IOException) { }
					catch (UnauthorizedAccessException) { }
				}
			}
		}
		var bitmap = new Bitmap(Math.Max(1, size.Width), Math.Max(1, size.Height));
		using (Graphics graphics = Graphics.FromImage(bitmap))
		using (var brush = new SolidBrush(Color.FromArgb(182, 187, 195)))
		using (var font = new Font("Microsoft YaHei UI", 9))
		using (var format = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center })
		{
			graphics.Clear(Color.FromArgb(242, 243, 246));
			graphics.DrawString(id > 0 ? "待补图" : "—", font, brush, new RectangleF(0, 0, bitmap.Width, bitmap.Height), format);
		}
		return bitmap;
	}
}
