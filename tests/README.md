# ReShade Linux Test Suite

Comprehensive automated test coverage for the ReShade Linux game detection engine.

## Overview

This test suite validates:
- **Game executable detection** with blacklist filtering and scoring
- **Icon discovery** with 3-tier lookup priority
- **Built-in game presets** for known titles
- **Full detection pipeline** integration tests

## Architecture

### Test Files

- **`test_exe_detection.bats`** - Tests game executable selection logic
  - Filters utility programs (crash handlers, installers, etc.)
  - Scores based on parent folder name matching
  - Evaluates architecture keywords (x64, win32, etc.)
  - Handles edge cases (no exes, single-char names)

- **`test_icon_detection.bats`** - Tests icon discovery pipeline
  - Priority lookup: logo.png → hash-named jpg → header.jpg
  - Skips library_*.jpg files
  - Handles missing icons gracefully
  - Tests persistent caching

- **`test_presets.bats`** - Tests built-in game presets
  - Cyberpunk 2077 → bin/x64
  - Witcher 3 → bin/x64
  - No Man's Sky → Binaries
  - Elden Ring → Game
  - Unknown AppID fallback

- **`test_integration.bats`** - End-to-end pipeline tests
  - Multiple games processed independently
  - Preset overrides generic detection
  - Games without presets handled gracefully
  - Complex utility filtering scenarios

### Test Fixtures

`fixtures.sh` provides:
- `setup_test_env()` / `teardown_test_env()` - Temporary Steam mock structures
- `create_mock_game()` - Creates game with ACF manifest and exes
- `create_mock_icon()` - Creates Steam icon cache for games
- `create_*_test()` - Pre-built scenarios (Warhammer, Cities Skylines, etc.)
- Helper assertions (`assert_exe_selected()`, `assert_icon_found()`, etc.)

## Running Tests

### Quick Start

```bash
# Run all tests
./tests/run_tests.sh

# Install BATS first time
./tests/run_tests.sh --install-bats

# Run with verbose output
./tests/run_tests.sh --verbose
```

### Individual Test Files

```bash
# Run specific test file
bats tests/test_exe_detection.bats

# Run single test
bats tests/test_exe_detection.bats --filter "pickBestExeInDir"
```

### From Build System

```bash
# Build with tests
make test

# Or with appimage build script
./appimage/build.sh test
```

## Test Coverage

### Game Executable Detection (test_exe_detection.bats)

| Test | Purpose |
|------|---------|
| Multi-exe games | Warhammer 40K selects WH40KRT.exe over UnityCrashHandler64.exe |
| Utility filtering | Removes UnityPlayer, EasyAntiCheat, setup.exe, etc. |
| Name matching | Prefers exe with name matching parent folder |
| Architecture scoring | x64/win64 versions score higher |
| Keyword bonuses | "game", "engine", "client" increase score |
| Generic names | Single-char names penalized |
| Case insensitivity | All matching is case-insensitive |
| No exes | Handles empty directories gracefully |

### Icon Detection (test_icon_detection.bats)

| Test | Purpose |
|------|---------|
| Priority chain | logo.png > hash-named jpg > header.jpg |
| Library exclusion | Skips library_600x900.jpg and similar |
| Fallback handling | header.jpg used when no icon found |
| Missing directory | Returns empty string safely |
| Persistent cache | Uses ~/.cache/reshade-linux/icons/ |
| Partial cache | Works with incomplete icon sets |

### Presets (test_presets.bats)

| Test | Purpose |
|------|---------|
| Known games | All 4 built-in presets return correct paths |
| Unknown games | Unknown AppID returns empty safely |
| Consistency | Repeated calls return same value |
| Malformed entries | Handles corrupted preset list gracefully |
| Empty presets | Works with unset BUILTIN_GAME_DIR_PRESETS |

### Integration (test_integration.bats)

| Test | Purpose |
|------|---------|
| Full pipeline | Exe + Icon detection for real games |
| Preset override | Preset takes priority over generic detection |
| Generic games | Non-preset games detected correctly |
| Complex utilities | Multiple utilities filtered correctly |
| Isolation | Tests don't interfere with each other |
| Partial data | Works when some data is missing |

## Test Data

### Mock Steam Structure

Tests create temporary structures like:

```
/tmp/test.XXXXX/
├── Steam/
│   └── appcache/librarycache/
│       ├── 255710/          # Cities Skylines
│       │   ├── logo.png
│       │   ├── hash*.jpg    # Actual 32×32 icon
│       │   └── header.jpg   # Banner fallback
│       └── 2021390/         # Warhammer 40K
│           └── ...
├── steamapps/
│   ├── common/
│   │   ├── Warhammer 40,000 Rogue Trader/
│   │   │   ├── WH40KRT.exe
│   │   │   └── UnityCrashHandler64.exe
│   │   └── Cities_Skylines/
│   │       └── Cities.exe
│   ├── appmanifest_255710.acf
│   └── appmanifest_2021390.acf
└── .cache/reshade-linux/icons/
    └── [persistent icon cache]
```

## Dependencies

- **BATS Core** - Bash testing framework
  - Auto-installed by `run_tests.sh` if missing
  - Supports: Linux, macOS (via brew)

- **Bash 4+** - Required for associative arrays and `[[` conditionals

- **Standard Unix tools** - find, grep, sed, awk, mkdir, etc.

## Implementation Notes

### How Functions Are Tested

Tests **source functions directly** from the main script:

```bash
# In fixtures.sh or test files
source "$(dirname "$BATS_TEST_FILENAME")/../reshade-linux.sh"

# Then call functions with test data
result=$(pickBestExeInDir "$TEST_GAME_DIR")
```

### Mock Game Creation

The `create_mock_game()` function:
1. Creates game directory in $TEST_GAMES_DIR
2. Creates one or more .exe files
3. Creates ACF manifest with metadata
4. Sets up icon cache if needed

### Test Isolation

Each test:
1. Calls `setup()` which creates fresh temporary environment
2. Runs with isolated paths (not affecting real Steam)
3. Calls `teardown()` which removes temp files

## Extending Tests

### Adding a New Test

```bash
# Add to test_exe_detection.bats
@test "pickBestExeInDir: [scenario description]" {
    # Setup
    create_mock_game "Game Name" "123456" "exe1.exe" "exe2.exe"
    local game_dir="$TEST_GAMES_DIR/Game Name"
    
    # Execute
    result=$(pickBestExeInDir "$game_dir")
    
    # Verify
    [[ "$result" == "exe1.exe" ]] || {
        echo "Expected 'exe1.exe' but got '$result'"
        return 1
    }
}
```

### Adding a New Scenario

```bash
# Add to fixtures.sh
create_my_custom_game() {
    create_mock_game "My Game" "777888" \
        "game.exe" \
        "launcher.exe"
    create_mock_icon "777888"
}

# Use in tests
@test "my test" {
    create_my_custom_game
    # ... test code
}
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: ./tests/run_tests.sh
```

### GitLab CI

```yaml
test:
  script:
    - ./tests/run_tests.sh
  artifacts:
    reports:
      junit: test-results.xml
```

## Troubleshooting

### BATS not found
```bash
./tests/run_tests.sh --install-bats
```

### Test timeout
Tests typically complete in <1 second each. If slow:
- Check disk space
- Verify /tmp is not full
- Check CPU load

### Permission errors
Ensure scripts are executable:
```bash
chmod +x tests/*.sh
```

### Individual test fails
Run with verbose output:
```bash
bats tests/test_exe_detection.bats --verbose
```

## Future Enhancements

- [ ] Steam library discovery tests (`listSteamAppsDirs()`)
- [ ] Game picker UI tests (CLI path handling)
- [ ] Download/caching tests (CDN fallback)
- [ ] Proton/runtime filtering tests
- [ ] Performance benchmarks
- [ ] Coverage report generation (nyc/istanbul equivalent)
- [ ] Parallel test execution
- [ ] Property-based testing (generative test cases)

## License

Same as ReShade Linux wrapper (see parent LICENSE)
