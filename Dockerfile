# syntax = docker/dockerfile:1

# Ruby version debe coincidir con .ruby-version
ARG RUBY_VERSION=3.3.4
FROM ruby:$RUBY_VERSION-slim

# Directorio de trabajo
WORKDIR /rails

# Instalar paquetes base necesarios
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    default-mysql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Variables de entorno para producción
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Build stage para compilar gems y assets
FROM ruby:$RUBY_VERSION-slim AS build

WORKDIR /rails

# Instalar paquetes necesarios para compilar gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    pkg-config \
    default-libmysqlclient-dev \
    libmagickwand-dev \
    libvips-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copiar e instalar gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copiar código de la aplicación
COPY . .

# Precompilar bootsnap para arranque más rápido
RUN bundle exec bootsnap precompile app/ lib/

# Precompilar assets sin necesitar RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Stage final - imagen limpia y pequeña
FROM ruby:$RUBY_VERSION-slim

WORKDIR /rails

# Instalar solo runtime dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    default-mysql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Variables de entorno
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Copiar artifacts del build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Crear usuario no-root
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint para preparar la base de datos
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Exponer puerto
EXPOSE 3000

# Comando de inicio
CMD ["./bin/rails", "server"]
