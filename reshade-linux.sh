#!/bin/bash
cat > /dev/null <<LICENSE
    Copyright (C) 2021-2022  kevinlekiller

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
    https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html
LICENSE
cat > /dev/null <<DESCRIPTION
    Bash script to download ReShade and ReShade shaders then links them to a game directory for games using Wine or Proton on Linux.
    By linking, re-running this script will update ReShade / shaders for all games.

    Requirements:
        grep   : Used in various parts of the script.
        7z     : Used to extract exe files
        curl   : Used to download files.
        git    : Used to clone ReShade shader repositories.
        wine   : Only used if the game uses Vulkan (to insert Windows Registry entries).
        yad    : Optional. When a display server is available and yad is installed, the script
                 automatically uses GTK dialogs for all prompts (directory picker, radio lists,
                 progress windows, info/error dialogs). Falls back to CLI if yad is absent.

    Notes:
        Vulkan / ReShade currently is not functional under wine.
        It might become possible in the future, so this information is provided in the event that happens.
        See https://github.com/kevinlekiller/reshade-steam-proton/issues/6
            Vulkan games like Doom (2016) : When asked if the game uses the Vulkan API, type y.
            Tell the script if the executable is 32 bit or 64 bit (by using the file command on the exe file or check on https://www.pcgamingwiki.com)
            Provide the WINEPREFIX to the script, for Steam games, the WINEPREFIX's folder name is the App ID and is stored in ~/.local/share/Steam/steamapps/compatdata/
            For example, on Doom (2016) on Steam, the WINEPREFIX is ~/.local/share/Steam/steamapps/compatdata/379720

        OpenGL games require the dll to be named opengl32.dll (Wolfenstein: The New Order for example).
        You will want to respond 'n' when asked for automatic detection of the dll.
        Then you will write 'opengl32' when asked for the name of the dll to override.
        You can check on pcgamingwiki.com to see what graphic API the game uses.

        Some 32 bit games use Direct3D 11 (Leisure Suit Larry: Wet Dreams Don't Dry for example),
         you'll have to manually specify the architecture (32) and DLL name (dxgi).

        Adding shader files not in a repository to the Merged/Shaders folder:
            For example, if we want to add this shader (CMAA2.fx) https://gist.github.com/kevinlekiller/cbb663e14b0f6ad6391a0062351a31a2
            Create the External_shaders folder inside the MAIN_PATH folder (by default $HOME/.local/share/reshade)
            Add the shader to it: cd "$HOME/.local/share/reshade/External_shaders" && curl -LO https://gist.github.com/kevinlekiller/cbb663e14b0f6ad6391a0062351a31a2/raw/CMAA2.fx
            Run this script, the shader will then be linked to the Merged folder.

        When you enable shaders in Reshade, this is a rough ideal order of shaders :
            color -> contrast/brightness/gamma -> anti-aliasing -> sharpening -> film grain

    Usage:
        Download the script
            Using curl:
                curl -LO https://github.com/asafelobotomy/reshade-steam-proton/raw/main/reshade-linux.sh
            Using git:
                git clone https://github.com/asafelobotomy/reshade-steam-proton
                cd reshade-steam-proton
        Make it executable:
            chmod u+x reshade-linux.sh
        Run it:
            ./reshade-linux.sh

        Installing ReShade for a DirectX / OpenGL game:
            Example on Back To The Future Episode 1:

                Find the game directory where the .exe file is.
                    If using Steam, you can open the Steam client, right click the game, click Properties,
                    click Local Files, clicking Browse, find the directory with the main
                    exe file, copy it, supply it to the script.

                    Or you can run : find ~/.local/share/Steam/steamapps/common -iregex ".*Back to the future.*.exe$"
                    We see BackToTheFuture101.exe is in "/home/kevin/.local/share/Steam/steamapps/common/Back to the Future Ep 1/"

                Run this script: ./reshade-linux.sh

                Type n when asked if the game uses the Vulkan API.

                Type i to install ReShade.
                    If you have never run this script, the shaders and ReShade will be downloaded.

                Supply the game directory where exe file is, when asked:
                    /home/kevin/.local/share/Steam/steamapps/common/Back to the Future Ep 1

                Select if you want it to automatically detect the correct dll file for ReShade or
                  to manually specity it.

                Set the WINEDLLOVERRIDES environment variable as instructed.

                Run the game, set the Effects and Textures search paths in the ReShade settings if required.

        Uninstalling ReShade for a DirectX /OpenGL game:
            Run this script: ./reshade-linux.sh

            Type n when asked if the game uses the Vulkan API.

            Type u to uninstall ReShade.

            Supply the game path where the .exe file is (see instructions above).

        Installing ReShade for a Vulkan game:
            Example on Doom (2016) on Steam:

                Run this script ./reshade-linux.sh

                When asked if the game is using the Vulkan API, type y

                Supply the WINEPREFIX:
                To find the WINEPREFIX for Doom on Steam, do a search on https://steamdb.info for Doom : https://steamdb.info/app/379720/
                We see the App ID listed there as 379720, we can now search for the folder: find ~/.local/share/Steam -wholename *compatdata/379720
                    /home/kevin/.local/share/Steam/steamapps/compatdata/379720

                Supply the exe architecture (32 or 64 bits):
                To find the exe architecture for the game, we can run: file ~/.local/share/Steam/steamapps/common/DOOM/DOOMx64vk.exe
                    /home/kevin/.local/share/Steam/steamapps/common/DOOM/DOOMx64vk.exe: PE32+ executable (GUI) x86-64, for MS Windows
                x86-64 is 64 bits, Intel 80386 would be 32 bits.

                Type i when asked if you want to install ReShade.

        Uninstall ReShade for a Vulkan game:
                Run this script ./reshade-linux.sh

                Type y when asked if the game is using the Vulkan API.

                Supply the WINEPREFIX location and the exe architecture.

                Type u to uninstall ReShade.

        Removing ReShade / shader files:
            By default the files are stored in $HOME/.local/share/reshade
            Run: rm -rf "$HOME/.local/share/reshade"

    Environment Variables:
        UPDATE_RESHADE
            To skip checking for ReShade and shader updates, set UPDATE_RESHADE=0
            ex.: UPDATE_RESHADE=0 ./reshade-linux.sh

        MAIN_PATH
            The directory where this script stores ReShade, shaders, and supporting files.
            Auto-detected on startup:
                If only Flatpak Steam is found (~/.var/app/com.valvesoftware.Steam), its data
                directory is used automatically.
                If both Flatpak and native Steam are found, you will be prompted to choose.
                Otherwise the XDG default is used ($HOME/.local/share/reshade).
            You can skip auto-detection by setting MAIN_PATH explicitly before running the script.
            ex.: MAIN_PATH=~/Documents/reshade ./reshade-linux.sh

        SHADER_REPOS
            List of git repo URI's to clone or update which contain reshade shaders.
            By default this is set to :
                https://github.com/CeeJayDK/SweetFX|sweetfx-shaders;https://github.com/martymcmodding/iMMERSE|immerse-shaders;https://github.com/BlueSkyDefender/AstrayFX|astrayfx-shaders;https://github.com/prod80/prod80-ReShade-Repository|prod80-shaders;https://github.com/crosire/reshade-shaders|reshade-shaders|slim;https://github.com/Fubaxiusz/fubax-shaders|fubax-shaders
            The format is (the branch is optional) : URI|local_repo_name|branch
            Use ; to separate multiple repos. For example: URI1|local_repo_name_1|master;URI2|local_repo_name_2

        MERGE_SHADERS
            If you're using multiple shader repositories, all the unique shaders will be put into one folder called Merged.
            For example, if you use reshade-shaders and sweetfx-shaders, both have ASCII.fx,
              by enabling MERGE_SHADERS, only 1 ASCII.fx is put into the Merged folder.
            The order of priority for shaders is taken from SHADER_REPOS.
            The default is MERGE_SHADERS=1
            To disable, set MERGE_SHADERS=0

        REBUILD_MERGE
            Set to REBUILD_MERGE to 1 to rebuild the MERGE_SHADERS folder.
            This is useful if you have changed SHADER_REPOS
            ex.: REBUILD_MERGE=1 SHADER_REPOS="https://github.com/martymcmodding/qUINT|martymc-shaders" ./reshade-linux.sh

        GLOBAL_INI
            With the default, GLOBAL_INI=1, the script will create a ReShade.ini file and store it
              in MAIN_PATH folder if it does not exist.
            The script will link this ReShade.ini file to the game's path.
            If you have disabled MERGE_SHADERS, you will need to manually edit the paths by editing
              this ReShade.ini file. Alternatively, when ReShade launches, you can change the paths in the GUI.
            You can disable GLOBAL_INI with : GLOBAL_INI=0
            Disabling GLOBAL_INI will cause ReShade to create a ReShade.ini file when the game starts,
              you will then need to manually configure ReShade when the game starts.
            You can also use a different ReShade.ini than the one that is created by this script,
              put it in the MAIN_PATH folder, then set GLOBAL_INI to the name of the
              file, for example : GLOBAL_INI="ReShade2.ini" ./reshade-linux.sh

        LINK_PRESET
            Link a ReShade preset file to the game's directory.
            Put the preset file in the MAIN_PATH, then run the script with LINK_PRESET set to the name of the file.
            ex.: LINK_PRESET=ReShadePreset.ini ./reshade-linux.sh

        RESHADE_VERSION
            To use a version of ReShade other than the newest version.
            If the version does not exist, the script will exit.
            The default is RESHADE_VERSION="latest"
            ex.: RESHADE_VERSION="4.9.1" ./reshade-linux.sh

        FORCE_RESHADE_UPDATE_CHECK
            By default the script will only check for updates if the script hasn't been run in more than 4 hours.
            This will bypass the 4 hours.
            ex.: FORCE_RESHADE_UPDATE_CHECK=1 ./reshade-linux.sh

        RESHADE_ADDON_SUPPORT
            This will download ReShade with addon support, it's only intended for single player games,
             since anti-cheat software might detect it as malicious.
            ex.: RESHADE_ADDON_SUPPORT=1 ./reshade-linux.sh

        DELETE_RESHADE_FILES
            When uninstalling ReShade for game, if DELETE_RESHADE_FILES is set to 1, ReShade.log and ReShadePreset.ini will be deleted.
            Disabled by default.
            ex.: DELETE_RESHADE_FILES=1 ./reshade-linux.sh

        VULKAN_SUPPORT
            As noted below, Vulkan / ReShade is not currently functional under wine.
            The script contains a function to enable ReShade under Vulkan, although it's disabled
            by default since it's currently not functional, you can enable this function by
            passing VULKAN_SUPPORT=1
            ex.: VULKAN_SUPPORT=1 ./reshade-linux.sh

        WINEPREFIX
            Since ReShade 6.5+, d3dcompiler_47.dll must also be present in the game's Wine/Proton
            prefix (drive_c/windows/system32 for 64-bit games, or syswow64 for 32-bit games),
            not only in the game folder. Without this, ReShade shaders will fail to compile.
            Set WINEPREFIX to the path of the Wine/Proton prefix for the game to have this script
            install d3dcompiler_47.dll there automatically.
            For Steam games with Proton, the prefix is typically found at:
            ~/.local/share/Steam/steamapps/compatdata/<AppID>/pfx
            You can find your game's AppID on https://steamdb.info
            ex.: WINEPREFIX="$HOME/.local/share/Steam/steamapps/compatdata/12345/pfx" ./reshade-linux.sh

        GAME_DIR_PRESETS
            Optional app-specific install-directory overrides used by Steam auto-detection.
            Format: AppID|subdirectory;AppID2|subdirectory2
            ex.: GAME_DIR_PRESETS="12345|Binaries/Win64;67890|bin/x64" ./reshade-linux.sh
            If a preset matches, that subdirectory is used instead of built-in presets and generic heuristics.
DESCRIPTION

# Print error and exit
# $1 is message
# $2 is exit code
function printErr() {
    removeTempDir
    printf '%bError: %s\nExiting.%b\n' "$_RED$_B" "$1" "$_R" >&2
    [[ $_GUI -eq 1 ]] && yad --error --title="ReShade — Error" \
        --text="<b>Error:</b>\n$1" --width=520 --button="OK:0" 2>/dev/null
    [[ -z $2 ]] && exit 1 || exit "$2"
}

# Check user input
# $1 is valid values to display to user
# $2 is regex
function checkStdin() {
    while true; do
        read -rp "$(printf '%b%s%b' "$_YLW" "$1" "$_R")" userInput
        if [[ $userInput =~ $2 ]]; then
            break
        fi
    done
    echo "$userInput"
}

# Print a colored section header.
# $1 is the message
function printStep() {
    printf '%b==> %s%b\n' "$_CYN$_B" "$1" "$_R"
}

# Run a command while showing a pulsating yad progress window (GUI mode only).
# $1 = dialog label text; remaining args = command + arguments to execute.
# The command runs in the current shell so functions and cd side-effects work normally.
function withProgress() {
    local text="$1"; shift
    if [[ $_GUI -eq 1 ]]; then
        # Drive yad --pulsate from a background loop; kill it when the command finishes.
        (while true; do printf '1\n'; sleep 0.1; done) \
            | yad --progress --pulsate --no-buttons \
                  --title="ReShade" --text="$text" --width=480 2>/dev/null &
        local _yadPid=$!
        "$@"
        local _ret=$?
        kill "$_yadPid" 2>/dev/null
        wait "$_yadPid" 2>/dev/null
        return $_ret
    else
        "$@"
    fi
}

# Return all detected Steam library steamapps directories (one per line).
function listSteamAppsDirs() {
    local _root _vdf _libPath _key
    local -A _seen=()
    for _root in \
        "$XDG_DATA_HOME/Steam" \
        "$HOME/.local/share/Steam" \
        "$HOME/.steam/steam" \
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"; do
        [[ -d "$_root/steamapps" ]] || continue
        # Canonicalize the path so that symlinks (e.g. /home -> /var/home) are
        # treated as the same directory and not enumerated twice.
        _key=$(realpath "$_root/steamapps" 2>/dev/null || printf '%s' "$_root/steamapps")
        if [[ -z ${_seen["$_key"]+x} ]]; then
            printf '%s\n' "$_root/steamapps"
            _seen["$_key"]=1
        fi
        _vdf="$_root/steamapps/libraryfolders.vdf"
        [[ -f $_vdf ]] || continue
        while IFS= read -r _libPath; do
            _libPath=${_libPath//\\\\/\\}
            [[ -d "$_libPath/steamapps" ]] || continue
            _key=$(realpath "$_libPath/steamapps" 2>/dev/null || printf '%s' "$_libPath/steamapps")
            if [[ -z ${_seen["$_key"]+x} ]]; then
                printf '%s\n' "$_libPath/steamapps"
                _seen["$_key"]=1
            fi
        done < <(sed -n 's/.*"path"[[:space:]]*"\([^"]*\)".*/\1/p' "$_vdf")
    done
}

# Find a locally cached Steam icon for an AppID.
# Checks appcache/librarycache in each known Steam root; prints path or empty string.
function findSteamIconPath() {
    local _steamRoot="$1" _appId="$2" _root _dir _f _c
    local _cacheDir="${XDG_CACHE_HOME:-$HOME/.cache}/reshade-linux/icons"

    # Backward compatibility: accept legacy call order (appId, steamRoot).
    if [[ $_steamRoot =~ ^[0-9]+$ ]] && [[ -n $_appId && $_appId == /* ]]; then
        local _tmp="$_steamRoot"
        _steamRoot="$_appId"
        _appId="$_tmp"
    fi

    # 1. Check persistent download cache (from previous CDN fetches).
    for _c in "$_cacheDir/${_appId}.png" "$_cacheDir/${_appId}.jpg"; do
        [[ -f $_c ]] && { printf '%s\n' "$_c"; return; }
    done

    # 2. Check provided Steam root first (for external libraries), if specified.
    if [[ -n $_steamRoot && -d $_steamRoot ]]; then
        _dir="$_steamRoot/appcache/librarycache/${_appId}"
        if [[ -d $_dir ]]; then
            # Prefer logo.png (game logo with transparent background).
            [[ -f "$_dir/logo.png" ]] && { printf '%s\n' "$_dir/logo.png"; return; }
            # Then pick the small hash-named .jpg (32x32 game icon stored by Steam).
            for _f in "$_dir"/*.jpg; do
                [[ -f $_f ]] || continue
                case $(basename "$_f") in header.jpg|library_*.jpg) continue ;; esac
                printf '%s\n' "$_f"; return
            done
            # Fall back to banner header.
            [[ -f "$_dir/header.jpg" ]] && { printf '%s\n' "$_dir/header.jpg"; return; }
        fi
    fi

    # 3. Check local Steam client image cache (standard locations).
    for _root in \
        "${XDG_DATA_HOME:-$HOME/.local/share}/Steam" \
        "$HOME/.local/share/Steam" \
        "$HOME/.steam/steam" \
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"; do
        _dir="$_root/appcache/librarycache/${_appId}"
        [[ -d $_dir ]] || continue
        # Prefer logo.png (game logo with transparent background).
        [[ -f "$_dir/logo.png" ]] && { printf '%s\n' "$_dir/logo.png"; return; }
        # Then pick the small hash-named .jpg (32x32 game icon stored by Steam).
        for _f in "$_dir"/*.jpg; do
            [[ -f $_f ]] || continue
            case $(basename "$_f") in header.jpg|library_*.jpg) continue ;; esac
            printf '%s\n' "$_f"; return
        done
        # Fall back to banner header.
        [[ -f "$_dir/header.jpg" ]] && { printf '%s\n' "$_dir/header.jpg"; return; }
    done
}

# Return preset subdirectory for an AppID from BUILTIN_GAME_DIR_PRESETS.
function getBuiltInGameDirPreset() {
    local _appId="$1" _entry _k _v
    local IFS=';'
    for _entry in $BUILTIN_GAME_DIR_PRESETS; do
        _k=${_entry%%|*}
        _v=${_entry#*|}
        [[ $_k == "$_appId" ]] && { printf '%s\n' "$_v"; return; }
    done
}

# Pick the most likely game executable from a directory.
# ReShade requires the ACTUAL game executable for DLL injection (via WINEDLLOVERRIDES).
# Filters out utilities (crash handlers, installers, etc.) and scores by name similarity to parent folder.
# Prints basename (or empty string if none found).
function pickBestExeInDir() {
    local _dir="$1" _parentDir _exe _name _lname _score _best _bestScore=-999999 _isUtility
    local _exeList=()
    
    _parentDir=$(basename "$_dir" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9')
    
    # Collect all .exe files and score them.
    for _exe in "$_dir"/*.exe; do
        [[ -f $_exe ]] || continue
        _name=${_exe##*/}
        _lname=${_name,,}
        _score=50
        _isUtility=0
        
        # Aggressive blacklist: filter OUT known non-game executables.
        if [[ $_lname =~ (unityplayer|unitycrash|crashhandler|easyanticheat|battleye|asp|unins|uninstall|setup|installer|vcredist|redist|eac|crashreport|crashpad|benchmark|test|launcher|update|check|remov|error|consultant) ]]; then
            _isUtility=1
            _score=$((_score - 200))
        fi
        # Mono runtime bundled with some Linux games — not a game executable.
        [[ $_lname =~ ^mono\. ]] && { _isUtility=1; _score=$((_score - 200)); }
        
        # Moderate penalty: debug builds are rarely the correct launch target.
        [[ $_lname =~ debug ]] && _score=$((_score - 80))
        
        # Strong positive: name contains parent directory name.
        [[ "$_lname" == *"${_parentDir}"* ]] && _score=$((_score + 150))
        
        # Moderate positive: contains game-like keywords.
        [[ $_lname =~ (game|main|app|engine|client|server|game_?setup) ]] && _score=$((_score + 80))
        
        # Moderate positive: contains architecture keywords (games tend to match their arch).
        [[ $_lname =~ (win64|x64|win32|i386|64|x86|ia32) ]] && _score=$((_score + 40))
        
        # Small penalty: generic names that could be utilities.
        [[ $_lname =~ ^[a-z][a-z0-9]?$ || $_lname == "app.exe" ]] && _score=$((_score - 30))
        
        if [[ $_score -gt $_bestScore ]]; then
            _bestScore=$_score
            _best=$_name
        fi
    done
    
    # Don't return an exe that scored as a utility/debug — skip entry entirely.
    [[ $_bestScore -le 0 ]] && _best=""
    printf '%s\n' "$_best"
}

# Score a specific executable candidate for a directory using the same heuristics
# as pickBestExeInDir(). Higher score means a more likely real game executable.
function scoreExeCandidate() {
    local _dir="$1" _name="$2" _lname _parentDir _score=50
    [[ -z $_name ]] && { printf '%s\n' "-999999"; return; }
    _lname=${_name,,}
    _parentDir=$(basename "$_dir" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9')

    [[ $_lname =~ (unityplayer|unitycrash|crashhandler|easyanticheat|battleye|asp|unins|uninstall|setup|installer|vcredist|redist|eac|crashreport|crashpad|benchmark|test|launcher|update|check|remov|error|consultant) ]] && _score=$((_score - 200))
    [[ $_lname =~ ^mono\. ]] && _score=$((_score - 200))
    [[ $_lname =~ debug ]] && _score=$((_score - 80))
    [[ "$_lname" == *"${_parentDir}"* ]] && _score=$((_score + 150))
    [[ $_lname =~ (game|main|app|engine|client|server|game_?setup) ]] && _score=$((_score + 80))
    [[ $_lname =~ (win64|x64|win32|i386|64|x86|ia32) ]] && _score=$((_score + 40))
    [[ $_lname =~ ^[a-z][a-z0-9]?$ || $_lname == "app.exe" ]] && _score=$((_score - 30))

    printf '%s\n' "$_score"
}

# Resolve the preferred install directory for a Steam game root.
# Prints "<directory>|<reason>".
function resolveGameInstallDir() {
    local _root="$1" _appId="$2"
    local _preset _entry _k _v _candidate _exe _depth _score _best _bestScore=-999999

    # Optional presets: GAME_DIR_PRESETS="12345|Binaries/Win64;67890|bin/x64"
    if [[ -n ${GAME_DIR_PRESETS:-} ]]; then
        local IFS=';'
        for _entry in $GAME_DIR_PRESETS; do
            _k=${_entry%%|*}
            _v=${_entry#*|}
            if [[ $_k == "$_appId" ]] && [[ -n $_v ]] && [[ -d "$_root/$_v" ]]; then
                printf '%s|%s\n' "$_root/$_v" "preset:$_v"
                return
            fi
        done
    fi

    # Built-in presets for known games with non-root launch directories.
    _preset=$(getBuiltInGameDirPreset "$_appId")
    if [[ -n $_preset ]] && [[ -d "$_root/$_preset" ]]; then
        printf '%s|%s\n' "$_root/$_preset" "builtin:$_preset"
        return
    fi

    for _candidate in \
        "." \
        "Binaries/Win64" "Binaries/Win32" "Binaries" \
        "bin/x64" "bin/x86" "bin" \
        "Win64" "Win32" "x64" "x86"; do
        if [[ $_candidate == "." ]]; then
            _candidate="$_root"
        else
            _candidate="$_root/$_candidate"
        fi
        if [[ -d $_candidate ]] && compgen -G "$_candidate/*.exe" &>/dev/null; then
            printf '%s|%s\n' "$_candidate" "heuristic"
            return
        fi
    done

    # Generic fallback: scan exe files and score likely launch targets.
    while IFS='|' read -r _depth _exe; do
        [[ -n $_exe ]] || continue
        _score=$((200 - _depth * 12))
        _name=${_exe##*/}
        _name=${_name,,}
        [[ $_name =~ (unins|uninstall|setup|installer|vcredist|redist|eac|easyanticheat|crashreport|crashpad|benchmark|remov|error|consultant) ]] && _score=$((_score - 100))
        [[ $_name =~ ^mono\. ]] && _score=$((_score - 100))
        [[ $_name =~ debug ]] && _score=$((_score - 50))
        # Penalize executables buried inside Mono/Unity runtime directories.
        [[ $_exe == */Mono/lib/* || $_exe == */Mono/bin/* || $_exe == */MonoBleedingEdge/* ]] && _score=$((_score - 300))
        [[ $_name =~ (shipping|game|win64|x64) ]] && _score=$((_score + 15))
        if [[ $_score -gt $_bestScore ]]; then
            _bestScore=$_score
            _best=$(dirname "$_exe")
        fi
    done < <(find "$_root" -maxdepth 5 -type f -iname '*.exe' -printf '%d|%p\n' 2>/dev/null)

    # Only use the scan result if it has a plausible game executable.
    if [[ -n $_best && $_bestScore -ge 0 ]]; then
        printf '%s|%s\n' "$_best" "scan"
    else
        printf '%s|%s\n' "$_root" "root"
    fi
}

# Find Steam's binary appinfo.vdf, which contains authoritative launch exe data for
# every game Steam knows about (installed or not). Returns the path or nothing.
function findSteamAppinfoVdf() {
    local _r
    for _r in \
        "${XDG_DATA_HOME:-$HOME/.local/share}/Steam" \
        "$HOME/.local/share/Steam" \
        "$HOME/.steam/steam" \
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"; do
        [[ -f "$_r/appcache/appinfo.vdf" ]] && { printf '%s\n' "$_r/appcache/appinfo.vdf"; return; }
    done
}

# Parse Steam's binary appinfo.vdf once and emit one line per game:
#   <appid>:<exe1>|<exe2>|...
# where exeN are unique Windows .exe paths from the launch config (in Steam's order).
# Uses only Python3 stdlib (struct). Silently exits on any error or unsupported format.
function loadSteamAppinfoExes() {
    local _appinfo="$1"
    [[ -f $_appinfo ]] || return
    command -v python3 &>/dev/null || return
    python3 - "$_appinfo" 2>/dev/null <<'PYEOF'
import sys, struct
try:
    with open(sys.argv[1], 'rb') as fh:
        raw = fh.read()
except OSError:
    sys.exit(0)

magic = raw[:4]
# bytes 1-3 must be b'DV\x07'; byte 0 is the format variant (0x27, 0x28, or 0x29)
if len(raw) < 8 or magic[1:4] != b'DV\x07':
    sys.exit(0)

# File header: 8 bytes for 0x27/0x28, 16 bytes for 0x29+
pos     = 8 if magic[0] < 0x29 else 16
new_sha = magic[0] >= 0x28   # 0x28 and 0x29 add a data_sha1 field per record

# In the per-app binary VDF, launch executables are stored with uint32 integer
# keys (NOT null-terminated string keys like public VDF). The pattern:
#   T_STRING (0x01) + uint32-LE key 457 (0x01C9) == "executable"
EXEC_PAT = b'\x01\xc9\x01\x00\x00'
# Metadata bytes to skip at the start of each app record before the binary VDF:
#   info_state(4) + last_updated(4) + access_token(8) + sha1(20) + change_number(4)
#   + data_sha1(20 if new_sha)
META_SZ = 4 + 4 + 8 + 20 + 4 + (20 if new_sha else 0)

while pos + 8 <= len(raw):
    appid = struct.unpack_from('<I', raw, pos)[0]; pos += 4
    if appid == 0:
        break
    sz  = struct.unpack_from('<I', raw, pos)[0]; pos += 4
    end = pos + sz
    chunk = raw[pos + META_SZ : end]
    pos   = end

    seen, results = set(), []
    p = 0
    while len(results) < 8:
        i = chunk.find(EXEC_PAT, p)
        if i == -1:
            break
        s = i + len(EXEC_PAT)
        e = chunk.find(b'\x00', s)
        if e == -1:
            break
        exe = chunk[s:e].decode('utf-8', 'replace').replace('\\\\', '/').replace('\\', '/')
        if exe.lower().endswith('.exe'):
            key = exe.lower()
            if key not in seen:
                seen.add(key)
                # Sanitize: replace '|' (our delimiter) with '/'
                results.append(exe.replace('|', '/'))
        p = i + 1

    if results:
        print(f"{appid}:{'|'.join(results)}")
PYEOF
}

# Detect the architecture and best ReShade DLL hook for a game directory by
# parsing the PE import table of root-level .exe files (Python3 stdlib only).
# $1 = game directory to scan
# Outputs two lines on success: "arch=64" and "dll=dxgi" (values vary per game).
function detectExeInfo() {
    local _dir="$1"
    command -v python3 &>/dev/null || return 1
    python3 - "$_dir" 2>/dev/null <<'PYEOF'
import sys, struct, os, re
BLACKLIST = re.compile(
    r'crash|setup|uninst|install|redist|vcredist|dxsetup|vc_redist|dotnet|error|remov', re.I)
PRIORITY  = ['d3d12.dll','d3d11.dll','d3d10.dll','d3d9.dll','d3d8.dll',
             'opengl32.dll','ddraw.dll','dinput8.dll']
OVERRIDE  = {'d3d12.dll':'dxgi','d3d11.dll':'dxgi','d3d10.dll':'dxgi',
             'd3d9.dll':'d3d9','d3d8.dll':'d3d8',
             'opengl32.dll':'opengl32','ddraw.dll':'ddraw','dinput8.dll':'dinput8'}

def parse_pe(path):
    try:
        with open(path, 'rb') as f:
            data = f.read(min(os.path.getsize(path), 2 * 1024 * 1024))
    except OSError:
        return None, []
    if data[:2] != b'MZ':
        return None, []
    e_lfanew = struct.unpack_from('<I', data, 60)[0]
    if e_lfanew + 24 > len(data) or data[e_lfanew:e_lfanew+4] != b'PE\x00\x00':
        return None, []
    num_sec   = struct.unpack_from('<H', data, e_lfanew + 6)[0]
    opt_sz    = struct.unpack_from('<H', data, e_lfanew + 20)[0]
    opt_off   = e_lfanew + 24
    if opt_off + 2 > len(data):
        return None, []
    opt_magic = struct.unpack_from('<H', data, opt_off)[0]
    is64  = (opt_magic == 0x20b)
    arch  = 64 if is64 else 32
    # DataDirectory[1] (Import): PE32 = opt_off+104, PE32+ = opt_off+120
    imp_rva_off = opt_off + (120 if is64 else 104)
    if imp_rva_off + 4 > len(data):
        return arch, []
    imp_rva = struct.unpack_from('<I', data, imp_rva_off)[0]
    if imp_rva == 0:
        return arch, []
    sec_off  = opt_off + opt_sz
    sections = []
    for i in range(num_sec):
        s = sec_off + i * 40
        if s + 40 > len(data):
            break
        va  = struct.unpack_from('<I', data, s + 12)[0]
        vsz = struct.unpack_from('<I', data, s + 16)[0]
        raw = struct.unpack_from('<I', data, s + 20)[0]
        sections.append((va, vsz, raw))
    def rva2off(rva):
        for va, vsz, raw in sections:
            if va <= rva < va + vsz:
                return raw + (rva - va)
        return None
    imp_off = rva2off(imp_rva)
    if imp_off is None:
        return arch, []
    imports = []
    idx = 0
    while True:
        d = imp_off + idx * 20
        if d + 20 > len(data):
            break
        name_rva = struct.unpack_from('<I', data, d + 12)[0]
        if name_rva == 0:
            break
        no  = rva2off(name_rva)
        if no is None:
            break
        end = data.find(b'\x00', no)
        if end < 0:
            break
        imports.append(data[no:end].decode('ascii', 'replace').lower())
        idx += 1
    return arch, imports

game_dir = sys.argv[1] if len(sys.argv) > 1 else '.'
try:
    exes = [f for f in os.listdir(game_dir)
            if f.lower().endswith('.exe') and not BLACKLIST.search(f)]
except OSError:
    sys.exit(1)

arch_votes = {32: 0, 64: 0}
dll_votes  = {}
for exe in exes:
    arch, imports = parse_pe(os.path.join(game_dir, exe))
    if arch:
        arch_votes[arch] += 1
    for imp in imports:
        if imp in OVERRIDE:
            dll_votes[imp] = dll_votes.get(imp, 0) + 1

final_arch = 64 if arch_votes[64] >= arch_votes[32] else 32
best_dll   = next((OVERRIDE[p] for p in PRIORITY if p in dll_votes), None)
if best_dll is None:
    best_dll = 'dxgi' if final_arch == 64 else 'd3d9'
print(f"arch={final_arch}")
print(f"dll={best_dll}")
PYEOF
}

# Write a per-game state file recording installation details.
# $1=appId  $2=gamePath  $3=dll  $4=arch
# State files live in $MAIN_PATH/game-state/<appid>.state
function writeGameState() {
    local _aid="$1" _gp="$2" _dll="$3" _arch="$4"
    [[ -z $_aid ]] && return
    local _dir="$MAIN_PATH/game-state"
    mkdir -p "$_dir" 2>/dev/null || return
    printf 'dll=%s\narch=%s\ngamePath=%s\n' "$_dll" "$_arch" "$_gp" > "$_dir/$_aid.state"
}

# Write/replace the Steam launch option for a game in localconfig.vdf.
# $1=appId  $2=full launch option string  (e.g. 'WINEDLLOVERRIDES="..." %command%')
# Backs up the file before any modification.
function applyLaunchOption() {
    local _aid="$1" _opt="$2"
    [[ -z $_aid || -z $_opt ]] && return 1
    command -v python3 &>/dev/null || return 1
    local _vcfg _applied=0
    for _vcfg in \
        "$HOME/.local/share/Steam/userdata"/*/config/localconfig.vdf \
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/userdata"/*/config/localconfig.vdf; do
        [[ -f $_vcfg ]] || continue
        python3 - "$_vcfg" "$_aid" "$_opt" 2>/dev/null <<'PYEOF'
import sys, re, os, shutil
vdf_path, appid, launch_opt = sys.argv[1], sys.argv[2], sys.argv[3]

with open(vdf_path, encoding='utf-8', errors='replace') as f:
    text = f.read()

# Locate "apps" section then find the <appid> block within it using brace counting.
apps_m = re.search(r'"[Aa]pps"\s*\{', text)
if not apps_m:
    sys.exit(1)
appid_m = re.search(rf'"{ re.escape(appid) }"\s*\{{', text[apps_m.end():])
if not appid_m:
    sys.exit(1)

block_start = apps_m.end() + appid_m.end()
depth = 1
block_end = block_start
for pos, ch in enumerate(text[block_start:]):
    if ch == '{': depth += 1
    elif ch == '}':
        depth -= 1
        if depth == 0:
            block_end = block_start + pos
            break
else:
    sys.exit(1)

block    = text[block_start:block_end]
lo_re    = re.compile(r'"LaunchOptions"(\s+)"[^"]*"', re.I)
lo_repl  = f'"LaunchOptions"\t\t"{launch_opt}"'
if lo_re.search(block):
    new_block = lo_re.sub(lo_repl, block, count=1)
else:
    indent    = (re.search(r'\n(\s+)"', block) or re.match(r'()', '')).group(1) if re.search(r'\n(\s+)"', block) else '\t' * 8
    new_block = block.rstrip() + f'\n{indent}{lo_repl}\n'

new_text = text[:block_start] + new_block + text[block_end:]
shutil.copy2(vdf_path, vdf_path + '.reshade.bak')
with open(vdf_path, 'w', encoding='utf-8') as f:
    f.write(new_text)
print(f"Updated {vdf_path}")
PYEOF
        if [[ $? -eq 0 ]]; then
            _applied=1
        fi
    done
    return $(( 1 - _applied ))
}

# Fill auto-detected Steam game arrays.
function detectSteamGames() {
    DETECTED_GAME_NAMES=()
    DETECTED_GAME_APPIDS=()
    DETECTED_GAME_PATHS=()
    DETECTED_GAME_EXES=()
    DETECTED_GAME_ICONS=()
    DETECTED_GAME_REASONS=()
    local _steamapps _manifest _appId _name _installDir _type _root _resolved _path _reason _exe _icon _steamRoot _dedupeKey
    local _idx _oldIdx _newScore _oldScore _aiCand
    local -a _aiCands
    local -A _bestIdxByPath=()

    # Parse Steam's appinfo.vdf once — authoritative Windows launch exe for every game.
    local -A _appinfoExes=()
    local _appinfoFile
    _appinfoFile=$(findSteamAppinfoVdf)
    if [[ -n $_appinfoFile ]]; then
        while IFS=: read -r _aid _aexes; do
            [[ -n $_aid && -n $_aexes ]] && _appinfoExes["$_aid"]="$_aexes"
        done < <(loadSteamAppinfoExes "$_appinfoFile")
    fi

    while IFS= read -r _steamapps; do
        [[ -d $_steamapps ]] || continue
        # Extract Steam root: /path/to/steamapps -> /path/to
        _steamRoot="${_steamapps%/steamapps}"
        [[ -d $_steamRoot ]] || continue
        
        for _manifest in "$_steamapps"/appmanifest_*.acf; do
            [[ -f $_manifest ]] || continue
            _appId=$(grep -m1 -o '"appid"[[:space:]]*"[0-9]*"' "$_manifest" | grep -o '[0-9]*')
            _name=$(grep -m1 -o '"name"[[:space:]]*"[^"]*"' "$_manifest" | sed -E 's/.*"name"[[:space:]]*"([^"]*)".*/\1/')
            _installDir=$(grep -m1 -o '"installdir"[[:space:]]*"[^"]*"' "$_manifest" | sed -E 's/.*"installdir"[[:space:]]*"([^"]*)".*/\1/')
            _type=$(grep -m1 -o '"type"[[:space:]]*"[^"]*"' "$_manifest" | sed -E 's/.*"type"[[:space:]]*"([^"]*)".*/\1/' | tr '[:upper:]' '[:lower:]')

            # Normalize common ACF parsing artifacts (CRLF + surrounding spaces).
            _appId=${_appId//$'\r'/}
            _name=${_name//$'\r'/}
            _installDir=${_installDir//$'\r'/}
            _type=${_type//$'\r'/}
            _name="${_name#"${_name%%[![:space:]]*}"}"; _name="${_name%"${_name##*[![:space:]]}"}"
            _installDir="${_installDir#"${_installDir%%[![:space:]]*}"}"; _installDir="${_installDir%"${_installDir##*[![:space:]]}"}"
            _type="${_type#"${_type%%[![:space:]]*}"}"; _type="${_type%"${_type##*[![:space:]]}"}"

            [[ -n $_appId && -n $_installDir ]] || continue
            # Skip non-game entries: Proton builds, Steam runtimes, redistributables, etc.
            [[ -n $_type && $_type != "game" ]] && continue
            [[ $_name =~ ^Proton([[:space:]]|$) || $_name =~ ^Steam[[:space:]]Linux[[:space:]]Runtime || $_name == "Steamworks Common Redistributables" ]] && continue
            _root="$_steamapps/common/$_installDir"
            [[ -d $_root ]] || continue
            _resolved=$(resolveGameInstallDir "$_root" "$_appId")
            _path=${_resolved%%|*}
            _reason=${_resolved#*|}
            _exe=""

            # If no manually-curated preset matched, try Steam's appinfo.vdf for the
            # authoritative Windows launch executable. appinfo.vdf is Steam's own binary
            # database — it knows exactly which .exe Steam uses to start each game.
            # Presets (builtin/user) take priority because they point to the ReShade-
            # compatible exe, which may differ from the outer launcher Steam invokes.
            if [[ $_reason != preset:* && $_reason != builtin:* && -n ${_appinfoExes[$_appId]+x} ]]; then
                IFS='|' read -ra _aiCands <<< "${_appinfoExes[$_appId]}"
                for _aiCand in "${_aiCands[@]}"; do
                    if [[ -f "$_root/$_aiCand" ]]; then
                        _path=$(dirname "$_root/$_aiCand")
                        _exe=$(basename "$_aiCand")
                        _reason="appinfo"
                        break
                    fi
                done
            fi

            # Fall back to heuristic exe scoring if appinfo didn't resolve a valid on-disk exe.
            [[ -z $_exe ]] && _exe=$(pickBestExeInDir "$_path")

            # Canonicalize path for stable dedupe across symlinks/trailing slashes/case variants.
            _path=$(realpath "$_path" 2>/dev/null || printf '%s' "$_path")
            _path=${_path%/}
            _dedupeKey=${_path,,}

            [[ -d $_path ]] || continue
            [[ -z $_name ]] && _name="AppID $_appId"
            # ReShade only works with a Windows executable target; hide unusable auto-detections.
            [[ -z $_exe ]] && continue
            _icon=$(findSteamIconPath "$_steamRoot" "$_appId" 2>/dev/null || echo "")

            # Deduplicate by canonical install path and keep the best exe candidate.
            if [[ -n ${_bestIdxByPath["$_dedupeKey"]+x} ]]; then
                _oldIdx=${_bestIdxByPath["$_dedupeKey"]}
                _newScore=$(scoreExeCandidate "$_path" "$_exe")
                _oldScore=$(scoreExeCandidate "$_path" "${DETECTED_GAME_EXES[_oldIdx]}")
                if (( _newScore > _oldScore )); then
                    DETECTED_GAME_NAMES[_oldIdx]="$_name"
                    DETECTED_GAME_APPIDS[_oldIdx]="$_appId"
                    DETECTED_GAME_PATHS[_oldIdx]="$_path"
                    DETECTED_GAME_EXES[_oldIdx]="$_exe"
                    DETECTED_GAME_ICONS[_oldIdx]="$_icon"
                    DETECTED_GAME_REASONS[_oldIdx]="$_reason"
                fi
                continue
            fi

            DETECTED_GAME_NAMES+=("$_name")
            DETECTED_GAME_APPIDS+=("$_appId")
            DETECTED_GAME_PATHS+=("$_path")
            DETECTED_GAME_EXES+=("$_exe")
            DETECTED_GAME_ICONS+=("$_icon")
            DETECTED_GAME_REASONS+=("$_reason")
            _idx=$((${#DETECTED_GAME_PATHS[@]} - 1))
            _bestIdxByPath["$_dedupeKey"]=$_idx
        done
    done < <(listSteamAppsDirs)
}

# Prompt user for a game path manually (GUI or CLI).
function promptGamePathManual() {
    if [[ $_GUI -eq 1 ]]; then
        local _startDir="$HOME/.local/share/Steam/steamapps/common"
        [[ ! -d $_startDir ]] && _startDir="$HOME"
        while true; do
            gamePath=$(yad --file --directory \
                --title="ReShade — Select the game folder" \
                --filename="$_startDir/" \
                --width=750 --height=520 2>/dev/null)
            if [[ -z $gamePath ]]; then
                yad --question --title="ReShade" --width=360 \
                    --text="No folder selected.\nExit the script?" 2>/dev/null \
                    && exit 0
                continue
            fi
            gamePath=$(realpath "$gamePath" 2>/dev/null)
            [[ -f $gamePath ]] && gamePath=$(dirname "$gamePath")
            if [[ -z $gamePath || ! -d $gamePath ]]; then
                yad --warning --title="ReShade" --width=420 \
                    --text="Path does not exist:\n<tt>$gamePath</tt>" \
                    --button="Try again:1" 2>/dev/null
                continue
            fi
            if ! compgen -G "$gamePath/*.exe" &>/dev/null; then
                yad --question --title="ReShade" --width=520 \
                    --text="No .exe file found in:\n<tt>$gamePath</tt>\n\nUse this folder anyway?" \
                    2>/dev/null || { _startDir="$gamePath"; continue; }
            fi
            break
        done
        return
    fi
    printf '%bSupply the folder path where the main executable (.exe) for the game is.%b\n' "$_CYN" "$_R"
    printf '%b(Control+C to exit)%b\n' "$_YLW" "$_R"
    while true; do
        read -rp "$(printf '%bGame path: %b' "$_YLW" "$_R")" gamePath
        gamePath="${gamePath/#\~/$HOME}"
        gamePath=$(realpath "$gamePath" 2>/dev/null)
        [[ -f $gamePath ]] && gamePath=$(dirname "$gamePath")
        if [[ -z $gamePath || ! -d $gamePath ]]; then
            printf '%bIncorrect or empty path supplied. You supplied "%s".%b\n' "$_YLW" "$gamePath" "$_R"
            continue
        fi
        if ! compgen -G "$gamePath/*.exe" &>/dev/null; then
            printf '%bNo .exe file found in "%s".%b\n' "$_YLW" "$gamePath" "$_R"
            printf '%bDo you still want to use this directory?%b\n' "$_YLW" "$_R"
            [[ $(checkStdin "(y/n) " "^(y|n)$") != "y" ]] && continue
        fi
        echo "Is this path correct? \"$gamePath\""
        [[ $(checkStdin "(y/n) " "^(y|n)$") == "y" ]] && break
    done
}

# Try to get game directory from user, preferring auto-detected Steam games.
function getGamePath() {
    detectSteamGames
    if [[ ${#DETECTED_GAME_PATHS[@]} -eq 0 ]]; then
        promptGamePathManual
        return
    fi

    if [[ $_GUI -eq 1 ]]; then
        local _pick _i _iconTmpDir="" _scaledIcon _statusName
        local _cacheDir="${XDG_CACHE_HOME:-$HOME/.cache}/reshade-linux/icons"
        mkdir -p "$_cacheDir" 2>/dev/null

        # Download missing icons from the Steam CDN in parallel (cached for future runs).
        for ((_i=0; _i<${#DETECTED_GAME_PATHS[@]}; _i++)); do
            [[ -n ${DETECTED_GAME_ICONS[_i]} ]] && continue
            curl --silent --fail --max-time 8 \
                -o "$_cacheDir/${DETECTED_GAME_APPIDS[_i]}.jpg" \
                "https://cdn.steamstatic.com/steam/apps/${DETECTED_GAME_APPIDS[_i]}/header.jpg" \
                2>/dev/null &
        done
        wait
        # Fill in paths for games that now have a freshly downloaded icon.
        for ((_i=0; _i<${#DETECTED_GAME_PATHS[@]}; _i++)); do
            [[ -n ${DETECTED_GAME_ICONS[_i]} ]] && continue
            local _f="$_cacheDir/${DETECTED_GAME_APPIDS[_i]}.jpg"
            [[ -f $_f ]] && DETECTED_GAME_ICONS[_i]="$_f"
        done

        # Pre-scale icons to 48x48 so they don't fill entire rows in the list.
        if command -v magick &>/dev/null; then
            _iconTmpDir=$(mktemp -d)
        fi
        local _args=(
            --list --no-click
            --title "ReShade — Select Game"
            --text "Detected installed Steam games. Choose one, or select manual path. ✔ = ReShade already installed."
            --column "Icon:IMG" --column "Game" --column "AppID" --column "Executable" --column "Install directory" --column "Detected by"
            --print-column=5 --search-column=2 --separator ""
            --width=1100 --height=560
        )
        for ((_i=0; _i<${#DETECTED_GAME_PATHS[@]}; _i++)); do
            _scaledIcon="${DETECTED_GAME_ICONS[_i]}"
            if [[ -n $_iconTmpDir && -n $_scaledIcon ]]; then
                magick "$_scaledIcon" -resize 48x48\> "$_iconTmpDir/$_i.png" 2>/dev/null \
                    && _scaledIcon="$_iconTmpDir/$_i.png"
            fi
            _statusName="${DETECTED_GAME_NAMES[_i]}"
            [[ -f "$MAIN_PATH/game-state/${DETECTED_GAME_APPIDS[_i]}.state" ]] \
                && _statusName="✔ $_statusName"
            _args+=("$_scaledIcon" "$_statusName" "${DETECTED_GAME_APPIDS[_i]}" "${DETECTED_GAME_EXES[_i]}" "${DETECTED_GAME_PATHS[_i]}" "${DETECTED_GAME_REASONS[_i]}")
        done
        _args+=("" "Manual path..." "-" "-" "MANUAL" "manual")
        _pick=$(yad "${_args[@]}" 2>/dev/null)
        local _yadExit=$?
        [[ -n $_iconTmpDir ]] && rm -rf "$_iconTmpDir"
        [[ $_yadExit -ne 0 ]] && exit 0
        if [[ $_pick == "MANUAL" ]]; then
            _selectedAppId=""
            promptGamePathManual
        else
            gamePath="$_pick"
            _selectedAppId=""
            for ((_i=0; _i<${#DETECTED_GAME_PATHS[@]}; _i++)); do
                if [[ "${DETECTED_GAME_PATHS[_i]}" == "$gamePath" ]]; then
                    _selectedAppId="${DETECTED_GAME_APPIDS[_i]}"
                    break
                fi
            done
            printf '%bSelected auto-detected game path:%b %s\n' "$_GRN" "$_R" "$gamePath"
        fi
        return
    fi

    local _i _choice _maxShow=25 _statusLabel
    printf '%bDetected Steam games on this system:%b\n' "$_CYN$_B" "$_R"
    for ((_i=0; _i<${#DETECTED_GAME_PATHS[@]} && _i<_maxShow; _i++)); do
        _statusLabel="${DETECTED_GAME_NAMES[_i]}"
        [[ -f "$MAIN_PATH/game-state/${DETECTED_GAME_APPIDS[_i]}.state" ]] \
            && _statusLabel+="  [ReShade installed]"
        printf '  %2d) %s (AppID %s)\n      exe: %s\n      -> %s\n' \
            "$((_i+1))" "$_statusLabel" "${DETECTED_GAME_APPIDS[_i]}" "${DETECTED_GAME_EXES[_i]}" "${DETECTED_GAME_PATHS[_i]}"
    done
    if [[ ${#DETECTED_GAME_PATHS[@]} -gt $_maxShow ]]; then
        printf '  ... showing first %d of %d detected games\n' "$_maxShow" "${#DETECTED_GAME_PATHS[@]}"
    fi
    printf '   m) Enter path manually\n'

    while true; do
        read -rp "$(printf '%bChoose game number or m: %b' "$_YLW" "$_R")" _choice
        if [[ $_choice =~ ^[mM]$ ]]; then
            _selectedAppId=""
            promptGamePathManual
            return
        fi
        if [[ $_choice =~ ^[0-9]+$ ]] && (( _choice >= 1 && _choice <= ${#DETECTED_GAME_PATHS[@]} )); then
            gamePath="${DETECTED_GAME_PATHS[$((_choice-1))]}"
            _selectedAppId="${DETECTED_GAME_APPIDS[$((_choice-1))]}"
            printf '%bSelected auto-detected game path:%b %s\n' "$_GRN" "$_R" "$gamePath"
            return
        fi
    done
}

# Remove / create temporary directory.
function createTempDir() {
    tmpDir=$(mktemp -d)
    cd "$tmpDir" || printErr "Failed to create temp directory."
}
function removeTempDir() {
    cd "$MAIN_PATH" || exit
    [[ -d $tmpDir ]] && rm -rf "$tmpDir"
}

# Downloads d3dcompiler_47.dll files.
# Sources from mozilla/fxc2 GitHub, same source used by Winetricks.
function downloadD3dcompiler_47() {
    ! [[ $1 =~ ^(32|64)$ ]] && printErr "(downloadD3dcompiler_47): Wrong system architecture."
    [[ -f $MAIN_PATH/d3dcompiler_47.dll.$1 ]] && return
    printf '%bDownloading d3dcompiler_47.dll (%s-bit)...%b\n' "$_GRN" "$1" "$_R"
    createTempDir
    if [[ $1 -eq 32 ]]; then
        local url="https://raw.githubusercontent.com/mozilla/fxc2/master/dll/d3dcompiler_47_32.dll"
        local hash="2ad0d4987fc4624566b190e747c9d95038443956ed816abfd1e2d389b5ec0851"
    else
        local url="https://raw.githubusercontent.com/mozilla/fxc2/master/dll/d3dcompiler_47.dll"
        local hash="4432bbd1a390874f3f0a503d45cc48d346abc3a8c0213c289f4b615bf0ee84f3"
    fi
    curl --fail "${_CURL_PROG[@]}" -Lo d3dcompiler_47.dll "$url" \
        || printErr "(downloadD3dcompiler_47) Could not download d3dcompiler_47.dll."
    local dlhash _
    read -r dlhash _ < <(sha256sum d3dcompiler_47.dll)
    [[ "$dlhash" != "$hash" ]] && printErr "(downloadD3dcompiler_47) Integrity check failed. (Expected: $hash ; Calculated: $dlhash)"
    cp d3dcompiler_47.dll "$MAIN_PATH/d3dcompiler_47.dll.$1" || printErr "(downloadD3dcompiler_47) Unable to copy d3dcompiler_47.dll to $MAIN_PATH"
    removeTempDir
}

# Download / extract ReShade from specified link.
# $1 => Version of ReShade
# $2 -> Full URL of ReShade exe, ex.: https://reshade.me/downloads/ReShade_Setup_5.0.2.exe
function downloadReshade() {
    createTempDir
    curl --fail "${_CURL_PROG[@]}" -LO "$2" || printErr "Could not download version $1 of ReShade."
    exeFile="${2##*/}"
    ! [[ -f $exeFile ]] && printErr "Download of ReShade exe file failed."
    file "$exeFile" | grep -q executable || printErr "The ReShade exe file is not an executable file, does the ReShade version exist?"
    7z -y e "$exeFile" 1> /dev/null || printErr "Failed to extract ReShade using 7z."
    rm -f "$exeFile"
    resCurPath="$RESHADE_PATH/$1"
    [[ -e $resCurPath ]] && rm -rf "$resCurPath"
    mkdir -p "$resCurPath"
    mv ./* "$resCurPath"
    removeTempDir
}

# Link d3dcompiler_47.dll into the Wine/Proton prefix system32 or syswow64 directory.
# Since ReShade 6.5+, the DLL must exist there for shaders to compile correctly.
# $1 is the exe architecture (32 or 64).
function linkD3dcompilerToWineprefix() {
    [[ -z $WINEPREFIX ]] && return
    local arch="$1"
    local sysDir
    # 32-bit libraries go into syswow64 in a 64-bit prefix; 64-bit go into system32.
    if [[ $arch -eq 32 ]] && [[ -d "$WINEPREFIX/drive_c/windows/syswow64" ]]; then
        sysDir="$WINEPREFIX/drive_c/windows/syswow64"
    else
        sysDir="$WINEPREFIX/drive_c/windows/system32"
    fi
    if [[ ! -d $sysDir ]]; then
        printf '%bWarning: Wine prefix directory '"'"'%s'"'"' not found -- skipping system32 d3dcompiler_47.dll install.%b\n' "$_YLW" "$sysDir" "$_R"
        return
    fi
    printf '%bLinking d3dcompiler_47.dll into %b%s%b (required for ReShade 6.5+).%b\n' "$_GRN" "$_CYN" "$sysDir" "$_GRN" "$_R"
    [[ -L "$sysDir/d3dcompiler_47.dll" ]] && unlink "$sysDir/d3dcompiler_47.dll"
    ln -is "$(realpath "$MAIN_PATH/d3dcompiler_47.dll.$arch")" "$sysDir/d3dcompiler_47.dll"
}

SEPARATOR="------------------------------------------------------------------------------------------------"
SCRIPT_VERSION="1.1.0"
# ANSI color helpers — used via printf '%b' throughout the script.
_R=$'\e[0m'    # reset
_B=$'\e[1m'    # bold
_RED=$'\e[31m' # red   (errors)
_GRN=$'\e[32m' # green (success / info)
_YLW=$'\e[33m' # yellow (warnings / prompts)
_CYN=$'\e[36m' # cyan  (section headers)
# GUI mode: use yad dialogs when a display server and yad are both available.
_GUI=0
[[ -n ${DISPLAY:-}${WAYLAND_DISPLAY:-} ]] && command -v yad &>/dev/null && _GUI=1
# Curl progress flag: visible progress bar in CLI; silent in GUI (yad shows its own indicator).
_CURL_PROG=(--progress-bar)
[[ $_GUI -eq 1 ]] && _CURL_PROG=(--silent)
COMMON_OVERRIDES="d3d8 d3d9 d3d11 d3d12 ddraw dinput8 dxgi opengl32"
REQUIRED_EXECUTABLES=(7z curl file git grep sed sha256sum)
XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
# Auto-detect Flatpak vs native Steam when MAIN_PATH is not explicitly set by user.
if [[ -z ${MAIN_PATH+x} ]]; then
    _flatpak_data="$HOME/.var/app/com.valvesoftware.Steam/.local/share"
    _flatpak_ok=0; _native_ok=0
    [[ -d "$_flatpak_data/Steam" ]] && _flatpak_ok=1
    [[ -d "$XDG_DATA_HOME/Steam" ]] && _native_ok=1
    if [[ $_flatpak_ok -eq 1 && $_native_ok -eq 0 ]]; then
        MAIN_PATH="$_flatpak_data/reshade"
        printf '%bDetected Flatpak Steam — using Flatpak data dir for MAIN_PATH.%b\n' "$_CYN" "$_R"
    elif [[ $_flatpak_ok -eq 1 && $_native_ok -eq 1 ]]; then
        if [[ $_GUI -eq 1 ]]; then
            _fpChoice=$(yad --list --radiolist \
                --title="ReShade" \
                --text="Both Flatpak and native Steam installs were detected.\nWhich installation should ReShade target?" \
                --column="" --column="Installation" --column="Path" \
                --print-column=2 --separator="" \
                --width=650 --height=220 \
                TRUE "Flatpak Steam" "$_flatpak_data/reshade" \
                FALSE "Native Steam" "$XDG_DATA_HOME/reshade" 2>/dev/null) || exit 0
            [[ $_fpChoice == *"Flatpak"* ]] \
                && MAIN_PATH="$_flatpak_data/reshade" \
                || MAIN_PATH="$XDG_DATA_HOME/reshade"
        else
            printf '%bBoth Flatpak and native Steam installs detected.%b\n' "$_YLW$_B" "$_R"
            printf '  1) Flatpak Steam  → %s/reshade\n' "$_flatpak_data"
            printf '  2) Native Steam   → %s/reshade\n' "$XDG_DATA_HOME"
            if [[ $(checkStdin "Which installation? (1/2): " "^(1|2)$") == "1" ]]; then
                MAIN_PATH="$_flatpak_data/reshade"
            else
                MAIN_PATH="$XDG_DATA_HOME/reshade"
            fi
        fi
    else
        MAIN_PATH="$XDG_DATA_HOME/reshade"
    fi
    unset _flatpak_data _flatpak_ok _native_ok
fi
RESHADE_PATH="$MAIN_PATH/reshade"
# Strip the leading /home/$USER/ then convert forward slashes to double-backslashes
# for use in Wine registry paths — done with pure bash, no external commands.
_tmp_path="${MAIN_PATH#/home/"$USER"/}"
WINE_MAIN_PATH="${_tmp_path//\//\\\\}"
unset _tmp_path
UPDATE_RESHADE=${UPDATE_RESHADE:-1}
MERGE_SHADERS=${MERGE_SHADERS:-1}
VULKAN_SUPPORT=${VULKAN_SUPPORT:-0}
GLOBAL_INI=${GLOBAL_INI:-"ReShade.ini"}
SHADER_REPOS=${SHADER_REPOS:-"https://github.com/CeeJayDK/SweetFX|sweetfx-shaders;https://github.com/martymcmodding/iMMERSE|immerse-shaders;https://github.com/BlueSkyDefender/AstrayFX|astrayfx-shaders;https://github.com/prod80/prod80-ReShade-Repository|prod80-shaders;https://github.com/crosire/reshade-shaders|reshade-shaders|slim;https://github.com/Fubaxiusz/fubax-shaders|fubax-shaders"}
RESHADE_VERSION=${RESHADE_VERSION:-"latest"}
RESHADE_ADDON_SUPPORT=${RESHADE_ADDON_SUPPORT:-0}
FORCE_RESHADE_UPDATE_CHECK=${FORCE_RESHADE_UPDATE_CHECK:-0}
RESHADE_URL="https://reshade.me"
RESHADE_URL_ALT="https://static.reshade.me"
WINEPREFIX=${WINEPREFIX:-""}
# Built-in install-dir presets for known titles where launch executables
# are often not in the game root. User GAME_DIR_PRESETS overrides these.
BUILTIN_GAME_DIR_PRESETS="1091500|bin/x64;292030|bin/x64;275850|Binaries;1245620|Game;306130|The Elder Scrolls Online/game/client;2623190|OblivionRemastered/Binaries/Win64"

# Parse command-line arguments.
_BATCH_UPDATE=0
for _arg in "$@"; do
    case "$_arg" in
        --update-all) _BATCH_UPDATE=1 ;;
        --help|-h)
            printf 'Usage: %s [--update-all]\n' "$0"
            printf '  --update-all  Re-link ReShade for all previously installed games (non-interactive).\n'
            exit 0 ;;
    esac
done

for REQUIRED_EXECUTABLE in "${REQUIRED_EXECUTABLES[@]}"; do
    if ! command -v "$REQUIRED_EXECUTABLE" &>/dev/null; then
        printf "Program '%s' is missing, but it is required.\n" "$REQUIRED_EXECUTABLE"
        # Suggest a package name and the correct package manager for this distro.
        case "$REQUIRED_EXECUTABLE" in
            7z)   _pkg="p7zip-full" ;; # Fedora/Arch: p7zip
            curl) _pkg="curl" ;;
            file) _pkg="file" ;;
            git)  _pkg="git" ;;
            grep)      _pkg="grep" ;;
            sed)       _pkg="sed" ;;
            sha256sum) _pkg="coreutils" ;;
            *)         _pkg="$REQUIRED_EXECUTABLE" ;;
        esac
        if   command -v apt-get &>/dev/null; then printf '  Install with:  sudo apt-get install %s\n' "$_pkg"
        elif command -v dnf     &>/dev/null; then printf '  Install with:  sudo dnf install %s\n'     "$_pkg"
        elif command -v pacman  &>/dev/null; then printf '  Install with:  sudo pacman -S %s\n'       "$_pkg"
        elif command -v zypper  &>/dev/null; then printf '  Install with:  sudo zypper install %s\n'  "$_pkg"
        fi
        unset _pkg
        printf 'Exiting.\n'
        exit 1
    fi
done

# Z0000 Create MAIN_PATH
# Z0005 Check if update enabled.
# Z0010 Download / update shaders.
# Z0015 Download / update latest ReShade version.
# Z0016 Download version of ReShade specified by user.
# Z0020 Process GLOBAL_INI.
# Z0025 Vulkan install / uninstall.
# Z0030 DirectX / OpenGL uninstall.
# Z0035 DirectX / OpenGL find correct ReShade DLL.
# Z0040 Download d3dcompiler_47.dll.
# Z0045 DirectX / OpenGL link files to game directory.

# Z0000
mkdir -p "$MAIN_PATH" || printErr "Unable to create directory '$MAIN_PATH'."
cd "$MAIN_PATH" || exit
# Z0000

mkdir -p "$RESHADE_PATH"
mkdir -p "$MAIN_PATH/ReShade_shaders"
mkdir -p "$MAIN_PATH/External_shaders"

# Z0005
# Skip updating shaders / reshade if recently done (4 hours).
LASTUPDATED=0; [[ -f LASTUPDATED ]] && LASTUPDATED=$(< LASTUPDATED)
[[ ! $LASTUPDATED =~ ^[0-9]+$ ]] && LASTUPDATED=0
if [[ $LASTUPDATED -gt 0 && $(($(date +%s)-LASTUPDATED)) -lt 14400 ]]; then
    UPDATE_RESHADE=0
    _ago=$(( ($(date +%s) - LASTUPDATED) / 60 ))
    printf '%bSkipping update check (last checked %d min ago). Set FORCE_RESHADE_UPDATE_CHECK=1 to override.%b\n\n' \
        "$_YLW" "$_ago" "$_R"
    unset _ago
fi
[[ $UPDATE_RESHADE == 1 ]] && date +%s > LASTUPDATED
# Z0005

printf '%b%s\n  ReShade installer/updater for Linux games using Wine or Proton.\n  Version %s\n%s%b\n\n' \
    "$_CYN$_B" "$SEPARATOR" "$SCRIPT_VERSION" "$SEPARATOR" "$_R"

# Z0010
# Link Shader / Texture files from an input directory to an output directory if the link doesn't already exist.
# $1 is the input directory (full path).
# $2 is the output directory name (Textures / Shaders), with optional subdirectory.
function linkShaderFiles() {
    [[ ! -d $1 ]] && return
    cd "$1" || return
    for file in *; do
        [[ ! -f $file ]] && continue
        [[ -L "$MAIN_PATH/ReShade_shaders/Merged/$2/$file" ]] && continue
        INFILE="$(realpath "$1/$file")"
        OUTDIR="$(realpath "$MAIN_PATH/ReShade_shaders/Merged/$2/")"
        [[ ! -d $OUTDIR ]] && mkdir -p "$OUTDIR"
        echo "Linking $INFILE to $OUTDIR"
        ln -s "$INFILE" "$OUTDIR"
    done
}
# Check ReShade_shaders or External_shaders directories for directories to link to the Merged folder.
# $1 ReShade_shaders | External_shaders
# $2 Optional: Repo name
function mergeShaderDirs() {
    [[ $1 != ReShade_shaders && $1 != External_shaders ]] && return
    for dirName in Shaders Textures; do
        [[ $1 == "ReShade_shaders" ]] && dirPath=$(find "$MAIN_PATH/$1/$2" ! -path . -type d -name "$dirName") || dirPath="$MAIN_PATH/$1/$dirName"
        linkShaderFiles "$dirPath" "$dirName"
        # Check if there are any extra directories inside the Shaders or Texture folder, and link them.
        while IFS= read -rd '' anyDir; do
            linkShaderFiles "$dirPath/$anyDir" "$dirName/$anyDir"
        done < <(find . ! -path . -type d -print0)
    done
}
if [[ -n $SHADER_REPOS ]]; then
    printStep "Checking for shader updates"
    [[ $REBUILD_MERGE == 1 ]] && rm -rf "$MAIN_PATH/ReShade_shaders/Merged/"
    [[ $MERGE_SHADERS == 1 ]] && mkdir -p "$MAIN_PATH/ReShade_shaders/Merged/Shaders" &&  mkdir -p "$MAIN_PATH/ReShade_shaders/Merged/Textures"
    IFS=';' read -ra _shaderRepos <<< "$SHADER_REPOS"
    for _repoEntry in "${_shaderRepos[@]}"; do
        IFS='|' read -r URI localRepoName branchName <<< "$_repoEntry"
        if [[ -d "$MAIN_PATH/ReShade_shaders/$localRepoName" ]]; then
            if [[ $UPDATE_RESHADE -eq 1 ]]; then
                cd "$MAIN_PATH/ReShade_shaders/$localRepoName" || continue
                printf '%bUpdating shader repo:%b %s\n' "$_GRN" "$_R" "$URI"
                withProgress "Updating shader repo:\n<tt>$URI</tt>" \
                    git pull --ff-only \
                    || printf '%bCould not update shader repo: %s%b\n' "$_YLW" "$URI" "$_R"
            fi
        else
            cd "$MAIN_PATH/ReShade_shaders" || exit
            branchArgs=()
            [[ -n $branchName ]] && branchArgs=(--branch "$branchName" --single-branch)
            printf '%bCloning shader repo:%b %s\n' "$_GRN" "$_R" "$URI"
            withProgress "Cloning shader repo:\n<tt>$URI</tt>" \
                git clone --depth 1 "${branchArgs[@]}" "$URI" "$localRepoName" \
                || printf '%bCould not clone shader repo: %s%b\n' "$_YLW" "$URI" "$_R"
        fi
        [[ $MERGE_SHADERS == 1 ]] && mergeShaderDirs "ReShade_shaders" "$localRepoName"
    done
    if [[ $MERGE_SHADERS == 1 ]] && [[ -d "$MAIN_PATH/External_shaders" ]]; then
        printStep "Checking for external shader updates"
        mergeShaderDirs "External_shaders"
        # Link loose files.
        cd "$MAIN_PATH/External_shaders" || exit 1
        for file in *; do
            [[ ! -f $file || -L "$MAIN_PATH/ReShade_shaders/Merged/Shaders/$file" ]] && continue
            INFILE="$(realpath "$MAIN_PATH/External_shaders/$file")"
            OUTDIR="$MAIN_PATH/ReShade_shaders/Merged/Shaders/"
            echo "Linking $INFILE to $OUTDIR"
            ln -s "$INFILE" "$OUTDIR"
        done
    fi
fi
echo "$SEPARATOR"
# Z0010

# Z0015
cd "$MAIN_PATH" || exit
LVERS=0; [[ -f LVERS ]] && LVERS=$(< LVERS)
if [[ $RESHADE_VERSION == latest ]]; then
    # Check if user wants reshade without addon support and we're currently using reshade with addon support.
    [[ $LVERS =~ Addon && $RESHADE_ADDON_SUPPORT -eq 0 ]] && UPDATE_RESHADE=1
    # Check if user wants reshade with addon support and we're not currently using reshade with addon support.
    [[ ! $LVERS =~ Addon ]] && [[ $RESHADE_ADDON_SUPPORT -eq 1 ]] && UPDATE_RESHADE=1
fi
if [[ $FORCE_RESHADE_UPDATE_CHECK -eq 1 ]] || [[ $UPDATE_RESHADE -eq 1 ]] || [[ ! -e reshade/latest/ReShade64.dll ]] || [[ ! -e reshade/latest/ReShade32.dll ]]; then
    printStep "Checking for ReShade updates"
    ALT_URL=0
    if ! RHTML=$(curl --fail --max-time 10 -sL "$RESHADE_URL") || [[ $RHTML == *'<h2>Something went wrong.</h2>'* ]]; then
        ALT_URL=1
        echo "Error: Failed to connect to '$RESHADE_URL' after 10 seconds. Trying to connect to '$RESHADE_URL_ALT'."
        RHTML=$(curl --fail -sL "$RESHADE_URL_ALT") || echo "Error: Failed to connect to '$RESHADE_URL_ALT'."
    fi
    [[ $RESHADE_ADDON_SUPPORT -eq 1 ]] && VREGEX="[0-9][0-9.]*[0-9]_Addon" || VREGEX="[0-9][0-9.]*[0-9]"
    RLINK="$(grep -o "/downloads/ReShade_Setup_${VREGEX}\.exe" <<< "$RHTML" | head -n1)"
    [[ $RLINK == "" ]] && printErr "Could not fetch ReShade version."
    [[ $ALT_URL -eq 1 ]] && RLINK="${RESHADE_URL_ALT}${RLINK}" || RLINK="${RESHADE_URL}${RLINK}"
    RVERS=$(grep -o "$VREGEX" <<< "$RLINK")
    if [[ $RVERS != "$LVERS" ]]; then
        [[ -L $RESHADE_PATH/latest ]] && unlink "$RESHADE_PATH/latest"
        printf '%bUpdating ReShade to version %s...%b\n' "$_GRN" "$RVERS" "$_R"
        withProgress "Downloading ReShade $RVERS..." downloadReshade "$RVERS" "$RLINK"
        ln -is "$(realpath "$RESHADE_PATH/$RVERS")" "$(realpath "$RESHADE_PATH/latest")"
        echo "$RVERS" > LVERS
        LVERS="$RVERS"
        printf '%bReShade updated to %b%s%b.%b\n' "$_GRN" "$_CYN$_B" "$RVERS" "$_R$_GRN" "$_R"
    fi
fi
# Z0015

# Z0016
cd "$MAIN_PATH" || exit
if [[ $RESHADE_VERSION != latest ]]; then
    [[ $RESHADE_ADDON_SUPPORT -eq 1 ]] && RESHADE_VERSION="${RESHADE_VERSION}_Addon"
    if [[ ! -f reshade/$RESHADE_VERSION/ReShade64.dll ]] || [[ ! -f reshade/$RESHADE_VERSION/ReShade32.dll ]]; then
        printf 'Downloading version %s of ReShade.\n%s\n\n' "$RESHADE_VERSION" "$SEPARATOR"
        [[ -e reshade/$RESHADE_VERSION ]] && rm -rf "reshade/$RESHADE_VERSION"
        withProgress "Downloading ReShade $RESHADE_VERSION..." \
            downloadReshade "$RESHADE_VERSION" "$RESHADE_URL/downloads/ReShade_Setup_$RESHADE_VERSION.exe"
    fi
    printf '%bUsing ReShade version %b%s%b.%b\n\n' "$_GRN" "$_CYN$_B" "$RESHADE_VERSION" "$_R$_GRN" "$_R"
else
    printf '%bUsing the latest version of ReShade (%b%s%b).%b\n\n' "$_GRN" "$_CYN$_B" "$LVERS" "$_R$_GRN" "$_R"
fi
# Z0016

# Z0020
if [[ $GLOBAL_INI != 0 ]] && [[ $GLOBAL_INI == ReShade.ini ]] && [[ ! -f $MAIN_PATH/$GLOBAL_INI ]]; then
    cd "$MAIN_PATH" || exit
    curl --fail -sLO https://github.com/asafelobotomy/reshade-steam-proton/raw/ini/ReShade.ini
    if [[ -f ReShade.ini ]]; then
        if [[ $MERGE_SHADERS == 1 ]]; then
            sed -i \
                -e "s/_USERSED_/$USER/g" \
                -e "s#_SHADSED_#$WINE_MAIN_PATH\\\ReShade_shaders\\\Merged\\\Shaders#g" \
                -e "s#_TEXSED_#$WINE_MAIN_PATH\\\ReShade_shaders\\\Merged\\\Textures#g" \
                "$MAIN_PATH/$GLOBAL_INI"
        else
            sed -i "s/_USERSED_/$USER/g" "$MAIN_PATH/$GLOBAL_INI"
        fi
    fi
fi
# Z0020

# Z0025
# TODO Requires changes for ReShade 5.0 ; paths and json files are different.
# See https://github.com/asafelobotomy/reshade-steam-proton/issues/6#issuecomment-1027230967
if [[ $VULKAN_SUPPORT == 1 ]]; then
    _useVulkan="n"
    if [[ $_GUI -eq 1 ]]; then
        yad --question --title="ReShade" --width=420 \
            --text="Does this game use the <b>Vulkan API</b>?" 2>/dev/null \
            && _useVulkan="y"
    else
        echo "Does the game use the Vulkan API?"
        _useVulkan=$(checkStdin "(y/n): " "^(y|n)$")
    fi
    if [[ $_useVulkan == "y" ]]; then
        # --- WINEPREFIX ---
        if [[ $_GUI -eq 1 ]]; then
            _startDir="$HOME/.local/share/Steam/steamapps/compatdata"
            [[ ! -d $_startDir ]] && _startDir="$HOME"
            while true; do
                WINEPREFIX=$(yad --file --directory \
                    --title="ReShade — Select WINEPREFIX folder" \
                    --filename="$_startDir/" \
                    --width=750 --height=520 2>/dev/null)
                [[ -z $WINEPREFIX ]] && exit 0
                WINEPREFIX=$(realpath "$WINEPREFIX" 2>/dev/null)
                [[ -d $WINEPREFIX ]] && break
                yad --warning --title="ReShade" --width=420 \
                    --text="Path does not exist:\n<tt>$WINEPREFIX</tt>" \
                    --button="Try again:1" 2>/dev/null
            done
        else
            printf '%bSupply the WINEPREFIX path for the game.%b\n' "$_CYN" "$_R"
            printf '%b(Control+C to exit)%b\n' "$_YLW" "$_R"
            while true; do
                read -rp "$(printf '%bWINEPREFIX path: %b' "$_YLW" "$_R")" WINEPREFIX
                # Expand leading ~ without using eval (safe tilde expansion).
                WINEPREFIX="${WINEPREFIX/#\~/$HOME}"
                WINEPREFIX=$(realpath "$WINEPREFIX" 2>/dev/null)
                if [[ -z $WINEPREFIX || ! -d $WINEPREFIX ]]; then
                    printf '%bIncorrect or empty path supplied. You supplied "%s".%b\n' "$_YLW" "$WINEPREFIX" "$_R"
                    continue
                fi
                printf '%bIs this path correct? "%s"%b\n' "$_YLW" "$WINEPREFIX" "$_R"
                [[ $(checkStdin "(y/n) " "^(y|n)$") == "y" ]] && break
            done
        fi
        # --- Architecture ---
        if [[ $_GUI -eq 1 ]]; then
            _archPick=$(yad --list --radiolist \
                --title="ReShade" --text="Select the game's EXE architecture:" \
                --column="" --column="Architecture" \
                --print-column=2 --separator="" \
                --width=400 --height=220 \
                TRUE "64-bit" FALSE "32-bit" 2>/dev/null) || exit 0
            [[ $_archPick == *"32"* ]] && exeArch=32 || exeArch=64
        else
            echo "Specify if the game's EXE file architecture is 32 or 64 bits:"
            [[ $(checkStdin "(32/64) " "^(32|64)$") == 64 ]] && exeArch=64 || exeArch=32
        fi
        export WINEPREFIX="$WINEPREFIX"
        # --- Install / Uninstall ---
        _vulkanAction="i"
        if [[ $_GUI -eq 1 ]]; then
            _vPick=$(yad --list --radiolist \
                --title="ReShade" --text="Install or uninstall Vulkan ReShade?" \
                --column="" --column="Action" \
                --print-column=2 --separator="" \
                --width=420 --height=220 \
                TRUE "Install" FALSE "Uninstall" 2>/dev/null) || exit 0
            [[ $_vPick == *"Uninstall"* ]] && _vulkanAction="u"
        else
            echo "Do you want to (i)nstall or (u)ninstall ReShade?"
            _vulkanAction=$(checkStdin "(i/u): " "^(i|u)$")
        fi
        if [[ $_vulkanAction == "i" ]]; then
            wine reg ADD HKLM\\SOFTWARE\\Khronos\\Vulkan\\ImplicitLayers /d 0 /t REG_DWORD /v "Z:\\home\\$USER\\$WINE_MAIN_PATH\\reshade\\$RESHADE_VERSION\\ReShade$exeArch.json" -f /reg:"$exeArch" \
                && echo "Done." || echo "An error has occurred."
        else
            wine reg DELETE HKLM\\SOFTWARE\\Khronos\\Vulkan\\ImplicitLayers -f /reg:"$exeArch" \
                && echo "Done." || echo "An error has occurred."
        fi
        exit 0
    fi
fi
# Z0025

# Z0030
_action="i"
if [[ $_GUI -eq 1 ]]; then
    _pick=$(yad --list --radiolist \
        --title="ReShade" \
        --text="What would you like to do?" \
        --column="" --column="Action" \
        --print-column=2 --separator="" \
        --width=480 --height=230 \
        TRUE "Install ReShade for a game" \
        FALSE "Uninstall ReShade for a game" 2>/dev/null) || exit 0
    [[ $_pick == *"Uninstall"* ]] && _action="u"
else
    echo "Do you want to (i)nstall or (u)ninstall ReShade for a DirectX or OpenGL game?"
    _action=$(checkStdin "(i/u): " "^(i|u)$")
fi
if [[ $_action == "u" ]]; then
    getGamePath
    printf '%bUnlinking ReShade files from:%b %s\n' "$_GRN" "$_R" "$gamePath"
    # Build the DLL list from COMMON_OVERRIDES using bash string substitution
    # (replaces each space with ".dll ", then appends ".dll" to the last entry).
    LINKS="${COMMON_OVERRIDES// /.dll }.dll ReShade.ini ReShade32.json ReShade64.json d3dcompiler_47.dll Shaders Textures ReShade_shaders"
    [[ -n $LINK_PRESET ]] && LINKS="$LINKS $LINK_PRESET"
    for link in $LINKS; do
        if [[ -L $gamePath/$link ]]; then
            echo "Unlinking \"$gamePath/$link\"."
            unlink "$gamePath/$link"
        fi
    done
    if [[ $DELETE_RESHADE_FILES == 1 ]]; then
        echo "Deleting ReShade.log and ReShadePreset.ini"
        rm -f "$gamePath/ReShade.log" "$gamePath/ReShadePreset.ini"
    fi
    if [[ -n $WINEPREFIX ]]; then
        for sysDir in "$WINEPREFIX/drive_c/windows/system32" "$WINEPREFIX/drive_c/windows/syswow64"; do
            if [[ -L "$sysDir/d3dcompiler_47.dll" ]]; then
                echo "Unlinking d3dcompiler_47.dll from '$sysDir'."
                unlink "$sysDir/d3dcompiler_47.dll"
            fi
        done
    fi
    # Clean up state file on uninstall if it exists.
    if [[ -n $_selectedAppId && -f "$MAIN_PATH/game-state/$_selectedAppId.state" ]]; then
        rm -f "$MAIN_PATH/game-state/$_selectedAppId.state"
    fi
    printf '%bFinished uninstalling ReShade for:%b %s\n' "$_GRN$_B" "$_R" "$gamePath"
    printf '%bMake sure to remove or unset the %bWINEDLLOVERRIDES%b environment variable.%b\n' "$_GRN" "$_CYN$_B" "$_R$_GRN" "$_R"
    exit 0
fi
# Z0030

# Z0028 Batch update: re-link ReShade for all previously installed games.
if [[ $_BATCH_UPDATE -eq 1 ]]; then
    _stateDir="$MAIN_PATH/game-state"
    if [[ ! -d $_stateDir ]] || ! compgen -G "$_stateDir/*.state" &>/dev/null; then
        printf '%bNo installed games found in state store. Run without --update-all first.%b\n' "$_YLW" "$_R"
        exit 0
    fi
    _ok=0; _fail=0
    for _sf in "$_stateDir"/*.state; do
        _aid="${_sf##*/}"; _aid="${_aid%.state}"
        _dll=$(grep  '^dll='      "$_sf" | cut -d= -f2  | head -1)
        _arch=$(grep '^arch='     "$_sf" | cut -d= -f2  | head -1)
        _gp=$(grep   '^gamePath=' "$_sf" | cut -d= -f2- | head -1)
        if [[ ! -d $_gp ]]; then
            printf '%bSkipping AppID %s — game directory not found: %s%b\n' \
                "$_YLW" "$_aid" "$_gp" "$_R"
            (( _fail++ )); continue
        fi
        printf '%bUpdating AppID %s — %s (%s-bit, %s.dll)%b\n' \
            "$_GRN" "$_aid" "$_gp" "$_arch" "$_dll" "$_R"
        [[ -L "$_gp/$_dll.dll" ]] && unlink "$_gp/$_dll.dll"
        if [[ $_arch == 64 ]]; then
            ln -is "$(realpath "$RESHADE_PATH/$RESHADE_VERSION"/ReShade64.dll)" "$_gp/$_dll.dll"
        else
            ln -is "$(realpath "$RESHADE_PATH/$RESHADE_VERSION"/ReShade32.dll)" "$_gp/$_dll.dll"
        fi
        [[ -L "$_gp/d3dcompiler_47.dll" ]] && unlink "$_gp/d3dcompiler_47.dll"
        ln -is "$(realpath "$MAIN_PATH/d3dcompiler_47.dll.$_arch")" "$_gp/d3dcompiler_47.dll" 2>/dev/null
        [[ -L "$_gp/ReShade_shaders" ]] && unlink "$_gp/ReShade_shaders"
        ln -is "$(realpath "$MAIN_PATH/ReShade_shaders")" "$_gp/" 2>/dev/null
        if [[ $GLOBAL_INI != 0 && -f "$MAIN_PATH/$GLOBAL_INI" ]]; then
            [[ -L "$_gp/$GLOBAL_INI" ]] && unlink "$_gp/$GLOBAL_INI"
            ln -is "$(realpath "$MAIN_PATH/$GLOBAL_INI")" "$_gp/$GLOBAL_INI" 2>/dev/null
        fi
        (( _ok++ ))
    done
    printf '%bBatch update complete: %d game(s) updated, %d skipped.%b\n' \
        "$_GRN$_B" "$_ok" "$_fail" "$_R"
    exit 0
fi

# Z0035
_selectedAppId=""
getGamePath

# If this game was previously installed, skip the DLL dialog and reuse stored settings.
exeArch=32
wantedDll=""
_stateFile=""
[[ -n $_selectedAppId ]] && _stateFile="$MAIN_PATH/game-state/$_selectedAppId.state"
if [[ -f "$_stateFile" ]]; then
    _stored_dll=$(grep  '^dll='  "$_stateFile" | cut -d= -f2 | head -1)
    _stored_arch=$(grep '^arch=' "$_stateFile" | cut -d= -f2 | head -1)
    if [[ -n $_stored_dll && $_stored_arch =~ ^(32|64)$ ]]; then
        wantedDll="$_stored_dll"
        exeArch="$_stored_arch"
        printf '%bReusing stored settings for this game: %s-bit, %s.dll%b\n' \
            "$_GRN" "$exeArch" "$wantedDll" "$_R"
    fi
fi

if [[ -z $wantedDll ]]; then
    # Auto-detect architecture and DLL via PE import table analysis.
    _peResult=$(detectExeInfo "$gamePath")
    if [[ -n $_peResult ]]; then
        _pe_arch=$(grep '^arch=' <<< "$_peResult" | cut -d= -f2)
        _pe_dll=$(grep  '^dll='  <<< "$_peResult" | cut -d= -f2)
        [[ -n $_pe_arch ]] && exeArch="$_pe_arch"
        [[ -n $_pe_dll  ]] && wantedDll="$_pe_dll"
    fi
    # Fall back to simple file(1) heuristic if PE parsing produced no result.
    if [[ -z $wantedDll ]]; then
        for file in "$gamePath/"*.exe; do
            [[ -f $file ]] || continue
            if [[ $(file "$file" 2>/dev/null) =~ x86-64 ]]; then exeArch=64; break; fi
        done
        [[ $exeArch -eq 32 ]] && wantedDll="d3d9" || wantedDll="dxgi"
    fi
    # Confirm with the user; offer manual override.
    if [[ $_GUI -eq 1 ]]; then
        yad --question --title="ReShade" --width=520 \
            --text="Detected a <b>$exeArch-bit</b> game.\nUse <b>$wantedDll.dll</b> as the DLL override?\n\n<i>Click No to choose a different DLL manually.</i>" \
            2>/dev/null || wantedDll="manual"
    else
        printf '%bDetected %s-bit game — DLL override: %s.dll. Is this correct?%b\n' \
            "$_CYN" "$exeArch" "$wantedDll" "$_R"
        [[ $(checkStdin "(y/n) " "^(y|n)$") == "n" ]] && wantedDll="manual"
    fi
fi

if [[ $wantedDll == "manual" ]]; then
    if [[ $_GUI -eq 1 ]]; then
        while true; do
            wantedDll=$(yad --entry \
                --title="ReShade" \
                --text="Enter the DLL override for ReShade.\nCommon values: <b>$COMMON_OVERRIDES</b>" \
                --entry-text="dxgi" \
                --width=520 2>/dev/null) || exit 0
            wantedDll=${wantedDll//.dll/}
            [[ -n $wantedDll ]] && break
            yad --warning --title="ReShade" --width=360 \
                --text="Please enter a DLL name." --button="OK:1" 2>/dev/null
        done
    else
        printf '%bManually enter the dll override for ReShade.%b Common values: %b%s%b\n' "$_CYN" "$_R" "$_B" "$COMMON_OVERRIDES" "$_R"
        while true; do
            read -rp "$(printf '%bOverride: %b' "$_YLW" "$_R")" wantedDll
            wantedDll=${wantedDll//.dll/}
            printf '%bYou entered %b%s%b — is this correct?%b\n' "$_YLW" "$_CYN$_B" "$wantedDll" "$_R$_YLW" "$_R"
            read -rp "$(printf '%b(y/n): %b' "$_YLW" "$_R")" ynCheck
            [[ $ynCheck =~ ^(y|Y|yes|YES)$ ]] && break
        done
    fi
fi
# Z0035

# If WINEPREFIX was not set by the user or Vulkan path, try to auto-detect it
# from the game path when the game lives under a Steam steamapps/common/ tree.
if [[ -z $WINEPREFIX && $gamePath == */steamapps/common/* ]]; then
    _steamRoot="${gamePath%/steamapps/common/*}"
    _gameName="${gamePath##*/steamapps/common/}"
    _gameName="${_gameName%%/*}"
    # Locate the ACF manifest whose "installdir" matches this game folder name.
    _acf=""
    while IFS= read -r _f; do
        if grep -qF "\"$_gameName\"" "$_f" 2>/dev/null; then
            _acf="$_f"; break
        fi
    done < <(grep -rl '"installdir"' "$_steamRoot/steamapps/" 2>/dev/null)
    if [[ -n $_acf ]]; then
        _appid=$(grep -o '"appid"[[:space:]]*"[0-9]*"' "$_acf" 2>/dev/null \
            | grep -o '[0-9]*' | head -1)
        _pfx="$_steamRoot/steamapps/compatdata/$_appid/pfx"
        if [[ -n $_appid && -d $_pfx ]]; then
            export WINEPREFIX="$_pfx"
            printf '%bAuto-detected WINEPREFIX:%b %s\n' "$_GRN" "$_R" "$WINEPREFIX"
        fi
    fi
    unset _steamRoot _gameName _acf _appid _pfx
fi

# Z0040
withProgress "Downloading d3dcompiler_47.dll ($exeArch-bit)..." \
    downloadD3dcompiler_47 "$exeArch"
linkD3dcompilerToWineprefix "$exeArch"
# Z0040

# Z0045
printStep "Linking ReShade files to game directory"
[[ -L $gamePath/$wantedDll.dll ]] && unlink "$gamePath/$wantedDll.dll"
if [[ $exeArch == 32 ]]; then
    printf '%bLinking ReShade32.dll → %s.dll%b\n' "$_GRN" "$wantedDll" "$_R"
    ln -is "$(realpath "$RESHADE_PATH/$RESHADE_VERSION"/ReShade32.dll)" "$gamePath/$wantedDll.dll"
else
    printf '%bLinking ReShade64.dll → %s.dll%b\n' "$_GRN" "$wantedDll" "$_R"
    ln -is "$(realpath "$RESHADE_PATH/$RESHADE_VERSION"/ReShade64.dll)" "$gamePath/$wantedDll.dll"
fi
[[ -L $gamePath/d3dcompiler_47.dll ]] && unlink "$gamePath/d3dcompiler_47.dll"
ln -is "$(realpath "$MAIN_PATH/d3dcompiler_47.dll.$exeArch")" "$gamePath/d3dcompiler_47.dll"
[[ -L $gamePath/ReShade_shaders ]] && unlink "$gamePath/ReShade_shaders"
ln -is "$(realpath "$MAIN_PATH"/ReShade_shaders)" "$gamePath/"
if [[ $GLOBAL_INI != 0 ]] && [[ -f $MAIN_PATH/$GLOBAL_INI ]]; then
    [[ -L $gamePath/$GLOBAL_INI ]] && unlink "$gamePath/$GLOBAL_INI"
    ln -is "$(realpath "$MAIN_PATH/$GLOBAL_INI")" "$gamePath/$GLOBAL_INI"
fi
if [[ -f $MAIN_PATH/$LINK_PRESET ]]; then
    echo "Linking $LINK_PRESET to game directory."
    [[ -L $gamePath/$LINK_PRESET ]] && unlink "$gamePath/$LINK_PRESET"
    ln -is "$(realpath "$MAIN_PATH/$LINK_PRESET")" "$gamePath/$LINK_PRESET"
fi
# Z0045

# Persist installation details so future runs can skip the DLL dialog
# and the batch --update-all mode knows which games have ReShade.
writeGameState "$_selectedAppId" "$gamePath" "$wantedDll" "$exeArch"

gameEnvVar="WINEDLLOVERRIDES=\"d3dcompiler_47=n;$wantedDll=n,b\""

# Try to write the Steam launch option directly into localconfig.vdf.
_launchOpt="$gameEnvVar %command%"
_launchApplied=0
if [[ -n $_selectedAppId ]]; then
    if applyLaunchOption "$_selectedAppId" "$_launchOpt"; then
        _launchApplied=1
        printf '%bSteam launch option written automatically%b (restart Steam if already running).%b\n' \
            "$_GRN" "$_YLW" "$_R"
    fi
fi

# In GUI mode, also copy the Steam launch option to the clipboard if possible.
_clipNote=""
if [[ $_GUI -eq 1 ]]; then
    if [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v wl-copy &>/dev/null; then
        printf '%s' "$_launchOpt" | wl-copy 2>/dev/null \
            && _clipNote="\n\n<i>The Steam launch option has been copied to your clipboard.</i>"
    elif [[ -n ${DISPLAY:-} ]] && command -v xclip &>/dev/null; then
        printf '%s' "$_launchOpt" | xclip -selection clipboard 2>/dev/null \
            && _clipNote="\n\n<i>The Steam launch option has been copied to your clipboard.</i>"
    fi
    [[ $_launchApplied -eq 1 && -z $_clipNote ]] \
        && _clipNote="\n\n<i>Steam launch option applied automatically.</i>"
fi
unset _launchOpt

printf '%b%s\n  Done!\n%s%b\n' "$_GRN$_B" "$SEPARATOR" "$SEPARATOR" "$_R"
printf '\n%bSteam launch option%b (Game Properties → Launch Options):\n  %b%s %%command%%%b\n' \
    "$_GRN$_B" "$_R" "$_CYN$_B" "$gameEnvVar" "$_R"
printf '%bNon-Steam — run the game with:%b\n  %b%s%b\n' \
    "$_GRN$_B" "$_R" "$_CYN$_B" "$gameEnvVar" "$_R"
printf '\n%bReShade first-run setup:%b\n' "$_GRN$_B" "$_R"
printf '  In the ReShade overlay, open the %bSettings%b tab.\n' "$_B" "$_R"
printf '  Ensure shader/texture paths point inside: %b%s/ReShade_shaders/Merged/%b\n' \
    "$_CYN" "$MAIN_PATH" "$_R"
printf '  Then go to the %bHome%b tab and click %bReload%b.\n' "$_B" "$_R" "$_B" "$_R"
if [[ -z $WINEPREFIX ]]; then
    printf '\n%bNote:%b ReShade 6.5+ also requires d3dcompiler_47.dll inside the game'"'"'s Wine/Proton prefix.\n' "$_YLW$_B" "$_R"
    printf '  If shaders fail to compile, re-run the script with:\n'
    printf '  %bWINEPREFIX="%s/.local/share/Steam/steamapps/compatdata/<AppID>/pfx" %s%b\n' \
        "$_CYN" "$HOME" "$0" "$_R"
fi

if [[ $_GUI -eq 1 ]]; then
    _wineNote=""
    [[ -z $WINEPREFIX ]] && _wineNote="\n\n<b>Note:</b> ReShade 6.5+ also requires d3dcompiler_47.dll inside the game's Wine/Proton prefix. If shaders fail to compile, re-run with:\n<tt>WINEPREFIX=\"\$HOME/.local/share/Steam/steamapps/compatdata/&lt;AppID&gt;/pfx\" $0</tt>"
    yad --info \
        --title="ReShade — Done!" \
        --text="<b>ReShade installation complete!</b>

<b>Steam launch option</b> (Game Properties → Launch Options):
<tt>$gameEnvVar %command%</tt>

<b>Non-Steam — run the game with:</b>
<tt>$gameEnvVar</tt>

<b>ReShade first-run setup:</b>
In the ReShade overlay, open the <b>Settings</b> tab.
Ensure shader/texture paths point inside:
<tt>$MAIN_PATH/ReShade_shaders/Merged/</tt>
Then go to the <b>Home</b> tab and click <b>Reload</b>.$_wineNote$_clipNote" \
        --button="OK:0" --width=680 2>/dev/null
fi
