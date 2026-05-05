#!/bin/bash
# 星光花园 - 项目启动脚本

echo "====================================="
echo "   星光花园 - Starlight Garden"
echo "====================================="
echo ""

# 检查Godot是否安装
if ! command -v godot &> /dev/null; then
    echo "❌ Godot未找到，请先安装Godot 4.x"
    echo "   下载地址: https://godotengine.org/download"
    exit 1
fi

echo "✅ Godot已安装"
echo ""

# 项目目录
PROJECT_DIR="/Users/jacklee/workspace/starlight-garden"

# 检查项目目录
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

echo "✅ 项目目录: $PROJECT_DIR"
echo ""

# 列出项目文件
echo "📁 项目结构:"
echo "   ├── scripts/      # 脚本文件"
echo "   ├── scenes/       # 场景文件"
echo "   ├── assets/       # 资源文件"
echo "   └── levels/       # 关卡配置"
echo ""

# 启动Godot
echo "🚀 正在启动Godot..."
echo ""

# 使用Godot打开项目
open -a "Godot" "$PROJECT_DIR/project.godot"

echo "✨ Godot已启动！"
echo ""
echo "📖 快速开始:"
echo "   1. 在Godot中打开项目"
echo "   2. 按 F5 运行游戏"
echo "   3. 或点击右上角 ▶️ 播放按钮"
echo ""
echo "🎯 测试功能:"
echo "   - 主菜单界面"
echo "   - 开始游戏"
echo "   - 新手引导"
echo "   - 消除玩法"
echo "   - 花园界面"
echo "   - 设置界面"
echo ""
echo "====================================="
echo "   祝开发顺利！🌸"
echo "====================================="
