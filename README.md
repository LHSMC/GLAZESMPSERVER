# GLAZESMPSERVER — Paper + Eaglercraft

A Docker-based Paper 1.21.1 server with the EaglerXPaper WebSocket bridge. EaglerXPaper provides a dual-stack listener, so Java Edition TCP and Eaglercraft WebSocket clients can use the same server listener. Docker publishes that listener as both `25565` and `25569`.

## Requirements

- Docker Engine and the Docker Compose plugin (or Docker Desktop).
- A machine/host that permits inbound TCP connections on the published port(s).
- Enough RAM for Paper; start with 3–4 GB if available.
- A browser client compatible with the Eaglercraft protocol supported by EaglerXPaper (commonly EaglercraftX 1.8.x, 1.12.2, or 1.5.2).

## Start it

1. Clone this repository and enter its folder.
2. Review `docker-compose.yml` and adjust memory settings if needed.
3. Make the start script executable and launch:

   ```sh
   chmod +x start.sh
   ./start.sh
   ```

   Alternatively run `docker compose up -d --build`.
4. Follow startup logs with `docker compose logs -f paper`. The first boot downloads Paper and the bridge, accepts the Minecraft EULA setting in the container, and generates the server configuration.
5. Stop cleanly with `docker compose down`. World and server data are stored in the named `paper-data` volume and persist across container rebuilds.

## How players connect

- **Java Edition:** `your-hostname-or-ip:25565`
- **Eaglercraft in a browser:** `ws://your-hostname-or-ip:25569/` when the browser page is served over plain HTTP or opened as a local/offline HTML file.
- If the client page is served over HTTPS, browsers generally require **WSS**. Put a TLS-terminating reverse proxy (for example, Caddy or nginx with a valid certificate) in front of the WebSocket endpoint and use `wss://your-hostname/`. Do not expose an unencrypted WebSocket endpoint to an HTTPS page and expect the browser to permit it.

The container maps host ports 25565 and 25569 to the bridge-enabled Paper listener on container port 25565. EaglerXPaper's dual-stack mode distinguishes WebSocket handshakes from normal Minecraft TCP connections; it does not require a separate internal listener.

## Compatibility notes

- Paper is pinned to **1.21.1** and uses Java 21.
- EaglerXPaper is downloaded from its published release. The project documents Paper support for 1.12.2 through 1.21.x and newer, and says its configuration is generated automatically under `plugins/EaglercraftXServer/`.
- EaglerXPaper's release notes warn that ViaVersion, ViaBackwards, and ViaRewind are required for its functionality. This image downloads those plugins as well. Protocol translation cannot recreate blocks/features absent from an older client.
- Use a browser client version compatible with the Eaglercraft protocol. This does not make arbitrary modern Java clients into Eaglercraft clients.
- The bridge's generated configuration is authoritative. The tracked file in `plugins/EaglercraftXServer/` is an explanatory placeholder; don't replace generated listener settings with guessed keys. Start once and inspect the generated files/logs if you need to customize it.

## Administration

- Console: `docker compose attach paper` (detach with Ctrl-P then Ctrl-Q), or use `docker compose logs -f paper`.
- Restart: `docker compose restart paper`.
- Update/rebuild: `docker compose build --pull && docker compose up -d`. Back up your data volume before changing versions.
- Server data lives in Docker volume `paper-data`. To back it up, stop the server first and back up that volume using Docker tooling.

## Security

- This is an internet-facing game server if you publish its ports. Keep Paper and plugins updated and only install plugins you trust.
- Do not enable remote administration/RCON on an internet-facing interface without proper protection.
- For public browser access, use WSS with a valid TLS certificate.
- Eaglercraft clients may not use Mojang/Microsoft online authentication in the same way as Java clients. Configure authentication/permissions appropriate to your community before opening the server publicly.

## References

- [Paper downloads](https://papermc.io/downloads/paper)
- [EaglerXPaper source and compatibility notes](https://github.com/PlanetDogeCodes/EaglerXPaper)
- [Latest EaglerXPaper release](https://github.com/PlanetDogeCodes/EaglerXPaper/releases/latest)
