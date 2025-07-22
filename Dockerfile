# Etapa de construcción
FROM ruby:3.3.3-slim AS builder

WORKDIR /rails

# Instalamos todas las dependencias necesarias, incluyendo las de red
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    default-libmysqlclient-dev \
    libvips \
    pkg-config \
    libyaml-dev \
    libssl-dev \
    zlib1g-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar Gemfile y instalar dependencias
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copiar el resto de la aplicación
COPY . .

# Precompilar assets
RUN bundle exec rails assets:precompile

# Etapa de producción
FROM ruby:3.3.3-slim AS production

WORKDIR /rails

# Instalamos solo las dependencias necesarias para ejecutar la aplicación
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    default-libmysqlclient-dev \
    libvips \
    && rm -rf /var/lib/apt/lists/*

# Configurar variables de entorno para producción
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true

# Copiar gemas y aplicación desde la etapa de construcción
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /rails /rails

# Exponer puerto
EXPOSE 3000

# Comando para iniciar la aplicación
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
