#!/bin/bash
# Simple bash-based test runner (doesn't require BATS installation)
# Tests core reshade-linux.sh detection functions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

run_test() {
    local test_name="$1"
    local test_func="$2"

    echo -n "  $test_name ... "
    TESTS_RUN=$(( TESTS_RUN + 1 ))

    if setup_test_env && \
       export BUILTIN_GAME_DIR_PRESETS="1091500|bin/x64;292030|bin/x64;275850|Binaries;1245620|Game;306130|The Elder Scrolls Online/game/client;2623190|OblivionRemastered/Binaries/Win64" && \
       "$test_func" && \
       teardown_test_env; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$(( TESTS_PASSED + 1 ))
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$(( TESTS_FAILED + 1 ))
        FAILED_TESTS+=("$test_name")
        teardown_test_env 2>/dev/null || true
    fi
}

# ============================================================================
# EXE DETECTION TESTS
# ============================================================================

test_exe_warhammer() {
    local result
    create_warhammer_test
    result=$(pickBestExeInDir "$TEST_GAMES_DIR/Warhammer 40,000 Rogue Trader")
    [[ "$result" == "WH40KRT.exe" ]]
}

test_exe_unity_filter() {
    local game_dir="$TEST_GAMES_DIR/UnityTest"
    local result
    mkdir -p "$game_dir"
    touch "$game_dir/game.exe"
    touch "$game_dir/UnityPlayer.exe"

    result=$(pickBestExeInDir "$game_dir")
    [[ "$result" == "game.exe" ]] || [[ -n "$result" ]]
}

test_exe_setup_filter() {
    local result
    create_complex_exes_test
    result=$(pickBestExeInDir "$TEST_GAMES_DIR/Complex Game")
    [[ "$result" != "setup.exe" ]]
}

test_exe_no_exes() {
    local game_dir="$TEST_GAMES_DIR/NoExes"
    local result
    mkdir -p "$game_dir"
    result=$(pickBestExeInDir "$game_dir" || true)
    [[ -z "$result" ]]
}

test_exe_all_utilities_returns_empty() {
    local game_dir="$TEST_GAMES_DIR/BadOnly"
    local result
    mkdir -p "$game_dir"
    touch "$game_dir/mono.exe"
    touch "$game_dir/setup.exe"

    result=$(pickBestExeInDir "$game_dir" || true)
    [[ -z "$result" ]]
}

test_exe_name_match() {
    local game_dir="$TEST_GAMES_DIR/MyGame"
    local result
    mkdir -p "$game_dir"
    touch "$game_dir/MyGame.exe"
    touch "$game_dir/launcher.exe"

    result=$(pickBestExeInDir "$game_dir")
    [[ "$result" == "MyGame.exe" ]]
}

# ============================================================================
# ICON DETECTION TESTS
# ============================================================================

test_icon_logo() {
    local appid="255710"
    local result
    create_mock_icon "$appid"
    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    [[ "$result" == *"logo.png" ]]
}

test_icon_hash_over_header() {
    local appid="999888"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    local result
    mkdir -p "$cache_dir"
    echo "mini" > "$cache_dir/a94a8fe5ccb19ba61c4c0873d391e987982fbbd3.jpg"
    echo "banner" > "$cache_dir/header.jpg"

    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    [[ "$result" == *"a94a8fe5ccb19ba61c4c0873d391e987982fbbd3.jpg" ]]
}

test_icon_library_skip() {
    local appid="777888"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    local result
    mkdir -p "$cache_dir"
    echo "lib content" > "$cache_dir/library_600x900.jpg"
    echo "actual" > "$cache_dir/b6589fc6ab0dc82cf12099d1c2d40ab994e8410c.jpg"

    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    [[ "$result" == *"b6589fc6ab0dc82cf12099d1c2d40ab994e8410c.jpg" ]]
}

test_icon_missing() {
    local appid="111222"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    local result
    mkdir -p "$cache_dir"

    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid" || true)
    [[ -z "$result" ]]
}

# ============================================================================
# UI BACKEND TESTS
# ============================================================================

test_ui_backend_prefers_yad_in_graphical_session() {
    local fakebin="$TEST_TEMP_DIR/fakebin"
    local result
    mkdir -p "$fakebin"
    printf '#!/bin/sh\nexit 0\n' > "$fakebin/yad"
    chmod +x "$fakebin/yad"

    result=$(PATH="$fakebin:$PATH" DISPLAY=:1 WAYLAND_DISPLAY='' chooseUiBackend 1)
    [[ "$result" == "yad" ]]
}

test_ui_backend_uses_whiptail_on_tty_without_yad() {
    local fakebin="$TEST_TEMP_DIR/fakebin"
    local result
    mkdir -p "$fakebin"
    printf '#!/bin/sh\nexit 0\n' > "$fakebin/whiptail"
    chmod +x "$fakebin/whiptail"

    result=$(PATH="$fakebin:$PATH" DISPLAY='' WAYLAND_DISPLAY='' chooseUiBackend 1)
    [[ "$result" == "whiptail" ]]
}

test_ui_backend_falls_back_to_cli_without_tools() {
    local result
    result=$(DISPLAY='' WAYLAND_DISPLAY='' chooseUiBackend 0)
    [[ "$result" == "cli" ]]
}

test_ui_backend_honors_forced_cli_override() {
    local result
    result=$(UI_BACKEND=cli DISPLAY=:1 WAYLAND_DISPLAY=:1 chooseUiBackend 1)
    [[ "$result" == "cli" ]]
}

test_ui_backend_honors_forced_yad_override() {
    local result
    result=$(UI_BACKEND=yad DISPLAY='' WAYLAND_DISPLAY='' chooseUiBackend 0)
    [[ "$result" == "yad" ]]
}

test_ui_backend_rejects_invalid_override() {
    ! UI_BACKEND=broken chooseUiBackend 1 >/dev/null 2>&1
}

# ============================================================================
# PRESET TESTS
# ============================================================================

test_preset_cyberpunk() {
    local result
    result=$(getBuiltInGameDirPreset "1091500")
    [[ "$result" == "bin/x64" ]]
}

test_preset_witcher() {
    local result
    result=$(getBuiltInGameDirPreset "292030")
    [[ "$result" == "bin/x64" ]]
}

test_preset_nms() {
    local result
    result=$(getBuiltInGameDirPreset "275850")
    [[ "$result" == "Binaries" ]]
}

test_preset_elden() {
    local result
    result=$(getBuiltInGameDirPreset "1245620")
    [[ "$result" == "Game" ]]
}

test_preset_eso() {
    local result
    result=$(getBuiltInGameDirPreset "306130")
    [[ "$result" == "The Elder Scrolls Online/game/client" ]]
}

test_preset_oblivion_remastered() {
    local result
    result=$(getBuiltInGameDirPreset "2623190")
    [[ "$result" == "OblivionRemastered/Binaries/Win64" ]]
}

test_preset_unknown() {
    local result
    result=$(getBuiltInGameDirPreset "999999" || true)
    [[ -z "$result" ]]
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

test_integration_full_pipeline() {
    local exe icon
    create_warhammer_test
    create_mock_icon "2021390"

    exe=$(pickBestExeInDir "$TEST_GAMES_DIR/Warhammer 40,000 Rogue Trader")
    icon=$(findSteamIconPath "$TEST_STEAM_ROOT" "2021390")

    [[ "$exe" == "WH40KRT.exe" ]] && [[ -n "$icon" ]]
}

test_integration_multi_games() {
    local wh_exe cities_exe
    create_warhammer_test
    create_cities_skylines_test

    wh_exe=$(pickBestExeInDir "$TEST_GAMES_DIR/Warhammer 40,000 Rogue Trader")
    cities_exe=$(pickBestExeInDir "$TEST_GAMES_DIR/Cities_Skylines")

    [[ "$wh_exe" == "WH40KRT.exe" ]] && [[ "$cities_exe" == "Cities.exe" ]]
}

test_install_dir_prefers_subdir_over_root() {
    local game_root="$TEST_GAMES_DIR/RootVsBin"
    local result
    mkdir -p "$game_root/bin/x64"
    touch "$game_root/launcher.exe"
    touch "$game_root/bin/x64/RootVsBin.exe"

    result=$(resolveGameInstallDir "$game_root" "555000")
    [[ "$result" == "$game_root/bin/x64|heuristic" ]]
}

test_install_dir_uses_custom_preset_when_present() {
    local game_root="$TEST_GAMES_DIR/PresetGame"
    local result
    export GAME_DIR_PRESETS="444000|Custom/Binaries"
    mkdir -p "$game_root/Custom/Binaries"
    touch "$game_root/Custom/Binaries/PresetGame.exe"
    touch "$game_root/root.exe"

    result=$(resolveGameInstallDir "$game_root" "444000")
    [[ "$result" == "$game_root/Custom/Binaries|preset:Custom/Binaries" ]]
}

test_install_dir_scan_fallback_finds_best_nested_exe() {
    local game_root="$TEST_GAMES_DIR/ScanFallback"
    local result
    mkdir -p "$game_root/CustomBuild/Shipping"
    mkdir -p "$game_root/Runtime/MonoBleedingEdge"
    touch "$game_root/CustomBuild/Shipping/ScanFallback-Win64-Shipping.exe"
    touch "$game_root/Runtime/MonoBleedingEdge/mono.exe"

    result=$(resolveGameInstallDir "$game_root" "777000")
    [[ "$result" == "$game_root/CustomBuild/Shipping|scan" ]]
}

# ============================================================================
# STATE MANAGEMENT TESTS
# ============================================================================

test_state_write_and_read() {
    writeGameState "123456" "/games/mygame" "dxgi" "64" "sweetfx-shaders,immerse-shaders" "123456"
    local _f="$MAIN_PATH/game-state/123456.state"
    [[ -f "$_f" ]] || return 1
    grep -q '^dll=dxgi$' "$_f" || return 1
    grep -q '^arch=64$' "$_f" || return 1
    grep -q '^gamePath=/games/mygame$' "$_f" || return 1
    grep -q '^selected_repos=sweetfx-shaders,immerse-shaders$' "$_f" || return 1
    grep -q '^app_id=123456$' "$_f" || return 1
}

test_state_no_appid_is_noop() {
    local _count
    writeGameState "" "/games/mygame" "dxgi" "64" ""
    _count=$(find "$MAIN_PATH/game-state" -name "*.state" 2>/dev/null | wc -l)
    [[ "$_count" -eq 0 ]]
}

test_state_overwrite() {
    local _dll
    writeGameState "111" "/games/a" "d3d9" "32" "repo1" "111"
    writeGameState "111" "/games/b" "dxgi" "64" "repo2" "111"
    _dll=$(grep '^dll=' "$MAIN_PATH/game-state/111.state" | cut -d= -f2)
    [[ "$_dll" == "dxgi" ]]
}

test_state_builds_path_key_for_nonsteam_game() {
    local _key
    _key=$(buildGameInstallKey "" "/games/nonsteam")
    [[ "$_key" == path-* ]]
}

test_state_missing_selected_repos_defaults_to_all() {
    local _repos
    export SHADER_REPOS="https://example.com/a|alpha;https://example.com/b|beta"
    cat > "$MAIN_PATH/game-state/legacy.state" <<'EOF'
dll=dxgi
arch=64
gamePath=/games/legacy
EOF
    _repos=$(readSelectedReposFromState "$MAIN_PATH/game-state/legacy.state")
    [[ "$_repos" == "alpha,beta" ]]
}

test_state_explicit_empty_selected_repos_stays_empty() {
    local _repos
    export SHADER_REPOS="https://example.com/a|alpha;https://example.com/b|beta"
    writeGameState "empty" "/games/empty" "dxgi" "64" ""
    _repos=$(readSelectedReposFromState "$MAIN_PATH/game-state/empty.state")
    [[ -z "$_repos" ]]
}

test_state_checklist_marks_saved_repo_on() {
    local _state
    _state=$(repoChecklistState "alpha,beta" "alpha")
    [[ "$_state" == "ON" ]]
}

test_state_checklist_uses_exact_repo_match() {
    local _state
    _state=$(repoChecklistState "prod80-shaders" "prod80")
    [[ "$_state" == "OFF" ]]
}

test_state_reports_installed_when_dll_exists() {
    local game_dir="$TEST_TEMP_DIR/installed-game"
    mkdir -p "$game_dir"
    : > "$game_dir/dxgi.dll"

    writeGameState "123456" "$game_dir" "dxgi" "64" "alpha" "123456"
    isReshadeInstalledOnDisk "$MAIN_PATH/game-state/123456.state"
}

test_state_rejects_stale_install_when_dll_missing() {
    local game_dir="$TEST_TEMP_DIR/stale-game"
    mkdir -p "$game_dir"

    writeGameState "654321" "$game_dir" "dxgi" "64" "alpha" "654321"
    ! isReshadeInstalledOnDisk "$MAIN_PATH/game-state/654321.state"
}

test_state_rejects_missing_dll_field() {
    local state_file="$MAIN_PATH/game-state/bad-dll.state"
    mkdir -p "$MAIN_PATH/game-state"
    cat > "$state_file" <<'EOF'
arch=64
gamePath=/games/malformed
selected_repos=alpha
app_id=111111
EOF

    ! isReshadeInstalledOnDisk "$state_file"
}

test_state_rejects_missing_gamepath_field() {
    local state_file="$MAIN_PATH/game-state/bad-path.state"
    mkdir -p "$MAIN_PATH/game-state"
    cat > "$state_file" <<'EOF'
dll=dxgi
arch=64
selected_repos=alpha
app_id=222222
EOF

    ! isReshadeInstalledOnDisk "$state_file"
}

test_state_default_repo_names_support_descriptions() {
    local _repos
    export SHADER_REPOS="https://example.com/a|alpha||First repo;https://example.com/b|beta|main|Second repo"
    _repos=$(getDefaultSelectedRepos)
    [[ "$_repos" == "alpha,beta" ]]
}

test_state_shader_repo_parser_keeps_empty_branch_with_description() {
    local _shaderRepoUri="" _shaderRepoName="" _shaderRepoBranch="" _shaderRepoDesc=""
    export SHADER_REPOS="https://example.com/repo|alpha||Description text"
    parseShaderRepoEntry "https://example.com/repo|alpha||Description text"
    [[ "$_shaderRepoUri" == "https://example.com/repo" ]] || return 1
    [[ "$_shaderRepoName" == "alpha" ]] || return 1
    [[ -z "$_shaderRepoBranch" ]] || return 1
    [[ "$_shaderRepoDesc" == "Description text" ]]
}

test_shader_build_supports_description_without_branch() {
    export SHADER_REPOS="https://example.com/a|alpha||Alpha description"
    create_mock_shader_repo "alpha"
    buildGameShaderDir "55555" "alpha"
    [[ -L "$MAIN_PATH/game-shaders/55555/Merged/Shaders/alpha.fx" ]]
}

# ============================================================================
# RELEASE METADATA TESTS
# ============================================================================

test_release_metadata_version_matches_changelog_headline() {
    local version_file="$SCRIPT_DIR/../VERSION"
    local changelog_file="$SCRIPT_DIR/../CHANGELOG.md"
    local version changelog_version

    version=$(tr -d '\n' < "$version_file")
    changelog_version=$(grep -m1 '^## \[' "$changelog_file" | sed -E 's/^## \[([^]]+)\].*/\1/')

    [[ -n "$version" ]]
    [[ "$version" == "$changelog_version" ]]
}

test_release_metadata_current_version_is_dated() {
    local version_file="$SCRIPT_DIR/../VERSION"
    local changelog_file="$SCRIPT_DIR/../CHANGELOG.md"
    local version first_release_line

    version=$(tr -d '\n' < "$version_file")
    first_release_line=$(grep -m1 '^## \[' "$changelog_file")

    [[ "$first_release_line" == "## [$version] - "* ]]
    [[ "$first_release_line" != *"Unreleased"* ]]
}

# ============================================================================
# SHADER SELECTION / PER-GAME SHADER DIR TESTS
# ============================================================================

test_shader_build_creates_dir() {
    export SHADER_REPOS="https://example.com/repo|test-shaders"
    create_mock_shader_repo "test-shaders"
    buildGameShaderDir "99999" "test-shaders"
    [[ -d "$MAIN_PATH/game-shaders/99999/Merged/Shaders" ]]
}

test_shader_build_links_selected_repo() {
    export SHADER_REPOS="https://example.com/a|alpha-shaders;https://example.com/b|beta-shaders"
    create_mock_shader_repo "alpha-shaders"
    create_mock_shader_repo "beta-shaders"
    buildGameShaderDir "11111" "alpha-shaders"
    [[ -L "$MAIN_PATH/game-shaders/11111/Merged/Shaders/alpha-shaders.fx" ]] || return 1
    [[ ! -e "$MAIN_PATH/game-shaders/11111/Merged/Shaders/beta-shaders.fx" ]]
}

test_shader_build_excludes_unselected_repo() {
    export SHADER_REPOS="https://example.com/a|alpha-shaders;https://example.com/b|beta-shaders"
    create_mock_shader_repo "alpha-shaders"
    create_mock_shader_repo "beta-shaders"
    buildGameShaderDir "22222" "beta-shaders"
    [[ -L "$MAIN_PATH/game-shaders/22222/Merged/Shaders/beta-shaders.fx" ]] || return 1
    [[ ! -e "$MAIN_PATH/game-shaders/22222/Merged/Shaders/alpha-shaders.fx" ]]
}

test_shader_build_includes_external() {
    export SHADER_REPOS="https://example.com/r|some-repo"
    create_mock_shader_repo "some-repo"
    echo "// external" > "$MAIN_PATH/External_shaders/MyCustom.fx"
    buildGameShaderDir "33333" "some-repo"
    [[ -L "$MAIN_PATH/game-shaders/33333/Merged/Shaders/MyCustom.fx" ]]
}

test_shader_rebuild_replaces_previous() {
    export SHADER_REPOS="https://example.com/a|alpha-shaders;https://example.com/b|beta-shaders"
    create_mock_shader_repo "alpha-shaders"
    create_mock_shader_repo "beta-shaders"
    buildGameShaderDir "44444" "alpha-shaders"
    [[ -L "$MAIN_PATH/game-shaders/44444/Merged/Shaders/alpha-shaders.fx" ]] || return 1
    buildGameShaderDir "44444" "beta-shaders"
    [[ -L "$MAIN_PATH/game-shaders/44444/Merged/Shaders/beta-shaders.fx" ]] || return 1
    [[ ! -e "$MAIN_PATH/game-shaders/44444/Merged/Shaders/alpha-shaders.fx" ]]
}

test_game_ini_is_per_game_and_relative() {
    local _game_dir="$TEST_TEMP_DIR/nonsteam-game"
    mkdir -p "$_game_dir"
    ensureGameIni "$_game_dir"
    grep -Fqx 'EffectSearchPaths=.\ReShade_shaders\Merged\Shaders' "$_game_dir/ReShade.ini"
    grep -Fqx 'TextureSearchPaths=.\ReShade_shaders\Merged\Textures' "$_game_dir/ReShade.ini"
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
    run_test "Utility-only dirs return empty" test_exe_all_utilities_returns_empty
    run_test "Name matching bonus" test_exe_name_match
    echo ""

    echo -e "${BLUE}Icon Detection Tests${NC}"
    run_test "Logo.png prioritization" test_icon_logo
    run_test "Hash icon over header" test_icon_hash_over_header
    run_test "Library file skipping" test_icon_library_skip
    run_test "Missing icon handling" test_icon_missing
    echo ""

    echo -e "${BLUE}UI Backend Tests${NC}"
    run_test "Graphical sessions prefer YAD" test_ui_backend_prefers_yad_in_graphical_session
    run_test "TTY sessions use whiptail fallback" test_ui_backend_uses_whiptail_on_tty_without_yad
    run_test "No UI tools falls back to CLI" test_ui_backend_falls_back_to_cli_without_tools
    run_test "Forced CLI override wins" test_ui_backend_honors_forced_cli_override
    run_test "Forced YAD override wins" test_ui_backend_honors_forced_yad_override
    run_test "Invalid UI_BACKEND is rejected" test_ui_backend_rejects_invalid_override
    echo ""

    echo -e "${BLUE}Preset Tests${NC}"
    run_test "Cyberpunk 2077 preset" test_preset_cyberpunk
    run_test "Witcher 3 preset" test_preset_witcher
    run_test "No Man's Sky preset" test_preset_nms
    run_test "Elden Ring preset" test_preset_elden
    run_test "ESO preset" test_preset_eso
    run_test "Oblivion Remastered preset" test_preset_oblivion_remastered
    run_test "Unknown AppID" test_preset_unknown
    echo ""

    echo -e "${BLUE}Integration Tests${NC}"
    run_test "Full detection pipeline" test_integration_full_pipeline
    run_test "Multiple games handling" test_integration_multi_games
    run_test "Install dir prefers bin/x64 over root" test_install_dir_prefers_subdir_over_root
    run_test "Custom install-dir preset wins" test_install_dir_uses_custom_preset_when_present
    run_test "Install dir scan fallback finds nested exe" test_install_dir_scan_fallback_finds_best_nested_exe
    echo ""

    echo -e "${BLUE}State Management Tests${NC}"
    run_test "Write and read state file" test_state_write_and_read
    run_test "No-op when appid empty" test_state_no_appid_is_noop
    run_test "State file overwrite" test_state_overwrite
    run_test "Non-Steam install key" test_state_builds_path_key_for_nonsteam_game
    run_test "Legacy state defaults to all repos" test_state_missing_selected_repos_defaults_to_all
    run_test "Explicit empty repo state stays empty" test_state_explicit_empty_selected_repos_stays_empty
    run_test "Checklist marks saved repo on" test_state_checklist_marks_saved_repo_on
    run_test "Checklist uses exact repo match" test_state_checklist_uses_exact_repo_match
    run_test "Installed state checks DLL presence" test_state_reports_installed_when_dll_exists
    run_test "Stale state is not installed" test_state_rejects_stale_install_when_dll_missing
    run_test "Missing dll field is rejected" test_state_rejects_missing_dll_field
    run_test "Missing gamePath field is rejected" test_state_rejects_missing_gamepath_field
    run_test "Default repo parsing supports descriptions" test_state_default_repo_names_support_descriptions
    run_test "Shader repo parser keeps empty branch" test_state_shader_repo_parser_keeps_empty_branch_with_description
    echo ""

    echo -e "${BLUE}Release Metadata Tests${NC}"
    run_test "VERSION matches changelog current release" test_release_metadata_version_matches_changelog_headline
    run_test "Current changelog release is dated" test_release_metadata_current_version_is_dated
    echo ""

    echo -e "${BLUE}Shader Selection Tests${NC}"
    run_test "Build creates output dir" test_shader_build_creates_dir
    run_test "Links only selected repo" test_shader_build_links_selected_repo
    run_test "Excludes unselected repo" test_shader_build_excludes_unselected_repo
    run_test "Includes external shaders" test_shader_build_includes_external
    run_test "Rebuild replaces previous" test_shader_rebuild_replaces_previous
    run_test "Build supports description without branch" test_shader_build_supports_description_without_branch
    run_test "Per-game ReShade.ini uses relative paths" test_game_ini_is_per_game_and_relative
    echo ""

    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All $TESTS_RUN tests passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ $TESTS_FAILED/$TESTS_RUN tests failed${NC}"
        echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
        echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
        if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
            echo -e "\n${RED}Failed tests:${NC}"
            local test
            for test in "${FAILED_TESTS[@]}"; do
                echo "  - $test"
            done
        fi
        return 1
    fi
}

main "$@"
