# NanoClaw Agent Container
# Runs Claude Agent SDK in isolated Linux VM with browser automation

FROM node:22-slim

# Install system dependencies for Chromium and PDF tools
RUN echo 'Acquire::http::Pipeline-Depth "0";' > /etc/apt/apt.conf.d/99fixbadproxy \
    && for i in 1 2 3 4 5; do \
         apt-get clean && apt-get update && apt-get install -y \
             chromium \
             fonts-liberation \
             fonts-noto-cjk \
             fonts-noto-color-emoji \
             libgbm1 \
             libnss3 \
             libatk-bridge2.0-0 \
             libgtk-3-0 \
             libx11-xcb1 \
             libxcomposite1 \
             libxdamage1 \
             libxrandr2 \
             libpangocairo-1.0-0 \
             libcups2 \
             libdrm2 \
             libxshmfence1 \
             curl \
             git \
             poppler-utils \
         && break || { echo "apt attempt $i failed, retrying..."; sleep 2; }; \
       done \
    && rm -rf /var/lib/apt/lists/*

# Chromium wrapper — adds flags required for headless rendering in Docker:
# --no-sandbox: required for non-root or unprivileged containers
# --disable-gpu: no GPU in container, prevents blank screenshots
# --disable-dev-shm-usage: /dev/shm is small in Docker, use /tmp instead
# --disable-software-rasterizer: avoids fallback to broken SW rasterizer
RUN printf '#!/bin/bash\nexec /usr/bin/chromium --no-sandbox --disable-gpu --disable-dev-shm-usage --disable-software-rasterizer "$@"\n' \
    > /usr/local/bin/chromium-headless && chmod +x /usr/local/bin/chromium-headless

# Set Chromium path for agent-browser
ENV AGENT_BROWSER_EXECUTABLE_PATH=/usr/local/bin/chromium-headless
ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/local/bin/chromium-headless

# Install agent-browser and claude-code globally
RUN npm install -g agent-browser @anthropic-ai/claude-code

# Create app directory
WORKDIR /app

# Copy package files first for better caching
COPY agent-runner/package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY agent-runner/ ./

# Build TypeScript
RUN npm run build

# Install pdf-reader CLI
COPY skills/pdf-reader/pdf-reader /usr/local/bin/pdf-reader
RUN chmod +x /usr/local/bin/pdf-reader

# Create workspace directories
RUN mkdir -p /workspace/group /workspace/global /workspace/extra /workspace/ipc/messages /workspace/ipc/tasks /workspace/ipc/input

# Create entrypoint script
# Container input (prompt, group info) is passed via stdin JSON.
# Credentials are injected by the host's credential proxy — never passed here.
# Follow-up messages arrive via IPC files in /workspace/ipc/input/
RUN printf '#!/bin/bash\nset -e\ncd /app && npx tsc --outDir /tmp/dist 2>&1 >&2\nln -s /app/node_modules /tmp/dist/node_modules\nchmod -R a-w /tmp/dist\ncat > /tmp/input.json\nnode /tmp/dist/index.js < /tmp/input.json\n' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Set ownership to node user (non-root) for writable directories
RUN chown -R node:node /workspace && chmod 777 /home/node

# Switch to non-root user (required for --dangerously-skip-permissions)
USER node

# Set working directory to group workspace
WORKDIR /workspace/group

# Entry point reads JSON from stdin, outputs JSON to stdout
ENTRYPOINT ["/app/entrypoint.sh"]
