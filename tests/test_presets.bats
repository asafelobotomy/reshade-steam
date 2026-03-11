#!/usr/bin/env bats
# Tests for built-in game preset lookups and directory resolution

load fixtures

setup() {
    setup_test_env
    export RESHADE_TEST_MODE=1
    
    # Load functions from test_functions.sh
    source "$(dirname "$BATS_TEST_FILENAME")/test_functions.sh"
    
    # Set up built-in presets  
    export BUILTIN_GAME_DIR_PRESETS="1091500|bin/x64;292030|bin/x64;275850|Binaries;1245620|Game"
}

teardown() {
    teardown_test_env
}

@test "getBuiltInGameDirPreset: returns bin/x64 for Cyberpunk 2077" {
    # Cyberpunk 2077 AppID: 1091500
    result=$(getBuiltInGameDirPreset "1091500")
    
    [[ "$result" == "bin/x64" ]] || {
        echo "Expected 'bin/x64' for Cyberpunk, got: $result"
        return 1
    }
}

@test "getBuiltInGameDirPreset: returns bin/x64 for Witcher 3" {
    # Witcher 3 AppID: 292030
    result=$(getBuiltInGameDirPreset "292030")
    
    [[ "$result" == "bin/x64" ]] || {
        echo "Expected 'bin/x64' for Witcher 3, got: $result"
        return 1
    }
}

@test "getBuiltInGameDirPreset: returns Binaries for No Man's Sky" {
    # No Man's Sky AppID: 275850
    result=$(getBuiltInGameDirPreset "275850")
    
    [[ "$result" == "Binaries" ]] || {
        echo "Expected 'Binaries' for NMS, got: $result"
        return 1
    }
}

@test "getBuiltInGameDirPreset: returns Game for Elden Ring" {
    # Elden Ring AppID: 1245620
    result=$(getBuiltInGameDirPreset "1245620")
    
    [[ "$result" == "Game" ]] || {
        echo "Expected 'Game' for Elden Ring, got: $result"
        return 1
    }
}

@test "getBuiltInGameDirPreset: returns empty for unknown AppID" {
    result=$(getBuiltInGameDirPreset "999999")
    
    [[ -z "$result" ]] || {
        echo "Expected empty string for unknown AppID, got: $result"
        return 1
    }
}

@test "getBuiltInGameDirPreset: handles all presets without conflicts" {
    # Ensure no preset is overwritten
    
    local appids=("1091500" "292030" "275850" "1245620")
    local expected=("bin/x64" "bin/x64" "Binaries" "Game")
    
    for i in "${!appids[@]}"; do
        result=$(getBuiltInGameDirPreset "${appids[$i]}")
        [[ "$result" == "${expected[$i]}" ]] || {
            echo "Preset ${appids[$i]} mismatch: expected '${expected[$i]}' got '$result'"
            return 1
        }
    done
}

@test "getBuiltInGameDirPreset: returns consistent results on repeated calls" {
    result1=$(getBuiltInGameDirPreset "1091500")
    result2=$(getBuiltInGameDirPreset "1091500")
    
    [[ "$result1" == "$result2" ]] || {
        echo "Inconsistent results: '$result1' vs '$result2'"
        return 1
    }
}

@test "getBuiltInGameDirPreset: handles AppID as string" {
    # Test with leading zeros (should not match)
    result=$(getBuiltInGameDirPreset "01091500")
    
    [[ -z "$result" ]] || {
        echo "Expected no match for padded AppID, got: $result"
        return 1
    }
}

@test "getBuiltInGameDirPreset: works with empty preset list" {
    export BUILTIN_GAME_DIR_PRESETS=""
    
    result=$(getBuiltInGameDirPreset "1091500")
    
    [[ -z "$result" ]] || {
        echo "Expected empty with empty preset list, got: $result"
        return 1
    }
}

@test "getBuiltInGameDirPreset: handles malformed preset entries gracefully" {
    # Preset with missing pipe separator
    export BUILTIN_GAME_DIR_PRESETS="1091500|bin/x64;corrupted_entry;292030|bin/x64"
    
    # Should still find the valid ones
    result=$(getBuiltInGameDirPreset "1091500")
    [[ "$result" == "bin/x64" ]] || {
        echo "Failed to find valid preset after malformed entry"
        return 1
    }
}
