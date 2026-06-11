# Redmine（含「项目方案属性应用」定制）生产镜像
# 基于 Ruby 3.4.9 + MySQL（mysql2），数据库在独立的 MySQL 容器，附件持久化在 /redmine-data 卷。
FROM ruby:3.4.9-slim-bookworm

ARG DEBIAN_FRONTEND=noninteractive
ENV RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=1 \
    BUNDLE_WITHOUT="development:test" \
    LANG=C.UTF-8 \
    TZ=Asia/Shanghai

# 系统依赖：编译原生 gem（mysql2/ffi/nokogiri 等）、附件缩略图、时区
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      git \
      default-libmysqlclient-dev \
      libffi-dev \
      libyaml-dev \
      pkg-config \
      imagemagick \
      tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /redmine

# 拷贝源码（.dockerignore 已排除 .git/log/tmp/已编译 assets/本地 sqlite 等）
COPY . .

# Docker 专用 database.yml：使用 MySQL（参数走环境变量）
COPY docker/database.yml config/database.yml

# puma 在上游 Gemfile 里只在 test 组，但生产用它做 web 服务器；
# ffi 保留以兼容 rest-client。这里在镜像内自生成 Gemfile.local，
# 不依赖被 git 忽略的本地 Gemfile.local，保证任何环境构建一致。
RUN printf "gem 'puma'\ngem 'ffi'\n" > Gemfile.local

# 安装 gem。Gemfile.lock 原本锁的是 Windows + sqlite3，这里补 Linux 平台，
# 并因 database.yml 改为 mysql2 而解析安装 mysql2 适配器。
RUN bundle config set --local without 'development test' \
    && bundle lock --add-platform x86_64-linux \
    && bundle install --jobs 4 --retry 3

# 预编译静态资源（不连数据库；dummy secret 满足 Rails 8 要求）
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# 持久化数据：上传附件（数据库在独立的 MySQL 容器里）
VOLUME ["/redmine-data"]

COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 3000
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
