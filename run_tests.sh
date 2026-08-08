#!/bin/bash
# 星光花园 - 测试运行脚本

echo "====================================="
echo "   星光花园 - 测试套件"
echo "====================================="
echo ""

# 项目目录
PROJECT_DIR="/Users/jacklee/workspace/starlight-garden"
GODOT_BIN="${GODOT_BIN:-$(command -v godot4 || command -v godot || true)}"

if [ -z "$GODOT_BIN" ]; then
    echo "❌ Godot未找到，请设置 GODOT_BIN 或将 godot4/godot 加入 PATH"
    exit 1
fi

echo "✅ Godot已安装: $GODOT_BIN"
echo ""

# 检查测试文件
if [ ! -f "$PROJECT_DIR/tests/TestRunner.gd" ]; then
    echo "❌ 测试文件不存在"
    exit 1
fi

echo "✅ 测试文件就绪"
echo ""

# 运行测试
echo "🚀 运行测试..."
echo ""

# 使用Godot运行测试场景
set +e
"$GODOT_BIN" --headless --path "$PROJECT_DIR" "res://tests/test_scene.tscn" 2>&1
TEST_EXIT_CODE=$?
set -e

echo ""
echo "====================================="
echo "   测试完成"
echo "====================================="
exit $TEST_EXIT_CODE
