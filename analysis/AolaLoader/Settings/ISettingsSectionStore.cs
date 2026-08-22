using System;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Settings;

internal interface ISettingsSectionStore
{
	SettingsSectionLoadResult<T> Load<T>(string key, ISettingsSectionCodec<T> codec);

	SettingsSectionSaveResult Save<T>(string key, T value, ISettingsSectionCodec<T> codec);
}

/// <summary>
/// Module-owned conversion, version migration, and normalization for one section.
/// </summary>
internal interface ISettingsSectionCodec<T>
{
	T CreateDefault();

	T DeserializeAndMigrate(JObject section);

	T Normalize(T value);

	JObject Serialize(T value);
}

internal sealed class SettingsSectionLoadResult<T>
{
	public SettingsSectionLoadResult(T value, bool usedDefault, bool legacyDocumentMigrated, string error)
	{
		Value = value;
		UsedDefault = usedDefault;
		LegacyDocumentMigrated = legacyDocumentMigrated;
		Error = error;
	}

	public T Value { get; }

	public bool UsedDefault { get; }

	public bool LegacyDocumentMigrated { get; }

	public string Error { get; }
}

internal sealed class SettingsSectionSaveResult
{
	private SettingsSectionSaveResult(bool succeeded, bool legacyDocumentMigrated, string error)
	{
		Succeeded = succeeded;
		LegacyDocumentMigrated = legacyDocumentMigrated;
		Error = error;
	}

	public bool Succeeded { get; }

	public bool LegacyDocumentMigrated { get; }

	public string Error { get; }

	public static SettingsSectionSaveResult Success(bool legacyDocumentMigrated)
	{
		return new SettingsSectionSaveResult(true, legacyDocumentMigrated, null);
	}

	public static SettingsSectionSaveResult Failure(string error)
	{
		return new SettingsSectionSaveResult(false, false, error);
	}
}

