# Testing Local SWIG Wrapper Changes in a Consuming Unity Project

This guide explains how to test **locally-generated** changes to the SWIG C# wrapper
(`csp-unity`) inside a Unity project that **already consumes the released
`com.magnopus.csp.unity` package** (via git URL, npm, or tarball).

It exists because dropping generated files into a consuming project is not as simple as
"copy the new `.cs` files over the old ones" — doing that naively produces a cascade of
confusing compiler errors. The sections below cover the build, the install, and — most
importantly — the Unity packaging rules that make or break the swap.

> **TL;DR**
> 1. Rebuild + install the wrapper (`cmake --build` **then** `cmake --install`).
> 2. Embed the release package into `Packages/` as a **complete, valid package**
>    (keep `package.json`, both `.asmdef`s, all `.meta`s).
> 3. Overlay the **entire** regenerated C# set **and** the matching native library —
>    they are one matched unit, never mix builds.
> 4. Add a `csc.rsp` next to each asmdef to suppress the generated code's benign
>    warnings, because an embedded package is *mutable* and your project's
>    `-warnaserror+` now applies to it.

---

## Background: why this is fiddly

A consuming project normally pulls CSP as an **immutable** package (resolved into
`Library/PackageCache` from a git/npm/tarball source). Two Unity behaviors that hold for
immutable packages stop holding the moment you embed a local copy under `Packages/`:

| Behavior | Immutable package (release) | Embedded package (`Packages/<name>/`) |
|---|---|---|
| Compiler **warnings** | **Suppressed** by Unity (you can't edit it) | **Shown** (it's mutable/editable) |
| Project `Assets/csc.rsp` (e.g. `-warnaserror+`) | Not enforced | **Enforced** on the package's assemblies |
| Editable | No | Yes |

The generated SWIG bindings have always contained **benign warnings** (member hiding,
nullable-reference annotations, etc.). They're invisible in the release because warnings
are suppressed. Embed the same code and those warnings appear — and if your project uses
`-warnaserror+`, every one becomes a hard **error**.

On top of that, the generated C# is split across many files that must stay in lockstep
with the native library. Cherry-picking a couple of files breaks that contract.

---

## Part 1 — Build & regenerate the wrapper

From the `csp-unity` root, run the standard configure/build/install triplet. The install
step is the one that actually copies artifacts into the test Unity project.

```bash
cmake -S . -B build -DENABLE_UNITY_EXTENSIONS=ON
cmake --build   build --config Debug
cmake --install build --config Debug
```

Notes:

- **`--build` alone does not copy anything into Unity.** It only produces
  `build/Debug/…DotNet.dll` and `build/generated/cs/…`. The copy into the Unity test
  project is an `install(CODE …)` step (see `cmake/InstallToUnityProject.cmake`), which
  runs only during **`cmake --install`**. Always run both.
- This produces **desktop (host-platform) native libraries only**. iOS/Android device
  builds need their own toolchain runs — see [Platform caveats](#platform-caveats).

### Where the build outputs land

After `cmake --install`, the freshly generated artifacts are in the csp-unity **test**
project (paths are relative to the csp-unity root):

- Generated C# (full set): `UnityProject/CspUnityTests/Assets/Plugins/include/`
  - `ConnectedSpacesPlatformDotNetPINVOKE.cs` (the central `[DllImport]` table)
  - `ConnectedSpacesPlatformDotNet.cs`, all `*CallbackAdapter.cs`, `SWIGTYPE_*.cs`
  - `csp/` (namespaced classes, e.g. `csp/systems/GLTFMaterial.cs`)
  - `Exceptions/`, `extra/`
  - `ConnectedSpacesPlatform.Unity.Core.asmdef`
- Native libs (Windows example): `UnityProject/CspUnityTests/Assets/Plugins/windows/`
  - `ConnectedSpacesPlatformDotNet.dll` — the SWIG wrapper (freshly built)
  - `ConnectedSpacesPlatform.dll` — the CSP core it links against
  - `ConnectedSpacesPlatformDotNet.lib` — link-time import lib, **not** needed at runtime

---

## Part 2 — Embed the package in the consuming project

Let `PKG = <ConsumingProject>/Packages/com.magnopus.csp.unity`.

### 2a. Start from a *complete, valid* package (do not hand-build the folder)

A folder placed at `Packages/<name>/` **overrides** the manifest dependency of the same
name and becomes an embedded package. Your `manifest.json` does **not** need editing — the
folder override is what Unity keys on (`packages-lock.json` will report
`"source": "embedded"`).

But the folder must be a *valid, complete* package. If it's missing `package.json` or the
`.asmdef`s, the generated `.cs` fall into the predefined `Assembly-CSharp`, which **does**
read `Assets/csc.rsp` — instantly turning every generated-code warning into an error.

The reliable way to get a complete skeleton is to copy the **entire released package out
of the cache**, then overlay your build on top:

```bash
# Find the resolved release package (immutable copy) in any project that still uses it:
#   <SomeProject>/Library/PackageCache/com.magnopus.csp.unity@<hash>/
# Copy the whole thing into Packages/:
cp -r "<SomeProject>/Library/PackageCache/com.magnopus.csp.unity/." \
      "$PKG/"
```
**Note** that you want to remove the hash postfix from the package name.

This gives you the required, GUID-stable pieces you must **keep**:

- `package.json` (+ `.meta`), `package-dist.json` (+ `.meta`)
- `Runtime/ConnectedSpacesPlatform.Unity.Core.asmdef` (+ `.meta`)
- `Editor/ConnectedSpacesPlatform.Editor.asmdef` (+ `.meta`) and its editor scripts
  (`CSPLibraryDownloader.cs`, `NativePluginBuildProcessor.cs`, …)
- The `Plugins/` folder and structure

> The `.meta` GUID on `ConnectedSpacesPlatform.Unity.Core.asmdef` is referenced by other
> assemblies (e.g. the Foundation package). **Never overwrite the asmdef `.meta`** — keep
> the release one.

### 2b. Overlay the *entire* regenerated C# set

Replace **all** generated code, preserving the asmdef + its meta:

```bash
S="<csp-unity>/UnityProject/CspUnityTests/Assets/Plugins/include"

# 1) Clear the stale generated code in Runtime, but KEEP the asmdef + its .meta
cd "$PKG/Runtime"
find . -mindepth 1 -maxdepth 1 \
  ! -name 'ConnectedSpacesPlatform.Unity.Core.asmdef' \
  ! -name 'ConnectedSpacesPlatform.Unity.Core.asmdef.meta' \
  -exec rm -rf {} +

# 2) Copy in the full fresh set (the source has no .meta files, so the kept asmdef.meta
#    is untouched; Unity regenerates .cs metas on import)
cp -r "$S/." "$PKG/Runtime/"
```

### 2c. Overlay the matching native library

Use the native lib **from the same build** as the C# above. For **Windows Editor testing**:

```bash
W="<csp-unity>/UnityProject/CspUnityTests/Assets/Plugins/windows"
cp "$W/ConnectedSpacesPlatformDotNet.dll" "$PKG/Plugins/"   # the SWIG wrapper
cp "$W/ConnectedSpacesPlatform.dll"       "$PKG/Plugins/"   # the CSP core it P/Invokes
# (do NOT copy the .lib — it's link-time only)
```

> ⚠️ **Never mix builds.** Release C# + your DLL, or your C# + release DLL, will fail
> (missing entry points or ABI mismatch). The generated C# and the native library must
> come from one build.

---

## Part 3 — Silence the generated code's warnings (the `-warnaserror+` trap)

Once embedded, the package is **mutable**, so your project's `Assets/csc.rsp` (commonly
`-warnaserror+`) is enforced on the CSP assemblies. The generated bindings emit benign
warnings that were previously suppressed by immutability. You'll see errors such as:

- `CS0108` — a generated member hides an inherited one
- `CS8600 / 8603 / 8604 / 8618 / 8625 / 8669` — nullable-reference warnings

Replicate what immutability gave you for free by suppressing those IDs **per assembly**.
A `csc.rsp` placed next to an `.asmdef` is Unity's documented per-assembly compiler-option
mechanism, and `-nowarn` removes the diagnostics entirely, so `-warnaserror+` has nothing
left to promote (regardless of response-file merge order).

Create these two files:

`$PKG/Runtime/csc.rsp`
```
-nowarn:0108,8600,8603,8604,8618,8625,8669
```

`$PKG/Editor/csc.rsp`
```
-nowarn:0108,8600,8603,8604,8618,8625,8669
```

If a warning code you don't see here appears after recompiling, add it to both files.

> To discover the exact set your build produces, read the Unity Editor log after a failed
> compile:
> ```bash
> grep -oE 'error CS[0-9]+' "$LOCALAPPDATA/Unity/Editor/Editor.log" | sort -u
> ```
> (Ignore `CS0117` — that's the matched-pair error from Part 2b, not a warning.)

---

## Part 4 — Recompile & verify in Unity

1. Focus the Unity Editor (or right-click the package in the Project window → **Reimport**)
   to trigger recompilation and `.meta` regeneration.
2. It should compile cleanly. The CSP code lives in its own asmdef assembly with the
   `-nowarn` suppression, and your consuming code (e.g. `AssetCollectionApi.cs`) compiles
   against the new bindings.
3. If you hit a runtime `DllNotFoundException`: select the native DLL in the Project window
   → Inspector → ensure **Editor** and your standalone platform (e.g. **Windows x86_64**)
   are checked in the plugin import settings.
4. Exercise the changed code path (play mode / a test) to confirm the behavior, not just
   that it compiles.

---

## Platform caveats

- The desktop build produces **host-platform** native libraries only. Testing works in the
  **Editor** on that host. An actual **iOS/Android device build** requires building
  csp-unity with the corresponding toolchain (see `BUILD.md` and the platform workflow
  files) and placing those platform libraries under `Plugins/` with correct import settings.
- The released package's editor script (`CSPLibraryDownloader.cs`) normally fetches native
  libs at import/build time. When you hand-place libs in `Plugins/`, make sure they aren't
  overwritten/removed by that downloader for the platform you're testing.

---

## Reverting

Because the embedded folder only *shadows* the manifest dependency, cleanup is simply:

```bash
rm -rf "<ConsumingProject>/Packages/com.magnopus.csp.unity"
```

Unity re-resolves the released package from `manifest.json` on the next focus/refresh. Your
`manifest.json` was never modified.

---

## Quick checklist

- [ ] `cmake --build` **and** `cmake --install` both run (Debug)
- [ ] New symbol present in **both** the built DLL and the generated PINVOKE `.cs`
- [ ] `Packages/com.magnopus.csp.unity/` is a **complete** package (package.json + both asmdefs + metas)
- [ ] **Entire** generated C# set copied (not just changed files); asmdef `.meta` preserved
- [ ] Matching native lib(s) copied from the **same build**; `.lib` excluded
- [ ] `Runtime/csc.rsp` **and** `Editor/csc.rsp` added with `-nowarn:…`
- [ ] Recompiled in Unity; behavior verified in play mode / tests
