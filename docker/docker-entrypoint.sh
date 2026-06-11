#!/bin/bash
set -e

DATA_DIR=/redmine-data
DB_HOST="${REDMINE_DB_HOST:-db}"
DB_PORT="${REDMINE_DB_PORT:-3306}"

# 1) 准备持久化目录（上传附件存这里）
mkdir -p "$DATA_DIR" "$DATA_DIR/files"

# 2) 把上传附件目录指向持久化卷
rm -rf /redmine/files
ln -s "$DATA_DIR/files" /redmine/files

# 3) 持久化 secret_key_base（保证重启后已登录会话不失效）
if [ -z "$SECRET_KEY_BASE" ]; then
  if [ ! -f "$DATA_DIR/secret_key_base" ]; then
    echo "[entrypoint] 生成 secret_key_base ..."
    bundle exec rails secret > "$DATA_DIR/secret_key_base"
  fi
  export SECRET_KEY_BASE="$(cat "$DATA_DIR/secret_key_base")"
fi

# 4) 等待 MySQL 端口就绪（compose 的 healthcheck 已确保库可用，这里再保险一次）
echo "[entrypoint] 等待 MySQL ${DB_HOST}:${DB_PORT} ..."
for i in $(seq 1 60); do
  if ruby -e "require 'socket'; TCPSocket.new('${DB_HOST}', ${DB_PORT}).close" >/dev/null 2>&1; then
    echo "[entrypoint] MySQL 已就绪"
    break
  fi
  sleep 2
done

# 5) 跑数据库迁移（幂等；首次会从零建好全部表，含「项目方案属性应用」相关迁移）
echo "[entrypoint] 执行数据库迁移 ..."
bundle exec rails db:migrate

# 6) 全新空库：自动加载 Redmine 默认数据（角色/状态/跟踪标签/优先级等，中文）
if [ "$(bundle exec rails runner 'print(Tracker.any? ? "no" : "yes")' 2>/dev/null)" = "yes" ]; then
  echo "[entrypoint] 检测到空库，加载默认数据（REDMINE_LANG=zh）..."
  bundle exec rake redmine:load_default_data REDMINE_LANG=zh
fi

echo "[entrypoint] 启动应用 ..."
exec "$@"
