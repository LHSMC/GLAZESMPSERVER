#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required. This script must run in a Codespace with Docker support." >&2
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 was not found." >&2
  exit 1
fi

mkdir -p plugins/EaglercraftXServer
echo "Building and starting GLAZESMPSERVER (Paper 1.21.1 + EaglerXPaper)..."
docker compose up -d --build
echo
echo "Follow startup output with: docker compose logs -f paper"
echo "Java Edition: <host>:25565"
echo "Eaglercraft: use the forwarded public URL for port 25569."
echo "For an HTTPS-hosted client, use wss:// with a valid TLS/WSS endpoint."
