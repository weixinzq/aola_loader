# Local runtime files

The source tree builds without checked-in runtime binaries. To run `AolaLoader`,
place the compatible x64 PPAPI Flash library at:

```text
analysis/runtime/pepflashplayer.dll
```

The build copies it to `runtime/pepflashplayer.dll` beside the executable. The
file is intentionally excluded from Git and is not downloaded automatically;
only use a copy that you are licensed to use and trust.

EasyHook 2.7.7097, including its managed and native runtime components, is
restored from NuGet by the projects. Do not add local EasyHook binaries here.
