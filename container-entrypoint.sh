#!/usr/bin/env sh
set -eu

cd /data

if [ "${EULA:-TRUE}" != "TRUE" ]; then
  echo "Set EULA=TRUE only after reviewing https://www.minecraft.net/eula." >&2
  exit 1
fi
printf 'eula=true\n' > eula.txt
mkdir -p plugins

# Install the bridge and translation plugins downloaded into the image.
for jar in /opt/downloads/*.jar; do
  [ -f "$jar" ] || continue
  target="/data/plugins/$(basename "$jar")"
  if [ ! -f "$target" ]; then
    cp "$jar" "$target"
  fi
done

# Seed settings on first boot; then keep the chosen environment settings in sync.
if [ ! -f server.properties ]; then
  : > server.properties
fi
set_property() {
  key="$1"
  value="$2"
  if grep -q "^${key}=" server.properties; then
    sed -i "s|^${key}=.*|${key}=${value}|" server.properties
  else
    printf '%s=%s\n' "$key" "$value" >> server.properties
  fi
}
set_property server-port "${SERVER_PORT:-25565}"
set_property online-mode "${ONLINE_MODE:-true}"
set_property max-players "${MAX_PLAYERS:-20}"
set_property view-distance "${VIEW_DISTANCE:-6}"
set_property simulation-distance "${SIMULATION_DISTANCE:-4}"

MEMORY="${MEMORY:-3G}"
echo "Starting Paper with EaglerXPaper; memory limit: $MEMORY"
exec java -Xms"$MEMORY" -Xmx"$MEMORY" -jar /opt/minecraft/paper.jar --nogui
