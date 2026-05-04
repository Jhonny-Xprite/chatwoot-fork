# --- BASE RUBY IMAGE ---
FROM ruby:3.4.9-slim-bookworm AS ruby-base

ENV BUNDLER_VERSION=2.5.16
ENV BUNDLE_PATH="/gems"
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  git \
  libpq-dev \
  libvips \
  libvips-dev \
  openssl \
  pkg-config \
  postgresql-client \
  tar \
  tzdata \
  xz-utils \
  && gem install bundler -v "$BUNDLER_VERSION" \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# --- GEMS BUILDER ---
FROM ruby-base AS gems-builder

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local path "$BUNDLE_PATH" \
  && bundle config set --local without 'development test' \
  && bundle install --jobs=4 --retry=3 \
  && rm -rf "$BUNDLE_PATH"/ruby/*/cache/*.gem \
  && find "$BUNDLE_PATH"/ruby/*/gems/ \( -name "*.c" -o -name "*.o" \) -delete

# --- ASSETS BUILDER ---
FROM ruby-base AS assets-builder

ARG PNPM_VERSION="10.2.0"
ARG NODE_OPTIONS="--max-old-space-size=4096 --openssl-legacy-provider"
ENV NODE_OPTIONS ${NODE_OPTIONS}
ENV RAILS_ENV=production

# Install Node.js and pnpm
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
  && apt-get install -y nodejs \
  && npm install -g pnpm@${PNPM_VERSION}

WORKDIR /app

# Copy gems for 'rake assets:precompile' as it loads the Rails env
COPY --from=gems-builder /gems /gems
COPY --from=gems-builder /usr/local/bundle /usr/local/bundle

# Configure bundle to find gems
ENV BUNDLE_PATH="/gems"
ENV BUNDLE_WITHOUT="development:test"

# Install node dependencies
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
  HUSKY=0 CI=true pnpm install --frozen-lockfile

# Copy app for asset compilation
COPY . .

# Precompile assets
RUN SECRET_KEY_BASE=precompile_placeholder RAILS_LOG_TO_STDOUT=enabled \
    bundle exec rake assets:precompile

# --- FINAL PRODUCTION IMAGE ---
FROM ruby:3.4.9-slim-bookworm

ENV BUNDLE_PATH="/gems"
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV EXECJS_RUNTIME="Disabled"

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  imagemagick \
  libpq5 \
  libvips \
  openssl \
  postgresql-client \
  tzdata \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy gems and app code
COPY --from=gems-builder /gems /gems
COPY --from=gems-builder /usr/local/bundle /usr/local/bundle
COPY . .

# Copy precompiled assets
COPY --from=assets-builder /app/public/vite ./public/vite
COPY --from=assets-builder /app/public/assets ./public/assets

# Remove unnecessary files to keep image small
RUN rm -rf spec node_modules tmp/cache .git .dockerignore .aios squads

# Generate .git_sha file
RUN if [ -d .git ]; then git rev-parse HEAD > .git_sha; fi

EXPOSE 3000

CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
