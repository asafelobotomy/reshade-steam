#!/bin/bash
# Test utilities and function definitions for reshade-linux automated testing
# This file extracts the core functions needed for testing without running the main install logic

# Requires: BUILTIN_GAME_DIR_PRESETS variable to be set

# ============================================================================
# CORE DETECTION FUNCTIONS (extracted from reshade-linux.sh)
# ============================================================================

function chooseUiBackend() {
    local _hasTty="${1:-0}"
    local _forced="${UI_BACKEND:-auto}"
    case $_forced in
        auto) ;;
        yad|whiptail|dialog|cli)
            printf '%s\n' "$_forced"
            return
            ;;
        *)
            return 1
            ;;
    esac
    if [[ $_hasTty -eq 1 ]]; then
        if command -v whiptail &>/dev/null; then
            printf 'whiptail\n'
            return
        fi
        if command -v dialog &>/dev/null; then
            printf 'dialog\n'
            return
        fi
    fi
    if [[ -n ${DISPLAY:-}${WAYLAND_DISPLAY:-} ]] && command -v yad &>/dev/null; then
        printf 'yad\n'
        return
    fi
    printf 'cli\n'
}

# Pick the most likely game executable from a directory.
# ReShade requires the ACTUAL game executable for DLL injection (via WINEDLLOVERRIDES).
# Filters out utilities (crash handlers, installers, etc.) and scores by name similarity to parent folder.
# Prints basename (or empty string if none found).
function pickBestExeInDir() {
    local _dir="$1" _parentDir _exe _name _lname _score _best="" _bestScore=-999999 _isUtility
    local _exeList=()
    
    _parentDir=$(basename "$_dir" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')
    
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
    _parentDir=$(basename "$_dir" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')

    [[ $_lname =~ (unityplayer|unitycrash|crashhandler|easyanticheat|battleye|asp|unins|uninstall|setup|installer|vcredist|redist|eac|crashreport|crashpad|benchmark|test|launcher|update|check|remov|error|consultant) ]] && _score=$((_score - 200))
    [[ $_lname =~ ^mono\. ]] && _score=$((_score - 200))
    [[ $_lname =~ debug ]] && _score=$((_score - 80))
    [[ "$_lname" == *"${_parentDir}"* ]] && _score=$((_score + 150))
    [[ $_lname =~ (game|main|app|engine|client|server|game_?setup) ]] && _score=$((_score + 80))
    [[ $_lname =~ (win64|x64|win32|i386|64|x86|ia32) ]] && _score=$((_score + 40))
    [[ $_lname =~ ^[a-z][a-z0-9]?$ || $_lname == "app.exe" ]] && _score=$((_score - 30))

    printf '%s\n' "$_score"
}

# Find a Steam game icon file.
# Returns path to icon file using 3-tier lookup priority:
#   1. Persistent cache (~/.cache/reshade-linux/icons/)
#   2. Local Steam cache (logo.png, hash-named jpg files, header.jpg)
#   3. Empty string if none found
function findSteamIconPath() {
    local _steamRoot="$1" _appId="$2"
    local _cacheDir="${XDG_CACHE_HOME:-$HOME/.cache}/reshade-linux/icons"
    local _libDir="$_steamRoot/appcache/librarycache/$_appId"
    local _file
    
    # Tier 1: Persistent cache (fastest)
    if [[ -d "$_cacheDir" ]]; then
        for _file in "$_cacheDir"/"$_appId".*; do
            [[ -f "$_file" ]] && { printf '%s\n' "$_file"; return; }
        done
    fi
    
    # Tier 2: Local Steam cache
    if [[ -d "$_libDir" ]]; then
        # Try logo.png first
        [[ -f "$_libDir/logo.png" ]] && { printf '%s\n' "$_libDir/logo.png"; return; }
        
        # Try hash-named jpg files (actual game icons, not banners)
        for _file in "$_libDir"/*.jpg; do
            [[ -f "$_file" ]] || continue
            basename "$_file" | grep -qE "^[a-f0-9]{40}\.jpg$" && \
                ! grep -q "library" <<< "$(basename "$_file")" && \
                { printf '%s\n' "$_file"; return; }
        done
        
        # Fall through to header.jpg
        [[ -f "$_libDir/header.jpg" ]] && { printf '%s\n' "$_libDir/header.jpg"; return; }
    fi
}

function parseShaderRepoEntry() {
    local _entry="$1"
    local _savedIFS="$IFS"
    IFS='|' read -r _shaderRepoUri _shaderRepoName _shaderRepoBranch _shaderRepoDesc <<< "$_entry"
    IFS="$_savedIFS"
    [[ -z $_shaderRepoDesc ]] && _shaderRepoDesc="$_shaderRepoUri"
}

# Return preset subdirectory for an AppID from BUILTIN_GAME_DIR_PRESETS.
function getBuiltInGameDirPreset() {
    local _appId="$1" _entry _k _v
    local IFS=";"
    for _entry in $BUILTIN_GAME_DIR_PRESETS; do
        _k=${_entry%%|*}
        _v=${_entry#*|}
        [[ $_k == "$_appId" ]] && { printf '%s\n' "$_v"; return; }
    done
}

# Resolve the preferred install directory for a Steam game root.
# Prints "<directory>|<reason>".
function resolveGameInstallDir() {
    local _root="$1" _appId="$2"
    local _preset _entry _k _v _candidate _exe _depth _score _best _bestScore=-999999 _name

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

    _preset=$(getBuiltInGameDirPreset "$_appId")
    if [[ -n $_preset ]] && [[ -d "$_root/$_preset" ]]; then
        printf '%s|%s\n' "$_root/$_preset" "builtin:$_preset"
        return
    fi

    for _candidate in \
        "Binaries/Win64" "Binaries/Win32" "Binaries" \
        "bin/x64" "bin/x86" "bin" \
        "Win64" "Win32" "x64" "x86" "."; do
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

    while IFS='|' read -r _depth _exe; do
        [[ -n $_exe ]] || continue
        _score=$((200 - _depth * 12))
        _name=${_exe##*/}
        _name=${_name,,}
        [[ $_name =~ (unins|uninstall|setup|installer|vcredist|redist|eac|easyanticheat|crashreport|crashpad|benchmark|remov|error|consultant) ]] && _score=$((_score - 100))
        [[ $_name =~ ^mono\. ]] && _score=$((_score - 100))
        [[ $_name =~ debug ]] && _score=$((_score - 50))
        [[ $_exe == */Mono/lib/* || $_exe == */Mono/bin/* || $_exe == */MonoBleedingEdge/* ]] && _score=$((_score - 300))
        [[ $_name =~ (shipping|game|win64|x64) ]] && _score=$((_score + 15))
        if [[ $_score -gt $_bestScore ]]; then
            _bestScore=$_score
            _best=$(dirname "$_exe")
        fi
    done < <(find "$_root" -maxdepth 5 -type f -iname '*.exe' -printf '%d|%p\n' 2>/dev/null)

    if [[ -n $_best && $_bestScore -ge 0 ]]; then
        printf '%s|%s\n' "$_best" "scan"
    else
        printf '%s|%s\n' "$_root" "root"
    fi
}

# Build a stable per-game install key.
function buildGameInstallKey() {
    local _aid="$1" _gp="$2"
    if [[ -n $_aid ]]; then
        printf '%s\n' "$_aid"
        return
    fi
    [[ -z $_gp ]] && return 1
    printf 'path-%s\n' "$(printf '%s' "$_gp" | sha256sum | cut -c1-16)"
}

# Persist game install state to $MAIN_PATH/game-state/<gameKey>.state.
# $1: gameKey  $2: gamePath  $3: dll  $4: arch  $5: selected_repos (comma-sep)  $6: appId(optional)
function writeGameState() {
    local _gameKey="$1" _gp="$2" _dll="$3" _arch="$4" _repos="$5" _appId="${6:-}"
    [[ -z $_gameKey ]] && return
    local _dir="$MAIN_PATH/game-state"
    mkdir -p "$_dir" 2>/dev/null || return
    printf 'dll=%s\narch=%s\ngamePath=%s\nselected_repos=%s\napp_id=%s\n' \
        "$_dll" "$_arch" "$_gp" "$_repos" "$_appId" > "$_dir/$_gameKey.state"
}

function getDefaultSelectedRepos() {
    local -a _names=()
    local _savedIFS="$IFS" _entry
    IFS=';' read -ra _allRepos <<< "$SHADER_REPOS"
    IFS="$_savedIFS"
    for _entry in "${_allRepos[@]}"; do
        parseShaderRepoEntry "$_entry"
        [[ -n $_shaderRepoName ]] && _names+=("$_shaderRepoName")
    done
    local IFS=','
    printf '%s\n' "${_names[*]}"
}

function readSelectedReposFromState() {
    local _stateFile="$1"
    [[ -f $_stateFile ]] || { getDefaultSelectedRepos; return; }
    if grep -q '^selected_repos=' "$_stateFile" 2>/dev/null; then
        grep '^selected_repos=' "$_stateFile" | cut -d= -f2- | head -1
        return
    fi
    getDefaultSelectedRepos
}

function repoIsSelected() {
    local _selectedRepos="$1" _repoName="$2" _entry
    local _savedIFS="$IFS"
    IFS=',' read -ra _repoList <<< "$_selectedRepos"
    IFS="$_savedIFS"
    for _entry in "${_repoList[@]}"; do
        [[ $_entry == "$_repoName" ]] && return 0
    done
    return 1
}

function repoChecklistState() {
    local _selectedRepos="$1" _repoName="$2"
    repoIsSelected "$_selectedRepos" "$_repoName" && printf 'ON\n' || printf 'OFF\n'
}

# Like linkShaderFiles but writes into an arbitrary output base directory.
function linkShaderFilesTo() {
    [[ ! -d $1 ]] && return
    local _inDir="$1" _subDir="$2" _outBase="$3"
    cd "$_inDir" || return
    local _outDir="$_outBase/$_subDir"
    mkdir -p "$_outDir"
    local _outDirReal
    _outDirReal="$(realpath "$_outDir")"
    for file in *; do
        [[ ! -f $file ]] && continue
        [[ -L "$_outDirReal/$file" ]] && continue
        ln -s "$(realpath "$_inDir/$file")" "$_outDirReal/"
    done
}

# Like mergeShaderDirs but writes into an arbitrary output base directory.
function mergeShaderDirsTo() {
    [[ $1 != ReShade_shaders && $1 != External_shaders ]] && return
    local _outBase="$3"
    local dirPath
    for dirName in Shaders Textures; do
        [[ $1 == "ReShade_shaders" ]] \
            && dirPath=$(find "$MAIN_PATH/$1/$2" ! -path . -type d -name "$dirName" 2>/dev/null) \
            || dirPath="$MAIN_PATH/$1/$dirName"
        linkShaderFilesTo "$dirPath" "$dirName" "$_outBase"
        while IFS= read -rd '' anyDir; do
            linkShaderFilesTo "$dirPath/$anyDir" "$dirName/$anyDir" "$_outBase"
        done < <(find . ! -path . -type d -print0 2>/dev/null)
    done
}

# Build (or rebuild) a per-game shader directory containing only selected repos.
function buildGameShaderDir() {
    local _gameKey="$1" _selectedRepos="$2"
    [[ -z $_gameKey ]] && return 1
    local _gameShaderDir="$MAIN_PATH/game-shaders/$_gameKey"
    rm -rf "$_gameShaderDir"
    mkdir -p "$_gameShaderDir/Merged/Shaders" "$_gameShaderDir/Merged/Textures"
    local _outBase="$_gameShaderDir/Merged" _entry
    IFS=';' read -ra _allRepos <<< "$SHADER_REPOS"
    for _entry in "${_allRepos[@]}"; do
        parseShaderRepoEntry "$_entry"
        [[ -z $_shaderRepoName ]] && continue
        [[ ",$_selectedRepos," != *",$_shaderRepoName,"* ]] && continue
        [[ ! -d "$MAIN_PATH/ReShade_shaders/$_shaderRepoName" ]] && continue
        mergeShaderDirsTo "ReShade_shaders" "$_shaderRepoName" "$_outBase"
    done
    if [[ -d "$MAIN_PATH/External_shaders" ]]; then
        mergeShaderDirsTo "External_shaders" "" "$_outBase"
        # Link loose files in External_shaders root (not inside Shaders/ subdirectory).
        cd "$MAIN_PATH/External_shaders" || return
        local _file
        for _file in *; do
            [[ ! -f $_file || -L "$_outBase/Shaders/$_file" ]] && continue
            ln -s "$(realpath "$MAIN_PATH/External_shaders/$_file")" "$_outBase/Shaders/"
        done
    fi
}

function ensureGameIni() {
    local _gamePath="$1"
    [[ ${GLOBAL_INI:-ReShade.ini} == 0 ]] && return 0
    local _target="$_gamePath/ReShade.ini"
    [[ -f $_target ]] && return 0
    if [[ ${GLOBAL_INI:-ReShade.ini} == ReShade.ini ]]; then
        cat > "$_target" <<'EOF'
[GENERAL]
EffectSearchPaths=.\ReShade_shaders\Merged\Shaders
TextureSearchPaths=.\ReShade_shaders\Merged\Textures
EOF
        return 0
    fi
    [[ -f "$MAIN_PATH/${GLOBAL_INI:-ReShade.ini}" ]] || return 1
    cp "$MAIN_PATH/${GLOBAL_INI:-ReShade.ini}" "$_target"
}
