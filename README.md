# reshade-steam

> Install [ReShade](https://reshade.me/) and shader repositories for any Windows game running under Wine or Proton on Linux — with automatic Steam game detection, per-game shader selection, and a graphical or terminal UI.

> [!NOTE]
> This is an independent continuation of [kevinlekiller/reshade-steam-proton](https://github.com/kevinlekiller/reshade-steam-proton). All original work and credit belongs to [kevinlekiller](https://github.com/kevinlekiller). This fork modernises the codebase, fixes active bugs, and adds substantial new features.

See [CHANGELOG.md](CHANGELOG.md) for release history.

---

## Quick start

### AppImage (recommended)

Download the latest AppImage from the [Releases](https://github.com/asafelobotomy/reshade-steam/releases) page:

```bash
chmod +x reshade-linux-*-x86_64.AppImage
./reshade-linux-*-x86_64.AppImage
```

The AppImage bundles everything — no dependencies to install.

### Run from source

Requirements: `grep`, `7z`, `curl`, `git`, `file`, `python3`, `sed`, and `sha256sum`.

```bash
git clone https://github.com/asafelobotomy/reshade-steam.git
cd reshade-steam
./reshade-linux.sh
```

> [!TIP]
> Install `yad` for a graphical interface on Linux desktops. If `yad` is unavailable, the script uses `whiptail` or `dialog` for a terminal UI, then falls back to plain CLI prompts.
>
> To force a backend manually, set `UI_BACKEND` to `auto`, `yad`, `whiptail`, `dialog`, or `cli`.

---

## Features

### Game detection

| | |
| --- | --- |
| **Steam library scan** | Finds all Steam library folders automatically; no manual path entry needed. |
| **`appinfo.vdf` parsing** | Reads Steam's binary metadata to identify the exact launch executable for every game. |
| **PE import table analysis** | Inspects the Windows PE import table to pick the correct DLL override (`dxgi`, `d3d9`, `opengl32`, `ddraw`, `dinput8`, …) instead of blindly defaulting to `dxgi`. |
| **Built-in directory presets** | Knows where the real executable lives for games with non-root layouts (Cyberpunk 2077, Witcher 3, Oblivion Remastered, ESO, and more). |
| **Custom directory presets** | Override any game's exe directory via `GAME_DIR_PRESETS="<AppID>\|<subdir>"`. |

### Install, update & uninstall

| | |
| --- | --- |
| **Installed-game indicator** | Game picker marks already-configured games with ✔ so repeat runs are immediately obvious. |
| **Per-game state** | Installation settings (DLL, architecture, shader selection) are saved per game in `~/.local/share/reshade/game-state/`. Re-running a game skips the DLL dialog and reuses stored settings. |
| **Per-game shader selection** | Choose which shader repositories to install for each game. Unticking a repo removes its shaders from that game only. |
| **Shared shader headers** | Core `.fxh` include files (e.g. `ReShade.fxh`, `ReShadeUI.fxh`) are always linked from all installed repos, even when their parent repo is deselected, so shaders compile correctly. |
| **Per-game config** | Every install gets its own `ReShade.ini` and `ReShade_shaders/` link; no shared global config. |
| **Update all** | Re-link ReShade and shaders for every tracked game at once — available from the main dialog or via `--update-all` on the command line. |
| **Wineprefix auto-detection** | Finds the correct Wine prefix from `compatdata/` automatically; installs `d3dcompiler_47.dll` into the prefix for ReShade 6.5+. |
| **Steam launch option output** | Prints the required `WINEDLLOVERRIDES` launch option and copies it to the clipboard when supported. |

### Flatpak & interface

| | |
| --- | --- |
| **Flatpak auto-detection** | Detects native vs. Flatpak Steam and sets `MAIN_PATH` accordingly; prompts if both are found. |
| **Graphical UI** | Uses `yad` automatically on graphical sessions for folder pickers, lists, prompts, and progress windows. |
| **Terminal UI** | Falls back to `whiptail`, then `dialog`, then plain CLI prompts. |

### Shader repositories

18 curated repos are included by default, covering anti-aliasing, ambient occlusion, depth of field, colour grading, LUTs, and more: SweetFX, iMMERSE, AstrayFX, prod80, reshade-shaders (official), fubax-shaders, OtisFX, qUINT, Insane-Shaders, NiceGuy-Shaders, daodan-shaders, Glamarye, FXShaders, CobraFX, CorgiFX, MLUT, dh-reshade-shaders, and lordbean-shaders.

The checklist shows human-readable descriptions for each repo and adapts to terminal height.

### Code quality vs. upstream

| | |
| --- | --- |
| **Security** | Removed unsafe `eval`; tilde expansion handled with `${var/#\~/$HOME}`; `curl --fail` throughout. |
| **Correctness** | `ls` replaced with `[[ -d ]]`/`compgen -G`; indirect `$?` checks eliminated (ShellCheck SC2181). |
| **Performance** | Shader repo loop rewritten to remove 4+ subshells per iteration; pure-Bash path construction. |
| **D3D compiler** | `downloadD3dcompiler_47()` uses [mozilla/fxc2](https://github.com/mozilla/fxc2) (same source as Winetricks) with sha256 verification instead of a 50 MB Firefox installer. |
| **ShellCheck** | Entry scripts and all sourced libraries pass ShellCheck cleanly. |

---

## Update all installed games

Re-link ReShade and shaders for every previously installed game at once:

**From the dialog**: Select "Update all installed games" in the install/uninstall menu (shown when at least one game is already installed).

**From the command line**:

```bash
./reshade-linux.sh --update-all
```

State files in `~/.local/share/reshade/game-state/` record the DLL, architecture, game path, and selected shader repos for each game. The update rebuilds each game's `ReShade_shaders/` link and per-game config. If a tracked repo is unavailable, the state file is rewritten to match whatever is actually available locally.

---

## Environment variables

Customise behaviour at the command line without editing the script:

```bash
VARIABLE=value ./reshade-linux.sh
```

| Variable | Default | Description |
| --- | --- | --- |
| `MAIN_PATH` | `~/.local/share/reshade` | Where ReShade files and state are stored. Auto-detected for Flatpak Steam. |
| `UI_BACKEND` | `auto` | Force the interface backend: `auto`, `yad`, `whiptail`, `dialog`, or `cli`. |
| `UPDATE_RESHADE` | `1` | Set to `0` to skip checking for new ReShade/shader versions. |
| `RESHADE_VERSION` | `latest` | Pin to a specific ReShade version, e.g. `4.9.1`. |
| `RESHADE_ADDON_SUPPORT` | `0` | Set to `1` to use the addon-enabled build (single-player use only). |
| `SHADER_REPOS` | *(18 repos)* | Semicolon-separated list of `URI\|local-name[\|branch[\|description]]` shader repositories. |
| `GAME_DIR_PRESETS` | *(empty)* | Per-game exe subdirectory overrides, e.g. `12345\|Binaries/Win64`. |
| `GLOBAL_INI` | `ReShade.ini` | Template for per-game `ReShade.ini`. Set to `0` to let ReShade create it on first launch. |
| `LINK_PRESET` | *(empty)* | Preset `.ini` file in `MAIN_PATH` to copy into a game's directory on first install. |
| `WINEPREFIX` | *(auto)* | Force a specific Wine prefix; auto-detected from `compatdata/` otherwise. |
| `DELETE_RESHADE_FILES` | `0` | Also delete `ReShade.log` and `ReShadePreset.ini` when uninstalling. |
| `FORCE_RESHADE_UPDATE_CHECK` | `0` | Bypass the 4-hour update check throttle. |
| `PROGRESS_UI` | `1` | Set to `0` to disable progress widgets while keeping the selected backend for dialogs. |
| `RESHADE_DEBUG_LOG` | *(empty)* | Append timestamped trace messages to this file for debugging non-CLI hangs. |

---

## GUI launcher

Launch the graphical wrapper directly:

```bash
./reshade-linux-gui.sh
```

This wrapper prefers `UI_BACKEND=yad` when `yad` is installed and otherwise falls back to the default backend selection. The repository also includes an AppImage launcher and desktop entry under [appimage/AppDir/](appimage/AppDir/).

---

## Repository layout

| Path | Purpose |
| --- | --- |
| `reshade-linux.sh` | Main entrypoint — orchestrates the full install/update/uninstall flow. |
| `reshade-linux-gui.sh` | GUI wrapper — sets `yad` as the preferred backend and launches the main script. |
| `lib/` | Production Bash libraries grouped by concern: config, state, shaders, Steam detection, UI, install flow. |
| `tests/` | Automated shell regression suite and fixtures. |
| `scripts/diagnostics/` | Local debugging and manual inspection scripts. |
| `appimage/` | Desktop-packaging assets (AppRun, `.desktop` entry). |

---

## Alternatives

For native Vulkan games, or Windows games running through DXVK/VKD3D, use:

- **[vkBasalt](https://github.com/DadSchoorse/vkBasalt)** — post-processing layer for Vulkan; works with native Linux games, DXVK (D3D9–D3D11), and VKD3D (D3D12).
- **vkBasalt via [Gamescope](https://github.com/Plagman/gamescope/)** — run vkBasalt on the compositor instead of the game, which works for any game Gamescope wraps.
