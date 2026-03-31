FROM node:22-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY penpot-mcp-source/package*.json ./penpot-mcp-source/
COPY penpot-mcp-source/common/package*.json ./penpot-mcp-source/common/
COPY penpot-mcp-source/mcp-server/package*.json ./penpot-mcp-source/mcp-server/
COPY penpot-mcp-source/penpot-plugin/package*.json ./penpot-mcp-source/penpot-plugin/

WORKDIR /app/penpot-mcp-source
RUN npm install && npm run install:all

COPY penpot-mcp-source/ ./
RUN npm run build:all

RUN useradd --create-home --shell /bin/bash penpot && \
    chown -R penpot:penpot /app
USER penpot

EXPOSE 4400 4401 4402 4403

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD node -e "fetch('http://127.0.0.1:4401/mcp').then((res) => process.exit(res.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["npm", "run", "start:all"]
