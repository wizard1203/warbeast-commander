#!/bin/bash
# Double-click in Finder, or run from any directory in Terminal.
set -euo pipefail

game_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
godot_executable="${GODOT_BIN:-}"

if [[ -z "$godot_executable" ]]; then
    for candidate in \
        "$HOME/Library/Caches/Codex/warbeast-commander/godot-4.7.2/Godot.app/Contents/MacOS/Godot" \
        "/Applications/Godot.app/Contents/MacOS/Godot" \
        "$HOME/Applications/Godot.app/Contents/MacOS/Godot"; do
        if [[ -x "$candidate" && ! -d "$candidate" ]]; then
            godot_executable="$candidate"
            break
        fi
    done
    if [[ -z "$godot_executable" ]]; then
        godot_executable="$(command -v godot || command -v godot4 || true)"
    fi
fi

if [[ -z "$godot_executable" || ! -x "$godot_executable" || -d "$godot_executable" ]]; then
    printf '%s\n' \
        '未找到 Godot。请安装 Godot 4.7.2 Standard 到 /Applications/Godot.app，' \
        '或用 GODOT_BIN 指定 Godot 可执行文件的绝对路径后重试。' >&2
    exit 127
fi

if [[ ! -f "$game_dir/project.godot" ]]; then
    printf '找不到游戏项目：%s/project.godot\n请把此脚本放回游戏目录。\n' "$game_dir" >&2
    exit 1
fi

printf '启动魔兽指挥官：%s\nGodot：%s\n' "$game_dir" "$godot_executable"
exec "$godot_executable" --path "$game_dir" "$@"
