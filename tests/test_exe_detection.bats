#!/usr/bin/env bats
# Tests for pickBestExeInDir() function
# Validates game executable detection and filtering logic

load fixtures

setup() {
    setup_test_env
    export RESHADE_TEST_MODE=1
    
    # Load functions from test_functions.sh
    source "$(dirname "$BATS_TEST_FILENAME")/test_functions.sh"
}

teardown() {
    teardown_test_env
}

@test "pickBestExeInDir: selects main game exe over crash handler" {
    create_warhammer_test
    local game_dir="$TEST_GAMES_DIR/Warhammer 40,000 Rogue Trader"
    
    result=$(pickBestExeInDir "$game_dir")
    
    [[ "$result" == "WH40KRT.exe" ]] || {
        echo "Expected 'WH40KRT.exe' but got '$result'"
        return 1
    }
}

@test "pickBestExeInDir: filters out UnityPlayer utilities" {
    create_complex_exes_test
    local game_dir="$TEST_GAMES_DIR/Complex Game"
    
    result=$(pickBestExeInDir "$game_dir")
    
    # Should NOT select UnityPlayer.exe
    [[ "$result" != "UnityPlayer.exe" ]] || {
        echo "UnityPlayer.exe should have been filtered"
        return 1
    }
}

@test "pickBestExeInDir: filters out EasyAntiCheat" {
    create_complex_exes_test
    local game_dir="$TEST_GAMES_DIR/Complex Game"
    
    result=$(pickBestExeInDir "$game_dir")
    
    [[ "$result" != "EasyAntiCheat.exe" ]] || {
        echo "EasyAntiCheat.exe should have been filtered"
        return 1
    }
}

@test "pickBestExeInDir: filters out setup installers" {
    create_complex_exes_test
    local game_dir="$TEST_GAMES_DIR/Complex Game"
    
    result=$(pickBestExeInDir "$game_dir")
    
    [[ "$result" != "setup.exe" ]] || {
        echo "setup.exe should have been filtered"
        return 1
    }
}

@test "pickBestExeInDir: prefers exe with name matching parent folder" {
    local game_dir="$TEST_GAMES_DIR/MyGame"
    mkdir -p "$game_dir"
    touch "$game_dir/MyGame.exe"
    touch "$game_dir/launcher.exe"
    
    result=$(pickBestExeInDir "$game_dir")
    
    [[ "$result" == "MyGame.exe" ]] || {
        echo "Expected 'MyGame.exe' (name match) but got '$result'"
        return 1
    }
}

@test "pickBestExeInDir: handles directory with no exes" {
    local game_dir="$TEST_GAMES_DIR/NoExes"
    mkdir -p "$game_dir"
    
    result=$(pickBestExeInDir "$game_dir" || echo "")
    
    [[ -z "$result" ]] || {
        echo "Expected empty result but got '$result'"
        return 1
    }
}

@test "pickBestExeInDir: scores architecture keywords positively" {
    local game_dir="$TEST_GAMES_DIR/ArchTest"
    mkdir -p "$game_dir"
    touch "$game_dir/game_generic.exe"
    touch "$game_dir/game_x64.exe"
    
    result=$(pickBestExeInDir "$game_dir")
    
    # x64 version should score higher
    [[ "$result" == "game_x64.exe" ]] || {
        echo "Expected 'game_x64.exe' (arch match) but got '$result'"
        return 1
    }
}

@test "pickBestExeInDir: scores game keyword positively" {
    local game_dir="$TEST_GAMES_DIR/KeywordTest"
    mkdir -p "$game_dir"
    touch "$game_dir/mygame.exe"
    touch "$game_dir/launcher.exe"
    
    result=$(pickBestExeInDir "$game_dir")
    
    # "game" keyword should win
    [[ "$result" == "mygame.exe" ]] || {
        echo "Expected 'mygame.exe' (keyword match) but got '$result'"
        return 1
    }
}

@test "pickBestExeInDir: handles case-insensitive matching" {
    local game_dir="$TEST_GAMES_DIR/CaseTest"
    mkdir -p "$game_dir"
    touch "$game_dir/MYUTILITY.EXE"
    touch "$game_dir/MyGame.exe"
    
    result=$(pickBestExeInDir "$game_dir")
    
    # MyGame should be chosen (has keyword)
    [[ "$result" == "MyGame.exe" ]] || {
        echo "Expected 'MyGame.exe' but got '$result' (case-insensitivity test)"
        return 1
    }
}

@test "pickBestExeInDir: penalizes single-character generic names" {
    local game_dir="$TEST_GAMES_DIR/GenericTest"
    mkdir -p "$game_dir"
    touch "$game_dir/a.exe"
    touch "$game_dir/myapp.exe"
    
    result=$(pickBestExeInDir "$game_dir")
    
    [[ "$result" == "myapp.exe" ]] || {
        echo "Expected 'myapp.exe' (not single-char) but got '$result'"
        return 1
    }
}
