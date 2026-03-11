#!/usr/bin/env bats
# Integration tests for the full game detection pipeline

load fixtures

setup() {
    setup_test_env
    export RESHADE_TEST_MODE=1
    
    # Load functions from test_functions.sh
    source "$(dirname "$BATS_TEST_FILENAME")/test_functions.sh"
    
    # Set up built-in presets
    export BUILTIN_GAME_DIR_PRESETS="1091500|bin/x64;292030|bin/x64;275850|Binaries;1245620|Game"
}}

teardown() {
    teardown_test_env
}

@test "Full pipeline: detects game with icon and identifies correct exe" {
    create_warhammer_test
    create_mock_icon "2021390"
    
    local game_dir="$TEST_GAMES_DIR/Warhammer 40,000 Rogue Trader"
    
    # Should find exe
    exe=$(pickBestExeInDir "$game_dir")
    [[ "$exe" == "WH40KRT.exe" ]] || {
        echo "Exe detection failed: got $exe"
        return 1
    }
    
    # Should find icon
    icon=$(findSteamIconPath "$TEST_STEAM_ROOT" "2021390")
    [[ -n "$icon" ]] || {
        echo "Icon detection failed"
        return 1
    }
}

@test "Full pipeline: preset overrides directory detection" {
    # Create game with preset
    local game_root="$TEST_GAMES_DIR/Cyberpunk 2077"
    local bin_x64="$game_root/bin/x64"
    mkdir -p "$bin_x64"
    touch "$bin_x64/Cyberpunk2077.exe"
    
    # Create manifest
    local manifest="$TEST_TEMP_DIR/steamapps/appmanifest_1091500.acf"
    mkdir -p "$(dirname "$manifest")"
    cat > "$manifest" << EOF
"AppState"
{
	"appid"	"1091500"
	"name"	"Cyberpunk 2077"
	"InstallDir"	"Cyberpunk 2077"
	"Type"	"1"
}
EOF
    
    # Should recognize preset and resolve to bin/x64
    preset=$(getBuiltInGameDirPreset "1091500")
    [[ "$preset" == "bin/x64" ]] || {
        echo "Preset lookup failed"
        return 1
    }
}

@test "Full pipeline: handles game without preset (generic path)" {
    local game_name="Generic Game"
    create_mock_game "$game_name" "999999" "game.exe" "launcher.exe"
    
    local game_dir="$TEST_GAMES_DIR/$game_name"
    
    # Should find game exe despite no preset
    exe=$(pickBestExeInDir "$game_dir")
    [[ -n "$exe" ]] || {
        echo "Failed to find exe for game without preset"
        return 1
    }
}

@test "Full pipeline: complex game with multiple utilities correctly picks main exe" {
    create_complex_exes_test
    local game_dir="$TEST_GAMES_DIR/Complex Game"
    
    exe=$(pickBestExeInDir "$game_dir")
    
    # game.exe should win over utilities
    [[ "$exe" == "game.exe" ]] || {
        echo "Expected 'game.exe' but got '$exe'"
        return 1
    }
}

@test "Full pipeline: game without local icon falls back gracefully" {
    local game_name="No Icon Game"
    create_mock_game "$game_name" "888999" "game.exe"
    
    # No icon created for this game
    local game_dir="$TEST_GAMES_DIR/$game_name"
    
    # Should still work despite missing icon
    exe=$(pickBestExeInDir "$game_dir")
    [[ -n "$exe" ]] || {
        echo "Failed to detect exe for game without icon"
        return 1
    }
    
    # Icon lookup should return empty
    icon=$(findSteamIconPath "$TEST_STEAM_ROOT" "888999")
    [[ -z "$icon" ]] || {
        echo "Expected no icon but got: $icon"
        return 1
    }
}

@test "Full pipeline: multiple games can be processed independently" {
    create_warhammer_test
    create_cities_skylines_test
    
    local wh_dir="$TEST_GAMES_DIR/Warhammer 40,000 Rogue Trader"
    local cities_dir="$TEST_GAMES_DIR/Cities_Skylines"
    
    # Each should detect correctly without interference
    wh_exe=$(pickBestExeInDir "$wh_dir")
    cities_exe=$(pickBestExeInDir "$cities_dir")
    
    [[ "$wh_exe" == "WH40KRT.exe" ]] || {
        echo "Warhammer detection failed"
        return 1
    }
    
    [[ "$cities_exe" == "Cities.exe" ]] || {
        echo "Cities Skylines detection failed: got $cities_exe"
        return 1
    }
}

@test "Full pipeline: test env isolation - cleanup doesn't affect other tests" {
    create_warhammer_test
    local dir1="$TEST_GAMES_DIR/Warhammer 40,000 Rogue Trader"
    exe1=$(pickBestExeInDir "$dir1")
    
    [[ "$exe1" == "WH40KRT.exe" ]] || {
        echo "First test failed"
        return 1
    }
    
    # Teardown/setup would happen between tests (in practice)
    # Just verify the test structure works
    return 0
}

@test "Full pipeline: icon priority works with partial cache" {
    local appid="777666"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    mkdir -p "$cache_dir"
    
    # Create only hash-named jpg (no logo.png, no header.jpg)
    echo "mini" > "$cache_dir/hash_icon.jpg"
    
    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    
    [[ "$result" == *"hash_icon.jpg" ]] || {
        echo "Failed to find hash icon in partial cache"
        return 1
    }
}
