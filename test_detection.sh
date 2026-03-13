#!/bin/bash
# Direct test of game detection
cd "$(dirname "$0")" || exit 1

# Source just enough of the main script to get the detection functions
# Skip the execution part
source <(sed -n '1,1200p' ./reshade-linux.sh)

# Clear the log  
> /tmp/game_detection.log

# Run detection
detectSteamGames

# Show results
echo "=== Games Detected ==="
for i in "${!DETECTED_GAME_APPIDS[@]}"; do
    printf "%2d. [AppID %s] %s (%s)\n" "$((i+1))" "${DETECTED_GAME_APPIDS[i]}" "${DETECTED_GAME_NAMES[i]}" "${DETECTED_GAME_EXES[i]}"
done

echo ""
echo "=== Detection Log ==="
cat /tmp/game_detection.log

echo ""
echo "=== Checking for Duplicates ==="
declare -A appid_list
for appid in "${DETECTED_GAME_APPIDS[@]}"; do
    if [[ -n ${appid_list["$appid"]} ]]; then
        echo "⚠ DUPLICATE: AppID $appid appears multiple times!"
    fi
    appid_list["$appid"]=1
done
