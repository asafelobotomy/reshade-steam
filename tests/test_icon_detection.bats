#!/usr/bin/env bats
# Tests for findSteamIconPath() function
# Validates icon discovery and 3-tier lookup priority

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

@test "findSteamIconPath: finds logo.png (first priority)" {
    create_cities_skylines_test
    
    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "255710")
    
    [[ "$result" == *"logo.png" ]] || {
        echo "Expected logo.png in result, got: $result"
        return 1
    }
}

@test "findSteamIconPath: returns hash-named jpg over header.jpg" {
    local appid="255710"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    mkdir -p "$cache_dir"
    
    # Create only hash-named jpg and header.jpg (no logo.png)
    echo "mini icon" > "$cache_dir/hash123abc.jpg"
    echo "banner" > "$cache_dir/header.jpg"
    
    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    
    [[ "$result" == *"hash123abc.jpg" ]] || {
        echo "Expected hash-named jpg, got: $result"
        return 1
    }
}

@test "findSteamIconPath: skips library_*.jpg files" {
    local appid="255710"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    mkdir -p "$cache_dir"
    
    # Create library files (should be skipped)
    echo "library content" > "$cache_dir/library_600x900.jpg"
    echo "library content" > "$cache_dir/library_hero.jpg"
    
    # Create valid icon
    echo "actual icon" > "$cache_dir/abc123def.jpg"
    
    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    
    # Should find the non-library jpg
    [[ "$result" == *"abc123def.jpg" ]] || {
        echo "Expected non-library jpg, got: $result"
        return 1
    }
}

@test "findSteamIconPath: returns header.jpg as fallback" {
    local appid="999888"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    mkdir -p "$cache_dir"
    
    # Only header.jpg available
    echo "banner" > "$cache_dir/header.jpg"
    
    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    
    [[ "$result" == *"header.jpg" ]] || {
        echo "Expected header.jpg fallback, got: $result"
        return 1
    }
}

@test "findSteamIconPath: returns empty string if no icons found" {
    local appid="111222"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    mkdir -p "$cache_dir"
    
    # Create cache dir but no icon files
    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    
    [[ -z "$result" ]] || {
        echo "Expected empty string, got: $result"
        return 1
    }
}

@test "findSteamIconPath: handles missing cache directory" {
    local appid="nonexistent"
    
    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    
    [[ -z "$result" ]] || {
        echo "Expected empty string for missing dir, got: $result"
        return 1
    }
}

@test "findSteamIconPath: prioritizes actual icons over banners" {
    local appid="333444"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    mkdir -p "$cache_dir"
    
    # Create all types
    echo "logo" > "$cache_dir/logo.png"
    echo "mini" > "$cache_dir/hash456.jpg"
    echo "banner" > "$cache_dir/header.jpg"
    
    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    
    # Should prefer logo.png (first in priority)
    [[ "$result" == *"logo.png" ]] || {
        echo "Expected logo.png at priority, got: $result"
        return 1
    }
}

@test "findSteamIconPath: uses persistent cache when available" {
    local appid="555666"
    
    # Create icon in persistent cache
    echo "cached icon" > "$TEST_ICON_CACHE/555666.jpg"
    
    # Even without Steam cache, should find it
    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    
    [[ "$result" == *"555666"* ]] || {
        echo "Expected to find cached icon, got: $result"
        return 1
    }
}

@test "findSteamIconPath: handles relative and absolute paths" {
    local appid="255710"
    local cache_dir="$TEST_STEAM_CACHE/$appid"
    mkdir -p "$cache_dir"
    echo "icon" > "$cache_dir/logo.png"
    
    # Test with absolute path
    result=$(findSteamIconPath "$TEST_STEAM_ROOT" "$appid")
    
    [[ -n "$result" ]] || {
        echo "Failed with absolute path"
        return 1
    }
}
