FROM eclipse-temurin:21-jre-jammy

ARG PAPER_VERSION=1.21.1
ARG PAPER_BUILD=latest
ARG EAGLERXPAPER_URL=https://github.com/PlanetDogeCodes/EaglerXPaper/releases/download/v1.1.1-S2/EaglerXPaper-v1.1.1-Stable2.jar
ARG VIAVERSION_URL=https://hangar.papermc.io/api/v1/projects/ViaVersion/versions/latest/PAPER
ARG VIABACKWARDS_URL=https://hangar.papermc.io/api/v1/projects/ViaBackwards/versions/latest/PAPER
ARG VIAREWIND_URL=https://hangar.papermc.io/api/v1/projects/ViaRewind/versions/latest/PAPER

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates jq && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/minecraft /opt/downloads /data/plugins

# Resolve a concrete Paper build through PaperMC's public API.
RUN set -eux; \
    if [ "$PAPER_BUILD" = "latest" ]; then \
      BUILD="$(curl -fsSL "https://api.papermc.io/v2/projects/paper/versions/$PAPER_VERSION" | jq -r '.builds[-1]')"; \
    else BUILD="$PAPER_BUILD"; fi; \
    test -n "$BUILD" && test "$BUILD" != "null"; \
    curl -fsSL "https://api.papermc.io/v2/projects/paper/versions/$PAPER_VERSION/builds/$BUILD/downloads/paper-$PAPER_VERSION-$BUILD.jar" -o /opt/minecraft/paper.jar

# EaglerXPaper enables Eaglercraft WebSocket connections on Paper's listener.
RUN set -eux; \
    curl -fL "$EAGLERXPAPER_URL" -o /opt/downloads/EaglerXPaper.jar; \
    # The bridge release recommends the Via* translation plugins. If a project API changes,
    # fail the image build rather than silently producing a misleading "working" image.
    for item in "ViaVersion:$VIAVERSION_URL" "ViaBackwards:$VIABACKWARDS_URL" "ViaRewind:$VIAREWIND_URL"; do \
      name="${item%%:*}"; url="${item#*:}"; \
      json="$(curl -fsSL "$url")"; \
      download="$(printf '%s' "$json" | jq -r '.. | objects | select(has("downloadUrl")) | .downloadUrl' | head -n1)"; \
      if [ -z "$download" ] || [ "$download" = "null" ]; then \
        echo "Could not resolve download URL for $name from Hangar API" >&2; exit 1; \
      fi; \
      curl -fL "$download" -o "/opt/downloads/$name.jar"; \
    done

COPY start.sh /usr/local/bin/start-server
RUN chmod +x /usr/local/bin/start-server

WORKDIR /data
EXPOSE 25565/tcp 25569/tcp
ENV EULA=TRUE MEMORY=3G SERVER_PORT=25565
ENTRYPOINT ["/usr/local/bin/start-server"]
