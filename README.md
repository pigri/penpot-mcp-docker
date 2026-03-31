# 🐳 PenPot MCP Server - Dockerized

A containerized version of the [PenPot MCP Server](https://github.com/montevive/penpot-mcp) that enables AI-powered design workflow automation through Docker containers.

## 🚀 Features

- **Containerized Deployment**: Easy deployment using Docker and Docker Compose
- **Multi-Architecture Support**: Works on AMD64 and ARM64 architectures
- **Production Ready**: Optimized for production with health checks and monitoring
- **Auto-restart**: Container automatically restarts on failures
- **Volume Persistence**: Optional persistent storage for cache and data
- **Redis Integration**: Optional Redis service for improved caching
- **Security Focused**: Runs with non-root user for enhanced security

## 📋 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Penpot account ([Sign up free](https://penpot.app/))

## 🛠️ Quick Start

Docker wrapper around the upstream Penpot MCP monorepo. This repository builds the source in `penpot-mcp-source/` inside a container and runs the upstream `npm run start:all` command.

## ⚙️ What It Runs

The container starts the upstream services on these ports:

- `4400`: plugin manifest server
- `4401`: MCP HTTP endpoint
- `4402`: WebSocket endpoint used by the plugin
- `4403`: REPL/debug server

The image is currently based on `node:22-slim`.

## 📁 Repository Layout

- `Dockerfile`: builds and runs the upstream Node monorepo
- `setup.sh`: clones or updates `penpot-mcp-source`, builds the image, and starts services
- `penpot-mcp-source/`: local upstream checkout used by the Docker build

## Prerequisites

- Docker
- Docker Compose or `docker compose`
- Git

## 🛠️ Quick Start

### Use `setup.sh`

```bash
chmod +x setup.sh
./setup.sh setup
```

This flow:

1. Clones `https://github.com/penpot/penpot-mcp.git` into `penpot-mcp-source/` if needed
2. Updates that checkout when it is already a git repository
3. Builds `penpot-mcp:latest`
4. Starts the configured services

Other commands:

```bash
./setup.sh build
./setup.sh start
./setup.sh help
```

### Build Manually

```bash
git clone https://github.com/penpot/penpot-mcp.git penpot-mcp-source
docker build -t penpot-mcp:latest .
```

Run the container directly:

```bash
docker run --rm \
  --name penpot-mcp-server \
  -p 4400:4400 \
  -p 4401:4401 \
  -p 4402:4402 \
  -p 4403:4403 \
  penpot-mcp:latest
```

## ✅ Verify Startup

Useful endpoints after startup:

- Plugin manifest: `http://localhost:4400/manifest.json`
- MCP endpoint: `http://localhost:4401/mcp`
- Legacy SSE endpoint: `http://localhost:4401/sse`
- WebSocket endpoint: `ws://localhost:4402`

Quick checks:

```bash
curl http://localhost:4400/manifest.json
curl http://localhost:4401/mcp
docker logs penpot-mcp-server
```

## 🐳 Dockerfile Notes

The Docker image:

- copies package manifests first for better layer caching
- installs root and package-level dependencies
- builds the monorepo with `npm run build:all`
- runs as a non-root `penpot` user
- exposes `4400`, `4401`, `4402`, and `4403`

## 🔄 Upstream Source Handling

This repository expects the upstream Penpot MCP source to live in `penpot-mcp-source/`.

`setup.sh` uses:

```bash
git clone https://github.com/penpot/penpot-mcp.git penpot-mcp-source
```

If `penpot-mcp-source/` already exists:

- if it is a git checkout, `setup.sh` updates it
- if it is just a local directory, `setup.sh` leaves it in place and uses it as-is

## 🚨 Troubleshooting

### Rebuild from scratch

```bash
docker build --no-cache -t penpot-mcp:latest .
```

### Update the upstream checkout

```bash
git -C penpot-mcp-source pull --ff-only
```

### Check whether ports are already in use

```bash
lsof -i :4400
lsof -i :4401
lsof -i :4402
lsof -i :4403
```

## 📌 Current Status

This README reflects the current Node-based `penpot-mcp-source` flow, the revised `setup.sh`, and the Docker image ports.

Some ancillary files, especially `docker-compose.yml` and `.env.example`, may still need alignment if you want the entire repository to follow the same `4400`-`4403` runtime model end-to-end.
