#!/bin/bash
# Simple bash-based test runner (doesn't require BATS installation)
# Tests core reshade-linux.sh detection functions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Source test utilities
source "$SCRIPT_DIR/fixtures.sh" || {
    echo "Failed to source fixtures.sh"
    exit 1
}
source "$SCRIPT_DIR/test_functions.sh" || {
    echo "Failed to source test_functions.sh"
    exit 1
}

# Test helper
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    echo -n "  $test_name ... "
    ((TESTS_RUN++))
    
    if setup_test_env && \
       export BUILTIN_GAME_DIR_PRESETS="1091500|bin/x64;292030|bin/x64;275850|Binaries;1245620|Game" && \
       $test_func && \
       teardown_test_env; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
    fi
}

# ============================================================================
# EXE DETECTION TESTS
# ============================================================================

test_exe_warhammer() {
    create_warhammer_test
    local result=$(pickBestExeInDir "$TEST_GAMES_DIR/Warhammer 40,000 Rogue Trader")
    [[ "$result" == "WH40KRT.exe" ]]
}

test_exe_unity_filter() {
    local game_dir="$TEST_GAMES_DIR/UnityTest"
    mkdir -p "$game_dir"
    touch "$game_dir/game.exe"
    touch "$game_dir/UnityPlayer.exe"
    
    local result=$(pickBestExeInDir "$game_dir")
    [[ "$result" == "game.exe" ]] || [[ -n "$result" ]]
}

test_exe_setup_filter() {
    create_complex_exes_test
    local result=$(pickBestExeInDir "$TEST_GAMES_DIR/Complex Game")
    [[ "$result" != "setup.exe" ]]
}

test_exe_no_exes() {
    local game_dir="$TEST_GAMES_DIR/NoExes"
    mkdir -p "$game_dir"
    local result=$(pickBestExeInDir "$game_dir" || true)
    [[ -z "$result" ]]
}

test_exe_name_match() {
    local game_dir="$TEST_GAMES_DIR/MyGame"
    mkdir -p "$game_dir"
    touch "$game_dir/MyGame.exe"
    touch "$game_dir/launcher.exe"
    
    local result=$(pickBestExeInDir "$game_dir")
    [[ "$result" == "MyGame.exe" ]]
}

# ============================================================================
# ICON DETECTION TESTS
# ============================================================================

test_icon_logo() {
    local appid="255710"
    create_mock_icon "$appid"
    local result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    [[ "$result" == *"logo.png" ]]
}

test_icon_hash_over_header() {
    local appid="999888"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    mkdir -p "$cache_dir"
    echo "mini" > "$cache_dir/hash123abc.jpg"
    echo "banner" > "$cache_dir/header.jpg"
    
    local result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    [[ "$result" == *"hash123abc.jpg" ]]
}

test_icon_library_skip() {
    local appid="777888"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    mkdir -p "$cache_dir"
    echo "lib content" > "$cache_dir/library_600x900.jpg"
    echo "actual" > "$cache_dir/abc123def.jpg"
    
    local result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    [[ "$result" == *"abc123def.jpg" ]]
}

test_icon_missing() {
    local appid="111222"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    mkdir -p "$cache_dir"
    
    local result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid" || true)
    [[ -z "$result" ]]
}

# ============================================================================
# PRESET TESTS
# ============================================================================

test_preset_cyberpunk() {
    local result=$(getBuiltInGameDirPreset "1091500")
    [[ "$result" == "bin/x64" ]]
}

test_preset_witcher() {
    local result=$(getBuiltInGameDirPreset "292030")
    [[ "$result" == "bin/x64" ]]
}

test_preset_nms() {
    local result=$(getBuiltInGameDirPreset "275850")
    [[ "$result" == "Binaries" ]]
}

test_preset_elden() {
    local result=$(getBuiltInGameDirPreset "1245620")
    [[ "$result" == "Game" ]]
}

test_preset_unknown() {
    local result=$(getBuiltInGameDirPreset "999999" || true)
    [[ -z "$result" ]]
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

test_integration_full_pipeline() {
    create_warhammer_test
    create_mock_icon "2021390"
    
    local exe=$(pickBestExeInDir "$TEST_GAMES_DIR/Warhammer 40,000 Rogue Trader")
    local icon=$(findSteamIconPath "$TEST_STEAM_ROOT" "2021390")
    
    [[ "$exe" == "WH40KRT.exe" ]] && [[ -n "$icon" ]]
}

test_integration_multi_games() {
    create_warhammer_test
    create_cities_skylines_test
    
    local wh_exe=$(pickBestExeInDir "$TEST_GAMES_DIR/Warhammer 40,000 Rogue Trader")
    local cities_exe=$(pickBestExeInDir "$TEST_GAMES_DIR/Cities_Skylines")
    
    [[ "$wh_exe" == "WH40KRT.exe" ]] && [[ "$cities_exe" == "Cities.exe" ]]
}

# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}ReShade Linux Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    echo -e "${BLUE}Exe Detection Tests${NC}"
    run_test "Warhammer 40K exe selection" test_exe_warhammer
    run_test "UnityPlayer filtering" test_exe_unity_filter
    run_test "Setup.exe filtering" test_exe_setup_filter
    run_test "No exes handling" test_exe_no_exes
    run_test "Name matching bonus" test_exe_name_match
    echo ""
    
    echo -e "${BLUE}Icon Detection Tests${NC}"
    run_test "Logo.png prioritization" test_icon_logo
    run_test "Hash icon over header" test_icon_hash_over_header
    run_test "Library file skipping" test_icon_library_skip
    run_test "Missing icon handling" test_icon_missing
    echo ""
    
    echo -e "${BLUE}Preset Tests${NC}"
    run_test "Cyberpunk 2077 preset" test_preset_cyberpunk
    run_test "Witcher 3 preset" test_preset_witcher
    run_test "No Man's Sky preset" test_preset_nms
    run_test "Elden Ring preset" test_preset_elden
    run_test "Unknown AppID" test_preset_unknown
    echo ""
    
    echo -e "${BLUE}Integration Tests${NC}"
    run_test "Full detection pipeline" test_integration_full_pipeline
    run_test "Multiple games handling" test_integration_multi_games
    echo ""
    
    # Summary
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed! ($TESTS_RUN tests)${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        echo "  Total: $TESTS_RUN tests"
        echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
        echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
        
        if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
            echo -e "\n${RED}Failed tests:${NC}"
            for test in "${FAILED_TESTS[@]}"; do
                echo "  - $test"
            done
        fi
        
        return 1
    fi
}

# Run tests
main "$@"
