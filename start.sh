#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required. Install Docker Engine/Desktop and the Compose plugin first." >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose plugin was not found. Install Docker Compose v2." >&2
  exit 1
fi

mkdir -p plugins/EaglercraftXServer

# Ensure the script itself is executable when launched through a shell.
if [ "${EULA:-TRUE}" != "TRUE" ]; then
  echo "EULA must be TRUE to start the Minecraft server. Review https://www.minecraft.net/eula." >&2
  exit 1
fi

echo "Building and starting GLAZESMPSERVER (Paper 1.21.1 + EaglerXPaper)..."
docker compose up -d --build

echo
echo "Container started. Follow startup output with:"
echo "  docker compose logs -f paper"
echo
echo "Java Edition:  <host>:25565"
echo "Eaglercraft:   ws://<host>:25569/ (plain HTTP/offline client only)"
echo "For HTTPS-hosted clients, configure TLS/WSS on a reverse proxy."
