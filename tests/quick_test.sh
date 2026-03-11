#!/bin/bash
# Simple bash-based test runner (no external dependencies)
# Tests core reshade-linux.sh detection functions

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0

# Source test utilities
source "$SCRIPT_DIR/test_functions.sh" || exit 1
source "$SCRIPT_DIR/fixtures.sh" || exit 1

export BUILTIN_GAME_DIR_PRESETS="1091500|bin/x64;292030|bin/x64;275850|Binaries;1245620|Game"

# Test runner
test_exe_warhammer() {
    setup_test_env || return 1
    create_warhammer_test || return 1
    local result=$(pickBestExeInDir "$TEST_GAMES_DIR/Warhammer 40,000 Rogue Trader" || echo "")
    teardown_test_env || return 1
    [[ "$result" == "WH40KRT.exe" ]]
}

test_preset_cyberpunk() {
    setup_test_env || return 1
    local result=$(getBuiltInGameDirPreset "1091500" || echo "")
    teardown_test_env || return 1
    [[ "$result" == "bin/x64" ]]
}

test_icon_logo() {
    setup_test_env || return 1
    local appid="255710"
    create_mock_icon "$appid" || return 1
    local result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid" || echo "")
    teardown_test_env || return 1
    [[ "$result" == *"logo.png" ]]
}

# Run tests
echo "Running tests..."
echo ""

for test in test_exe_warhammer test_preset_cyberpunk test_icon_logo; do
    printf "  %-40s " "$test:"
    if $test 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        ((PASS++)) || true
    else
        echo -e "${RED}FAIL${NC}"
        ((FAIL++)) || true
    fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
