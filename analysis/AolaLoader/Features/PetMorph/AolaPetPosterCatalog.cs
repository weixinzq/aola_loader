// 架构角色：读取宠物海报目录并提供 petId 到资源标识的只读查询。
// 数据流：catalog JSON -> 规范化条目 -> PetPosterResourceRule。
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;

namespace AolaLoader.Features.PetMorph;

internal sealed class AolaPetPosterCatalog
{
	private readonly Dictionary<int, AolaPetPosterCatalogEntry> _bySkinId;
	private readonly Dictionary<int, AolaPetPosterCatalogEntry> _byResourceId;

	private AolaPetPosterCatalog(
		IReadOnlyList<AolaPetPosterCatalogEntry> entries,
		string source,
		string sourceSha256,
		string error)
	{
		Entries = entries ?? Array.Empty<AolaPetPosterCatalogEntry>();
		Source = source ?? string.Empty;
		SourceSha256 = sourceSha256 ?? string.Empty;
		Error = error;
		_bySkinId = Entries.ToDictionary(entry => entry.SkinId);
		_byResourceId = Entries.ToDictionary(entry => entry.ResourceId);
	}

	public IReadOnlyList<AolaPetPosterCatalogEntry> Entries { get; }

	public string Source { get; }

	public string SourceSha256 { get; }

	public string Error { get; }

	public bool IsAvailable => Error == null && Entries.Count > 0;

	public bool TryGetBySkinId(int skinId, out AolaPetPosterCatalogEntry entry)
	{
		return _bySkinId.TryGetValue(skinId, out entry);
	}

	public bool TryGetByResourceId(int resourceId, out AolaPetPosterCatalogEntry entry)
	{
		return _byResourceId.TryGetValue(resourceId, out entry);
	}

	public static AolaPetPosterCatalog Load(string path)
	{
		try
		{
			if (!File.Exists(path))
			{
				return Empty("找不到海报映射目录：" + path);
			}
			AolaPetPosterCatalogDocument document = JsonConvert.DeserializeObject<AolaPetPosterCatalogDocument>(
				File.ReadAllText(path));
			if (document == null || document.SchemaVersion != 1 || document.Entries == null)
			{
				return Empty("海报映射目录版本或内容无效。 ");
			}
			List<AolaPetPosterCatalogEntry> entries = document.Entries
				.Where(entry => entry != null && entry.SkinId > 0 && entry.ResourceId > 0 && entry.HasBackground)
				.ToList();
			if (entries.Count == 0 || entries.Count != entries.Select(entry => entry.SkinId).Distinct().Count() ||
				entries.Count != entries.Select(entry => entry.ResourceId).Distinct().Count())
			{
				return Empty("海报映射目录包含空目录或重复 ID。 ");
			}
			return new AolaPetPosterCatalog(entries, document.Source, document.SourceSha256, null);
		}
		catch (Exception ex) when (ex is IOException || ex is UnauthorizedAccessException ||
			ex is JsonException || ex is ArgumentException || ex is InvalidOperationException)
		{
			return Empty("读取海报映射目录失败：" + ex.Message);
		}
	}

	private static AolaPetPosterCatalog Empty(string error)
	{
		return new AolaPetPosterCatalog(Array.Empty<AolaPetPosterCatalogEntry>(), string.Empty, string.Empty, error);
	}

	private sealed class AolaPetPosterCatalogDocument
	{
		public int SchemaVersion { get; set; }

		public string Source { get; set; }

		public string SourceSha256 { get; set; }

		public List<AolaPetPosterCatalogEntry> Entries { get; set; }
	}
}

internal sealed class AolaPetPosterCatalogEntry
{
	public int SkinId { get; set; }

	public int ResourceId { get; set; }

	public string Name { get; set; }

	public bool HasBackground { get; set; }

	public bool ShowPet { get; set; }
}
