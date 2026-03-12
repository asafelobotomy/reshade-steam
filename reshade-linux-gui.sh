#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export UI_BACKEND=yad

exec "$HERE/reshade-linux.sh" "$@"