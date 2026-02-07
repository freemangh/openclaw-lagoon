# Stage 1: Install openclaw (skip native builds for local LLM - not needed with API providers)
FROM uselagoon/node-22-builder:latest AS builder

# Install git (required by npm for some dependencies)
RUN apk add --no-cache git

# Install openclaw globally, skipping postinstall scripts that build native code
# This disables local LLM support (node-llama-cpp) but works fine with API providers like amazeeai
ARG OPENCLAW_VERSION=2026.2.1
RUN npm install -g --ignore-scripts openclaw@${OPENCLAW_VERSION}

# Run only the essential postinstall scripts (not node-llama-cpp)
RUN cd /usr/local/lib/node_modules/openclaw && node scripts/postinstall.js || true

# Verify installation
RUN openclaw --version

# Stage 2: Runtime image (smaller, no build tools)
FROM uselagoon/node-22:latest

# Install git (needed at runtime for some skills)
RUN apk add --no-cache git bash curl

# Install pnpm globally (needed by some openclaw skills)
RUN npm install -g pnpm

# Copy globally installed openclaw from builder and create symlink
COPY --from=builder /usr/local/lib/node_modules/openclaw /usr/local/lib/node_modules/openclaw
RUN ln -s /usr/local/lib/node_modules/openclaw/openclaw.mjs /usr/local/bin/openclaw

# Verify installation
RUN openclaw --version

# Optional: extra Alpine packages for browser automation or other needs
ARG EXTRA_APK_PACKAGES=""
RUN if [ -n "$EXTRA_APK_PACKAGES" ]; then \
      apk add --no-cache $EXTRA_APK_PACKAGES; \
    fi

# Copy Lagoon entrypoint scripts
# 50-shell-config.sh: Custom bash prompt with lobster branding
# 60-amazeeai-config.sh: Model discovery from amazee.ai
COPY .lagoon/50-shell-config.sh /lagoon/entrypoints/50-shell-config.sh
COPY .lagoon/60-amazeeai-config.sh /lagoon/entrypoints/60-amazeeai-config.sh

# Create data directories for persistent config and npm global packages
RUN mkdir -p /home/.openclaw /home/.openclaw/npm \
    && fix-permissions /home/.openclaw

# pnpm and npm configuration - use writable directories to avoid permission issues
# Cache in /tmp (ephemeral), global prefix in /home/.openclaw (persistent)
ENV NODE_ENV=production \
    OPENCLAW_GATEWAY_PORT=3000 \
    XDG_DATA_HOME=/home/.openclaw/.local/share/ \
    PNPM_HOME=/home/.openclaw/.local/share/pnpm \
    npm_config_cache=/tmp/.npm \
    npm_config_prefix=/home/.openclaw/npm \
    PATH="/home/.openclaw/npm/bin:/home/.openclaw/.local/share/pnpm:$PATH" \
    LAGOON=openclaw

WORKDIR /home/.openclaw

# Port 3000 already exposed by base image
CMD ["openclaw", "gateway", "--bind", "lan"]
