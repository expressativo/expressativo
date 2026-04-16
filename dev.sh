#!/usr/bin/env bash
set -e

export RAILS_ENV=development

REQUIRED_RUBY=$(cat .ruby-version)
CURRENT_RUBY=$(ruby -e 'puts RUBY_VERSION' 2>/dev/null || echo "none")

if [ "$CURRENT_RUBY" != "$REQUIRED_RUBY" ]; then
  echo "==> Ruby $REQUIRED_RUBY requerido (actual: $CURRENT_RUBY). Instalando con mise..."
  mise install
  eval "$(mise activate bash)"
fi

echo "==> Usando Ruby $(ruby -e 'puts RUBY_VERSION')"

echo "==> Verificando dependencias del sistema..."
if [[ "$(uname)" == "Darwin" ]]; then
  for pkg in zstd openssl@3 mysql; do
    if ! brew list "$pkg" &>/dev/null; then
      echo "==> Instalando $pkg..."
      brew install "$pkg"
    fi
  done
  bundle config build.mysql2 \
    --with-ldflags="-L$(brew --prefix zstd)/lib -L$(brew --prefix openssl@3)/lib" \
    --with-cppflags="-I$(brew --prefix zstd)/include -I$(brew --prefix openssl@3)/include"
else
  sudo apt-get update -qq
  sudo apt-get install -y -qq libmysqlclient-dev libzstd-dev libssl-dev
fi

echo "==> Instalando gemas..."
bundle install

echo "==> Levantando base de datos MySQL con Docker..."
docker-compose -f local.yml up -d

echo "==> Esperando a que MySQL esté listo..."
until docker-compose -f local.yml exec -T db mysqladmin ping -h 127.0.0.1 -u root -proot --silent 2>/dev/null; do
  sleep 1
done
echo "==> MySQL listo."

echo "==> Preparando base de datos..."
bin/rails db:create 2>/dev/null || true
bin/rails db:migrate

echo "==> Levantando servidor de desarrollo..."
bin/dev
