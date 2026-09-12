#!/bin/bash
# 星光花园 - Harness 回归入口

set -e

PROJECT_DIR="/Users/jacklee/workspace/starlight-garden"
GODOT_BIN="${GODOT_BIN:-$(command -v godot4 || command -v godot || true)}"
HARNESS_HOME="${HARNESS_HOME:-/tmp/starlight-garden-godot-home}"

if [ -z "$GODOT_BIN" ]; then
    echo "Godot 未找到，请设置 GODOT_BIN 或将 godot4/godot 加入 PATH"
    exit 1
fi

export HOME="$HARNESS_HOME"
export XDG_DATA_HOME="$HARNESS_HOME"
export XDG_CONFIG_HOME="$HARNESS_HOME"

echo "====================================="
echo "   星光花园 - Harness 回归"
echo "====================================="
echo "Godot: $GODOT_BIN"
echo "Project: $PROJECT_DIR"
echo ""

echo "0/4 coding-harness 漂移检查"
"$PROJECT_DIR/harness" check --manifest "$PROJECT_DIR/harness.manifest.json"
echo ""

echo "1/4 导入新增项目资源"
"$GODOT_BIN" --headless --editor --path "$PROJECT_DIR" --quit

echo ""
echo "2/4 运行 Harness 结构与目标检查"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --script "res://scripts/tools/harness_check.gd"

echo ""
echo "3/4 运行 Godot 自动化测试"
"$PROJECT_DIR/run_tests.sh"

echo ""
echo "====================================="
echo "   Harness 回归通过"
echo "====================================="
