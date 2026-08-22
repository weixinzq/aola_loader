using System;
using System.IO;
using System.Security;
using System.Text;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Settings;

internal sealed class JsonSettingsSectionStore : ISettingsSectionStore
{
	private const int CurrentDocumentVersion = 1;
	private readonly object _syncRoot = new object();
	private readonly string _path;
	private readonly IAtomicSettingsWriter _writer;
	private readonly LegacySettingsMigrator _legacyMigrator;

	public JsonSettingsSectionStore(string path)
		: this(path, new AtomicSettingsWriter(), new LegacySettingsMigrator())
	{
	}

	internal JsonSettingsSectionStore(
		string path,
		IAtomicSettingsWriter writer,
		LegacySettingsMigrator legacyMigrator)
	{
		if (string.IsNullOrWhiteSpace(path))
		{
			throw new ArgumentException("Settings path is required.", nameof(path));
		}
		_path = Path.GetFullPath(path);
		_writer = writer ?? throw new ArgumentNullException(nameof(writer));
		_legacyMigrator = legacyMigrator ?? throw new ArgumentNullException(nameof(legacyMigrator));
	}

	public SettingsSectionLoadResult<T> Load<T>(string key, ISettingsSectionCodec<T> codec)
	{
		if (codec == null)
		{
			throw new ArgumentNullException(nameof(codec));
		}
		if (!IsValidKey(key))
		{
			return DefaultResult(codec, false, "Settings section key is invalid.");
		}

		lock (_syncRoot)
		{
			DocumentReadResult read = ReadDocument();
			if (!read.Succeeded)
			{
				return DefaultResult(codec, false, read.Error);
			}

			JObject sections = (JObject)read.Document["Sections"];
			JToken sectionToken = sections[key];
			if (sectionToken == null)
			{
				return DefaultResult(codec, read.LegacyDocumentMigrated, null);
			}
			if (!(sectionToken is JObject section))
			{
				return DefaultResult(
					codec,
					read.LegacyDocumentMigrated,
					"Settings section '" + key + "' is not an object.");
			}

			try
			{
				T value = codec.DeserializeAndMigrate((JObject)section.DeepClone());
				value = codec.Normalize(value);
				if (read.LegacyDocumentMigrated)
				{
					WriteDocument(read.Document);
				}
				return new SettingsSectionLoadResult<T>(
					value,
					usedDefault: false,
					read.LegacyDocumentMigrated,
					error: null);
			}
			catch (Exception ex) when (IsRecoverable(ex))
			{
				return DefaultResult(codec, read.LegacyDocumentMigrated, ex.Message);
			}
		}
	}

	public SettingsSectionSaveResult Save<T>(string key, T value, ISettingsSectionCodec<T> codec)
	{
		if (codec == null)
		{
			throw new ArgumentNullException(nameof(codec));
		}
		if (!IsValidKey(key))
		{
			return SettingsSectionSaveResult.Failure("Settings section key is invalid.");
		}

		lock (_syncRoot)
		{
			try
			{
				T normalized = codec.Normalize(value);
				JObject replacement = codec.Serialize(normalized);
				if (replacement == null)
				{
					return SettingsSectionSaveResult.Failure("Settings section serializer returned null.");
				}

				DocumentReadResult read = ReadDocument();
				if (!read.Succeeded)
				{
					return SettingsSectionSaveResult.Failure(read.Error);
				}

				JObject sections = (JObject)read.Document["Sections"];
				JObject merged = sections[key] is JObject existing
					? (JObject)existing.DeepClone()
					: new JObject();
				merged.Merge(
					replacement,
					new JsonMergeSettings
					{
						MergeArrayHandling = MergeArrayHandling.Replace,
						MergeNullValueHandling = MergeNullValueHandling.Merge
					});
				sections[key] = merged;
				WriteDocument(read.Document);
				return SettingsSectionSaveResult.Success(read.LegacyDocumentMigrated);
			}
			catch (Exception ex) when (IsRecoverable(ex))
			{
				return SettingsSectionSaveResult.Failure(ex.Message);
			}
		}
	}

	private DocumentReadResult ReadDocument()
	{
		if (!File.Exists(_path))
		{
			return DocumentReadResult.Success(CreateEmptyDocument(), legacyDocumentMigrated: false);
		}

		try
		{
			JObject document = JObject.Parse(File.ReadAllText(_path, Encoding.UTF8));
			if (IsCurrentDocument(document))
			{
				return DocumentReadResult.Success(document, legacyDocumentMigrated: false);
			}

			if (!_legacyMigrator.TryMigrate(document, out JObject migrated, out string migrationError))
			{
				return DocumentReadResult.Failure(migrationError);
			}
			return DocumentReadResult.Success(migrated, legacyDocumentMigrated: true);
		}
		catch (Exception ex) when (IsRecoverable(ex))
		{
			return DocumentReadResult.Failure(ex.Message);
		}
	}

	private void WriteDocument(JObject document)
	{
		string content = JsonConvert.SerializeObject(document, Formatting.Indented);
		_writer.WriteAllText(_path, content);
	}

	private static JObject CreateEmptyDocument()
	{
		return new JObject
		{
			["DocumentVersion"] = CurrentDocumentVersion,
			["Sections"] = new JObject()
		};
	}

	private static bool IsCurrentDocument(JObject document)
	{
		JToken version = document["DocumentVersion"];
		return version != null &&
			version.Type == JTokenType.Integer &&
			version.Value<int>() == CurrentDocumentVersion &&
			document["Sections"] is JObject;
	}

	private static SettingsSectionLoadResult<T> DefaultResult<T>(
		ISettingsSectionCodec<T> codec,
		bool legacyDocumentMigrated,
		string error)
	{
		T value = codec.Normalize(codec.CreateDefault());
		return new SettingsSectionLoadResult<T>(
			value,
			usedDefault: true,
			legacyDocumentMigrated,
			error);
	}

	private static bool IsValidKey(string key)
	{
		if (string.IsNullOrWhiteSpace(key) || key.Length > 64 || !char.IsLower(key[0]))
		{
			return false;
		}
		for (int index = 1; index < key.Length; index++)
		{
			if (!char.IsLetterOrDigit(key[index]))
			{
				return false;
			}
		}
		return true;
	}

	private static bool IsRecoverable(Exception ex)
	{
		return ex is IOException ||
			ex is UnauthorizedAccessException ||
			ex is SecurityException ||
			ex is JsonException ||
			ex is ArgumentException ||
			ex is InvalidOperationException ||
			ex is NotSupportedException;
	}

	private sealed class DocumentReadResult
	{
		private DocumentReadResult(
			bool succeeded,
			JObject document,
			bool legacyDocumentMigrated,
			string error)
		{
			Succeeded = succeeded;
			Document = document;
			LegacyDocumentMigrated = legacyDocumentMigrated;
			Error = error;
		}

		public bool Succeeded { get; }

		public JObject Document { get; }

		public bool LegacyDocumentMigrated { get; }

		public string Error { get; }

		public static DocumentReadResult Success(JObject document, bool legacyDocumentMigrated)
		{
			return new DocumentReadResult(true, document, legacyDocumentMigrated, null);
		}

		public static DocumentReadResult Failure(string error)
		{
			return new DocumentReadResult(false, null, false, error);
		}
	}
}
