#!/bin/bash

# n8n 启动脚本 - 使用本地 MySQL 数据库

echo "配置 n8n 使用本地 MySQL 数据库..."

# 设置数据库配置
export DB_TYPE=mysqldb
export DB_MYSQLDB_HOST=localhost
export DB_MYSQLDB_PORT=3306
export DB_MYSQLDB_DATABASE=n8n
export DB_MYSQLDB_USER=root
export DB_MYSQLDB_PASSWORD=your_mysql_password

# 启动 n8n
echo "启动 n8n..."
pnpm start

# 或者使用开发模式
# pnpm dev
