#!/bin/bash
set -euo pipefail
outposts_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
printf '%s\n' '魔兽指挥官 · 金矿据点版 V4' \
  '固定建筑空位：点击地图空位 → 查看费用 → 确认施工；无需工人。' \
  '仅金币一种资源：完整占领＋完工基地/矿场后自动采金。' \
  '三族首发：21种正规兵、24名英雄、12项特色科技；素材需自行合法安装。'
exec bash "$outposts_dir/launch-mac.command" "$@"
