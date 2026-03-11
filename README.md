# reshade-linux

Bash script to download [ReShade](https://reshade.me/) and shaders and link them to games running with Wine or Proton on Linux.

> **Attribution:** This repository is an independent continuation of [kevinlekiller/reshade-steam-proton](https://github.com/kevinlekiller/reshade-steam-proton), originally written by [kevinlekiller](https://github.com/kevinlekiller). All original work and credit belongs to them. This fork modernises the codebase, fixes active bugs, and is maintained independently.

## Improvements over the original

- `downloadD3dcompiler_47()`: replaced Firefox 62 CDN (~50 MB installer) with a direct download from [mozilla/fxc2](https://github.com/mozilla/fxc2) — the same source used by Winetricks — with sha256 integrity verification.
- `d3d12` added to `COMMON_OVERRIDES` (ReShade officially supports Direct3D 12).
- Removed unsafe `eval` usage; tilde expansion handled safely with `${var/#\~/$HOME}`.
- `ls` replaced with `[[ -d ]]` and `compgen -G` for directory and glob tests.
- Shader repo loop rewritten to eliminate 4+ subshells per iteration.
- `which` replaced with `command -v`; `echo -ne` replaced with `printf`.
- `WINE_MAIN_PATH` and `LINKS` construction converted to pure Bash (no subshells).
- `cat` replaced with `$(< file)` for reading version files.
- `curl --fail` added to prevent silent HTTP error pages being treated as success.
- All `[[ $? ]]` indirect exit-code checks replaced with direct checks (ShellCheck SC2181).
- `RESHADE_URL_ALT` upgraded from `http://` to `https://`.
- `SHADER_REPOS` updated: replaced `martymcmodding/qUINT` (3 years stale) with its active successor [`martymcmodding/iMMERSE`](https://github.com/martymcmodding/iMMERSE); added [`Fubaxiusz/fubax-shaders`](https://github.com/Fubaxiusz/fubax-shaders), which is featured in the official ReShade installer.
- Flatpak Steam auto-detection: the script detects whether Steam is installed natively or as a Flatpak and sets `MAIN_PATH` automatically. If both are present it prompts the user to choose. The separate `reshade-linux-flatpak.sh` wrapper is no longer needed.
- GUI mode via `yad`: when `yad` is installed and a display server (`$DISPLAY` / `$WAYLAND_DISPLAY`) is present, every interactive prompt is replaced by a native GTK dialog — folder picker, radio lists, yes/no questions, text entry, and pulsating progress windows. Falls back to the existing CLI behaviour automatically when `yad` is absent or no display server is detected.
- Steam game auto-detection: install/uninstall now scans detected Steam libraries, shows installed games with icons, and automatically selects the correct game directory. No manual path entry needed for Steam games.
- **PE import table DLL detection**: the script parses the actual Windows PE import table of the game executable to determine the correct DLL override (`dxgi`, `d3d9`, `d3d11`, `opengl32`, `ddraw`, etc.) rather than defaulting to `dxgi` for all 64-bit games.
- **Authoritative exe selection via `appinfo.vdf`**: Steam's binary metadata database is parsed to find the exact launch executable for each game, overriding heuristic scanning.
- **Installed game indicator**: the game picker marks games that already have ReShade installed with a ✔ prefix, so repeat runs are clearly visible.
- **Per-game state files**: installation settings (DLL, architecture, path) are stored in `~/.local/share/reshade/game-state/`. Reinstalling a game skips the DLL dialog and reuses the stored settings automatically.
- **Auto Steam launch option**: after installation the `WINEDLLOVERRIDES` launch option is written directly into Steam's `localconfig.vdf`, so you do not need to manually paste it into Game Properties. Steam needs a restart for the change to appear.
- **Batch update mode** (`--update-all`): re-links ReShade for all previously installed games non-interactively. Run this after a ReShade version update.
- Detected game picker now shows the likely executable name alongside the target install directory.
- Optional per-game directory presets with `GAME_DIR_PRESETS` (example: `GAME_DIR_PRESETS="12345|Binaries/Win64;67890|bin/x64" ./reshade-linux.sh`).
- Includes a small built-in preset map for common non-root executable layouts (Cyberpunk 2077, Witcher 3, Oblivion Remastered, ESO, etc.); `GAME_DIR_PRESETS` overrides built-ins.
- Zero ShellCheck warnings.

## Usage

### Quick:

Download the script:

    curl -LO https://github.com/asafelobotomy/reshade-steam-proton/raw/main/reshade-linux.sh

Make it executable:

    chmod u+x reshade-linux.sh

Execute the script:

    ./reshade-linux.sh

### Detailed:

For full usage instructions, see the comments at the top of the script:

https://github.com/asafelobotomy/reshade-steam-proton/blob/main/reshade-linux.sh#L21

## AppImage

A self-contained AppImage can be built from the repository. It bundles `yad` (when present on the build host) so GUI mode works on target systems that do not have `yad` installed. GTK3 is intentionally not bundled — it is universally available on desktop distros.

**Build:**

```bash
bash appimage/build.sh
```

Requirements: `curl`, `ImageMagick` (`magick` or `convert`). `yad` is optional — if present it is bundled automatically.

**Run:**

```bash
chmod +x reshade-linux-x86_64.AppImage
./reshade-linux-x86_64.AppImage
```

The generated AppImage file, the `appimage/tools/` cache directory, and the `appimage/AppDir/usr/` staging tree are gitignored.

## Batch update

After a ReShade version update, re-link all previously installed games without any prompts:

```bash
./reshade-linux-x86_64.AppImage --update-all
```

This reads the per-game state files in `~/.local/share/reshade/game-state/` and re-creates all symlinks pointing at the latest ReShade version.

## Alternatives

### vkBasalt:
https://github.com/DadSchoorse/vkBasalt

For native Linux Vulkan games, Windows games which can run through DXVK (D3D9 / D3D10 / D3D11) and Windows games which can run through VKD3D (D3D12).

### vkBasalt through Gamescope:

Since [gamescope](https://github.com/Plagman/gamescope/) can use Vulkan, you can run vkBasalt on gamescope itself, instead of on the game.

## Misc

`reshade-linux.sh` is the main script — works with any Windows game running under Wine or Proton. It auto-detects whether Steam is installed natively or as a Flatpak and configures `MAIN_PATH` accordingly.

[`yad`](https://github.com/v1cont/yad) is an optional dependency. Install it with your package manager (`sudo dnf install yad`, `sudo apt install yad`, etc.) to enable GUI mode. When absent the script runs entirely in the terminal.

## Environment variables

All behaviour can be customised without editing the script. Key variables:

| Variable | Default | Description |
|---|---|---|
| `MAIN_PATH` | `~/.local/share/reshade` | Where ReShade files and state are stored. Auto-detected for Flatpak Steam. |
| `UPDATE_RESHADE` | `1` | Set to `0` to skip checking for new ReShade/shader versions. |
| `RESHADE_VERSION` | `latest` | Pin to a specific ReShade version, e.g. `4.9.1`. |
| `RESHADE_ADDON_SUPPORT` | `0` | Set to `1` to use the addon-enabled ReShade build (single-player only). |
| `SHADER_REPOS` | *(6 repos)* | Semicolon-separated list of `URI\|local-name[\|branch]` shader repositories. |
| `MERGE_SHADERS` | `1` | Merge all shader repos into a single `Merged/` folder. |
| `GAME_DIR_PRESETS` | *(empty)* | Per-game exe subdirectory overrides, e.g. `12345\|Binaries/Win64`. |
| `GLOBAL_INI` | `ReShade.ini` | Shared ReShade config file linked into every game directory. |
| `LINK_PRESET` | *(empty)* | Preset `.ini` file in `MAIN_PATH` to link into every game directory. |
| `WINEPREFIX` | *(auto)* | Force a specific Wine prefix; auto-detected from Steam `compatdata/` otherwise. |
| `VULKAN_SUPPORT` | `0` | Enable the experimental Vulkan registry path (currently non-functional). |
| `DELETE_RESHADE_FILES` | `0` | Also delete `ReShade.log` and `ReShadePreset.ini` when uninstalling. |
| `FORCE_RESHADE_UPDATE_CHECK` | `0` | Bypass the 4-hour update check throttle. |
