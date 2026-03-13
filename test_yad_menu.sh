#!/bin/bash
# Comprehensive test simulating the exact getGamePath flow
cd "$(dirname "$0")" || exit 1

# Source the main script (functions only, no execution)
source <(sed -n '1,1750p' ./reshade-linux.sh)

# Clear the log  
> /tmp/game_detection.log

# Run the EXACT code path from getGamePath
echo "=== Simulating getGamePath for INSTALL (main path) ==="
detectSteamGames

echo "Games after detectSteamGames:"
for i in "${!DETECTED_GAME_APPIDS[@]}"; do
    printf "  %d: AppID %s\n" "$i" "${DETECTED_GAME_APPIDS[i]}"
done

# Now simulate what gets built for the menu (from lines 1204-1213)
local -a _items=()
for ((_i=0; _i<${#DETECTED_GAME_PATHS[@]}; _i++)); do
    _statusLabel="${DETECTED_GAME_NAMES[_i]}"
    _items+=("$((_i+1))" "$_statusLabel | AppID ${DETECTED_GAME_APPIDS[_i]} | ${DETECTED_GAME_EXES[_i]}")
done

echo ""
echo "=== Menu Items (what YAD would show) ==="
for ((i=0; i<${#_items[@]}; i+=2)); do
    printf "%s. %s\n" "${_items[i]}" "${_items[((i+1))]}"
done

echo ""
echo "=== Checking for Duplicates in Menu ==="
for ((i=1; i<${#_items[@]}; i+=2)); do
    for ((j=i+2; j<${#_items[@]}; j+=2)); do
        if [[ "${_items[$i]}" == "${_items[$j]}" ]]; then
            echo "⚠ DUPLICATE: ${_items[$i]}"
        fi
    done
done

echo ""
echo "=== Detection Log ==="
cat /tmp/game_detection.log
