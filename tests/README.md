# ReShade Linux Test Suite

The maintained automated test path is the shell runner in `run_simple_tests.sh`.

## Run tests

```bash
bash tests/run_simple_tests.sh
```

## Files

- `run_simple_tests.sh` - main regression suite used locally and in CI
- `fixtures.sh` - isolated temp Steam, cache, and shader fixture helpers
- `test_functions.sh` - mirrored pure-shell helpers extracted from `reshade-linux.sh`

## Coverage

The current shell suite covers:

- executable selection and utility filtering
- Steam icon lookup priority
- UI backend selection across YAD, terminal UI, and CLI fallback
- explicit `UI_BACKEND` override handling and validation
- built-in and custom install-directory resolution
- scan fallback for nested executable layouts when heuristic directories do not match
- per-game state read/write behavior
- installed-state verification against the actual DLL on disk
- malformed state file rejection when required keys are missing
- shader repo selection and per-game merged shader directory rebuilds
- per-game `ReShade.ini` generation
- parsing of the current `SHADER_REPOS` format with optional branch and description fields
- release metadata sync between `VERSION` and the current `CHANGELOG.md` entry

## Design notes

- Tests run in isolated temporary directories and do not touch the real Steam install.
- `HOME`, `XDG_CACHE_HOME`, and `MAIN_PATH` are redirected into the fixture tree for each test.
- `test_functions.sh` must stay behaviorally aligned with the production functions it mirrors.
- When adding a new regression test, update both `run_simple_tests.sh` and `test_functions.sh` if the production logic is mirrored there.

## CI

The repository CI runs:

```bash
bash tests/run_simple_tests.sh
```

See `.github/workflows/ci.yml` for the exact job definition.

## Adding tests

Use `fixtures.sh` to build isolated Steam libraries, icons, game directories, and shader repos. Prefer targeted regression tests that exercise one decision point at a time.

Example:

```bash
test_my_new_case() {
    local game_dir="$TEST_GAMES_DIR/MyGame"
    mkdir -p "$game_dir/bin/x64"
    touch "$game_dir/bin/x64/MyGame.exe"

    [[ "$(resolveGameInstallDir "$game_dir" "777888")" == "$game_dir/bin/x64|heuristic" ]]
}
```

## Troubleshooting

If a test fails, run the suite directly to see the failing test name:

```bash
bash tests/run_simple_tests.sh
```

If scripts lose their executable bit locally:

```bash
chmod +x tests/*.sh
```

## License

Same as the parent project. See `LICENSE` in the repository root.
