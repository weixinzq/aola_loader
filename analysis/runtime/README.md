# Pinned runtime files

The repository includes the x64 PPAPI Flash library currently used by
`AolaLoader` at:

```text
analysis/runtime/pepflashplayer.dll
```

The build copies it to `runtime/pepflashplayer.dll` beside the executable.

Pinned file evidence:

```text
Size: 16089056 bytes
SHA-256: 5C11EB05346F7D5B5CF8D01B7ED0B6FA540260A173B45BE3546A87DE1E230917
Authenticode: HashMismatch
Signer subject: Adobe Inc.
```

The Authenticode signature does not validate against the current bytes. Treat
this legacy binary as untrusted, do not replace it casually, and only use or
redistribute it where you have permission to do so.

EasyHook 2.7.7097, including its managed and native runtime components, is
restored from NuGet by the projects. Do not add local EasyHook binaries here.
