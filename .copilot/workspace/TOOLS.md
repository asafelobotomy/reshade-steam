# Tool Usage Patterns — reshade-steam

| Tool / command | Effective usage pattern |
| -------------- | ----------------------- |
| `bash tests/run_simple_tests.sh` | Run after every change; treat red as blocking |
| `bash tests/run_simple_tests.sh && shellcheck lib/*.sh reshade-linux.sh` | Three-check ritual — run before marking a task done |
| `shellcheck lib/*.sh reshade-linux.sh` | Run after every type definition change |
| `wc -l lib/*.sh reshade-linux.sh reshade-linux-gui.sh` | Measure LOC delta before and after refactors |

Note: Update this file when a workflow proves repeatably useful.
