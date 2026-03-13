#!/bin/bash
# Quick diagnostic for listSteamAppsDirs

# Minimal function definitions
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

echo "=== Steam Libraries Found ==="
listSteamAppsDirs | nl

echo ""
echo "=== Manifest Files in All Libraries ==="
declare -A manifest_count
while read -r lib; do
    [[ -d "$lib" ]] || continue
    echo "Library: $lib"
    for manifest in "$lib"/appmanifest_*.acf; do
        [[ -f "$manifest" ]] || continue
        appid=$(grep -m1 -o '"appid"[[:space:]]*"[0-9]*"' "$manifest" | grep -o '[0-9]*')
        name=$(grep -m1 -o '"name"[[:space:]]*"[^"]*"' "$manifest" | sed -E 's/.*"name"[[:space:]]*"([^"]*)".*/\1/')
        name="${name:0:50}"
        printf "  %s | %s | %s\n" "$appid" "$name" "$manifest"
        manifest_count["$appid"]=$((manifest_count["$appid"]+1))
    done
done < <(listSteamAppsDirs)

echo ""
echo "=== Duplicate AppIDs Found Across Libraries ==="
for appid in "${!manifest_count[@]}"; do
    if (( manifest_count["$appid"] > 1 )); then
        echo "⚠ AppID $appid found $manifest_count[$appid] times!"
    fi
done
