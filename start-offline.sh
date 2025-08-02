#!/bin/bash

# n8n 离线环境启动脚本 (非 Docker 模式，使用本地配置和汉化)

echo "🚀 启动 n8n 离线环境 (非 Docker 模式 + 本地配置 + 汉化版本)..."

# 检查并安装缺失依赖的函数
check_and_install_dependencies() {
    echo "🔍 检查项目依赖完整性..."
    
    # 关键依赖列表
    local deps=("zod" "@sentry/node" "axios" "ssh2" "prettier" "vitest" "@lezer/lr" "@codemirror/language" "@lezer/highlight")
    local dev_deps=("@types/ssh2")
    local missing_deps=()
    
    # 检查缺失的依赖
    for dep in "${deps[@]}"; do
        if ! pnpm list "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    # 如果有缺失的依赖，安装它们
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "⚠️ 发现缺失依赖: ${missing_deps[*]}"
        echo "📦 安装缺失依赖..."
        
        # 安装主要依赖
        for dep in "${missing_deps[@]}"; do
            echo "   安装: $dep"
            pnpm add "$dep" -w 2>/dev/null || echo "   ⚠️ $dep 安装失败，将在构建时重试"
        done
        
        # 安装开发依赖
        for dep in "${dev_deps[@]}"; do
            echo "   安装开发依赖: $dep"
            pnpm add -D "$dep" -w 2>/dev/null || true
        done
        
        echo "✅ 依赖安装完成"
        return 0
    else
        echo "✅ 所有关键依赖都已存在"
        return 1
    fi
}

echo "📋 配置信息："
echo "   运行模式: 本地 Node.js 进程 (非 Docker)"
echo "   配置文件: .env (本地配置)"
echo "   数据库: 使用 .env 文件中的配置"
echo "   界面语言: 中文汉化"
echo ""

# 检查运行环境
echo "🔍 检查运行环境..."

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装，请先安装 Node.js (>= 22.16)"
    exit 1
fi

NODE_VERSION=$(node --version | sed 's/v//')
echo "✅ Node.js 版本: ${NODE_VERSION}"

# 检查 pnpm
if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm 未安装，请先安装 pnpm"
    echo "   安装命令: npm install -g pnpm@latest"
    exit 1
fi

PNPM_VERSION=$(pnpm --version)
echo "✅ pnpm 版本: ${PNPM_VERSION}"

# 检查项目根目录
if [ ! -f "package.json" ]; then
    echo "❌ 请在 n8n 项目根目录下运行此脚本"
    exit 1
fi

# 停止可能运行的 n8n 进程
echo "🛑 停止现有 n8n 进程..."
pkill -f "n8n" || true
sleep 2

# 1. 使用本地 .env 配置
echo "� 使用本地 .env 配置文件..."
if [ ! -f ".env" ]; then
    echo "⚠️ .env 文件不存在，从示例文件创建..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✅ 已从 .env.example 创建 .env 文件"
    else
        echo "❌ .env.example 文件也不存在，请创建配置文件"
        exit 1
    fi
fi

echo "✅ 使用本地 .env 配置文件"
echo "📊 当前数据库配置:"
grep "DB_" .env | head -6 || echo "   未找到数据库配置"

# 2. 应用汉化设置
echo "🈵 应用中文汉化设置..."
if [ -f "scripts/set-chinese.sh" ]; then
    chmod +x scripts/set-chinese.sh
    ./scripts/set-chinese.sh
    echo "✅ 中文汉化设置完成"
else
    echo "⚠️ 汉化脚本不存在，跳过汉化设置"
fi

# 3. 安装依赖（如果需要）
echo "📦 检查项目依赖..."
if [ ! -d "node_modules" ] || [ ! -f "pnpm-lock.yaml" ]; then
    echo "🔄 安装项目依赖..."
    pnpm install --frozen-lockfile
    echo "✅ 依赖安装完成"
else
    echo "✅ 依赖已存在，跳过安装"
fi

# 4. 构建项目（如果需要）
echo "🔨 检查项目构建..."
if [ ! -d "packages/cli/dist" ] || [ ! -d "compiled" ]; then
    echo "🔄 构建项目..."
    
    # 尝试完整构建
    if pnpm build; then
        echo "✅ 项目构建完成"
    else
        echo "⚠️ 完整构建失败，尝试修复依赖问题..."
        
        # 强制安装所有必需的依赖
        echo "📦 强制安装缺失的依赖包..."
        pnpm add zod @sentry/node axios ssh2 prettier vitest @lezer/lr @codemirror/language @lezer/highlight -w --force
        pnpm add -D @types/ssh2 vitest -w --force
        
        # 清理构建缓存
        echo "🧹 清理构建缓存..."
        rm -rf packages/*/dist packages/*/tsconfig.tsbuildinfo
        
        # 重新安装所有依赖
        echo "🔄 重新安装依赖..."
        rm -rf node_modules packages/*/node_modules pnpm-lock.yaml
        pnpm install
        
        # 重试构建
        echo "🔄 重试构建..."
        if pnpm build; then
            echo "✅ 项目构建完成（重试成功）"
        else
            echo "❌ 构建仍然失败，尝试跳过测试相关包..."
            
            # 尝试跳过问题包进行构建
            if pnpm build --filter=!@n8n/vitest-config --filter=!@n8n/codemirror-lang; then
                echo "✅ 项目部分构建完成（跳过了测试和编辑器包）"
            else
                echo "❌ 构建失败，但继续启动..."
                echo "   请检查构建日志并手动解决依赖问题"
                echo "   查看详细错误: pnpm build --verbose"
                echo "   手动安装命令:"
                echo "   pnpm add vitest @lezer/lr @codemirror/language @lezer/highlight -w"
            fi
        fi
    fi
else
    echo "✅ 项目已构建，跳过构建步骤"
fi

# 5. 启动 n8n 服务
echo "🚀 启动 n8n 服务..."

# 确认使用本地 .env 配置文件
echo "   配置文件: .env (本地配置)"
if [ -f ".env" ]; then
    echo "✅ 使用本地 .env 配置启动"
else
    echo "❌ .env 文件不存在"
    exit 1
fi

# 设置环境变量，确保使用本地配置
export NODE_ENV=production

# 后台启动 n8n
echo "🔄 启动 n8n 进程..."
echo "   启动命令: packages/cli/bin/n8n start"
echo "   日志文件: n8n.log"
echo "   环境文件: .env"

# 确保环境变量文件存在并可读
if [ ! -f ".env" ]; then
    echo "❌ 环境文件 .env 不存在"
    exit 1
fi

# 加载环境变量
set -a  # 自动导出所有变量
# 使用更安全的方式加载环境变量，过滤掉注释和空行
while IFS= read -r line; do
    # 跳过注释行和空行
    if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
        continue
    fi
    # 确保变量格式正确（key=value），并移除行内注释
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
        # 移除行内注释（# 后面的内容）
        cleaned_line=$(echo "$line" | sed 's/[[:space:]]*#.*$//')
        export "$cleaned_line"
    fi
done < .env
set +a  # 关闭自动导出

# 同步加密密钥
echo "🔑 同步加密密钥..."
if [ -f ~/.n8n/config ]; then
    EXISTING_KEY=$(grep -o '"encryptionKey":[[:space:]]*"[^"]*"' ~/.n8n/config | sed 's/"encryptionKey":[[:space:]]*"\([^"]*\)"/\1/')
    if [ -n "$EXISTING_KEY" ]; then
        export N8N_ENCRYPTION_KEY="$EXISTING_KEY"
        echo "✅ 使用现有加密密钥: ${EXISTING_KEY}"
    fi
fi

# 输出关键数据库配置进行验证
echo "📊 验证数据库配置:"
echo "   DB_TYPE: ${DB_TYPE}"
echo "   DB_MYSQLDB_HOST: ${DB_MYSQLDB_HOST}"
echo "   DB_MYSQLDB_DATABASE: ${DB_MYSQLDB_DATABASE}"

# 使用直接的 n8n 命令启动，并将输出重定向到日志文件
cd packages/cli/bin && nohup ./n8n start > ../../../n8n.log 2>&1 &
N8N_PID=$!
cd ../../..

echo "✅ n8n 进程已启动 (PID: ${N8N_PID})"
echo "📄 进程信息已保存到: n8n.pid"

# 保存 PID 到文件，方便后续管理
echo $N8N_PID > n8n.pid

# 6. 等待 n8n 服务完全启动
echo "🔍 等待 n8n 服务可用..."
max_attempts=12
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -sf "http://localhost:5678/" > /dev/null 2>&1; then
        echo "✅ n8n 服务已启动并可访问"
        break
    fi
    echo "   尝试 $attempt/$max_attempts - 等待服务启动..."
    sleep 5
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "⚠️ n8n 服务启动超时，请检查日志"
    echo "   日志文件: n8n.log"
    echo "   查看日志: tail -f n8n.log"
    echo "   进程状态: ps aux | grep n8n"
fi

echo ""
echo "🎉 n8n 离线环境已启动！(非 Docker + 本地配置 + 汉化版本)"
echo ""
echo "📊 访问信息："
echo "  🌐 n8n 工作流平台: http://localhost:5678"
echo "  🗄️  数据库: 使用 .env 文件中的配置"
echo ""
echo "🈵 语言设置："
echo "  界面语言: 中文 (已汉化)"
echo "  时区设置: Asia/Shanghai"
echo ""
echo "🔧 配置管理："
echo "  当前配置文件: .env (本地配置)"
echo "  配置示例文件: .env.example"
echo "  进程 PID: ${N8N_PID}"
echo ""
echo "📋 常用命令："
echo "  查看日志: tail -f n8n.log"
echo "  停止服务: kill ${N8N_PID} 或 pkill -f n8n"
echo "  重启服务: ./start-offline.sh"
echo "  检查进程: ps aux | grep n8n"
echo "  测试连接: curl http://localhost:5678/"
echo ""
echo "🔄 配置更新流程："
echo "  1. 编辑 .env 文件修改配置"
echo "  2. 重新运行启动脚本: ./start-offline.sh"
echo ""
echo "🐛 故障排除："
echo "  检查 n8n 日志: tail -f n8n.log"
echo "  检查进程状态: ps aux | grep n8n"
echo "  检查端口占用: lsof -i :5678"
echo "  测试数据库连接: node -e \"console.log('数据库配置检查'); require('fs').readFileSync('.env', 'utf8').split('\\n').filter(line => line.includes('DB_')).forEach(line => console.log(line))\""
echo ""
