#!/bin/bash
# Open-source arena; missing private audio uses the explicit silent policy.
set -euo pipefail
game_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$game_dir/launch-mac.command" --script res://tools/release_media/arena_bootstrap.gd "$@"
