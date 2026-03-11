#!/bin/bash
# Test utilities and function definitions for reshade-linux automated testing
# This file extracts the core functions needed for testing without running the main install logic

# Requires: BUILTIN_GAME_DIR_PRESETS variable to be set

# ============================================================================
# CORE DETECTION FUNCTIONS (extracted from reshade-linux.sh)
# ============================================================================

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
        if [[ $_lname =~ (unityplayer|unitycrash|crashhandler|easyanticheat|battleye|asp|unins|uninstall|setup|installer|vcredist|redist|eac|crashreport|benchmark|test|launcher|update|check) ]]; then
            _isUtility=1
            _score=$((_score - 200))
        fi
        
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
    
    printf '%s\n' "$_best"
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
        for _file in "$_cacheDir"/${_appId}.*; do
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
