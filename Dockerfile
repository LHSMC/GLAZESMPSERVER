FROM eclipse-temurin:21-jre-jammy

ARG PAPER_VERSION=1.21.1
ARG PAPER_BUILD=latest
ARG EAGLERXPAPER_URL=https://github.com/PlanetDogeCodes/EaglerXPaper/releases/download/v1.1.1-S2/EaglerXPaper-v1.1.1-Stable2.jar
ARG VIAVERSION_URL=https://hangar.papermc.io/api/v1/projects/ViaVersion/versions/latest/PAPER
ARG VIABACKWARDS_URL=https://hangar.papermc.io/api/v1/projects/ViaBackwards/versions/latest/PAPER
ARG VIAREWIND_URL=https://hangar.papermc.io/api/v1/projects/ViaRewind/versions/latest/PAPER

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates jq && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/minecraft /opt/downloads /data/plugins

# PaperMC retired its v2 API. Resolve the current v3 download URL and verify its checksum.
RUN set -eux; \
    UA='GLAZESMPSERVER/1.0 (https://github.com/LHSMC/GLAZESMPSERVER)'; \
    if [ "$PAPER_BUILD" = "latest" ]; then \
      META="$(curl -fsSL -H "User-Agent: $UA" -H 'Accept: application/json' "https://fill.papermc.io/v3/projects/paper/versions/$PAPER_VERSION/builds?channel=STABLE")"; \
      URL="$(printf '%s' "$META" | jq -r 'first(.[] | select(.channel == "STABLE") | .downloads["server:default"].url) // empty')"; \
      SHA="$(printf '%s' "$META" | jq -r 'first(.[] | select(.channel == "STABLE") | .downloads["server:default"].checksums.sha256) // empty')"; \
    else \
      META="$(curl -fsSL -H "User-Agent: $UA" -H 'Accept: application/json' "https://fill.papermc.io/v3/projects/paper/versions/$PAPER_VERSION/builds/$PAPER_BUILD")"; \
      URL="$(printf '%s' "$META" | jq -r '.downloads["server:default"].url // empty')"; \
      SHA="$(printf '%s' "$META" | jq -r '.downloads["server:default"].checksums.sha256 // empty')"; \
    fi; \
    test -n "$URL" && test -n "$SHA"; \
    curl -fsSL -H "User-Agent: $UA" "$URL" -o /opt/minecraft/paper.jar; \
    echo "$SHA  /opt/minecraft/paper.jar" | sha256sum -c -

# Download EaglerXPaper and its recommended protocol translation plugins.
RUN set -eux; \
    curl -fL "$EAGLERXPAPER_URL" -o /opt/downloads/EaglerXPaper.jar; \
    for item in "ViaVersion:$VIAVERSION_URL" "ViaBackwards:$VIABACKWARDS_URL" "ViaRewind:$VIAREWIND_URL"; do \
      name="${item%%:*}"; url="${item#*:}"; \
      json="$(curl -fsSL "$url")"; \
      download="$(printf '%s' "$json" | jq -r '.. | objects | select(has("downloadUrl")) | .downloadUrl' | head -n1)"; \
      if [ -z "$download" ] || [ "$download" = "null" ]; then \
        echo "Could not resolve download URL for $name from Hangar API" >&2; exit 1; \
      fi; \
      curl -fL "$download" -o "/opt/downloads/$name.jar"; \
    done

COPY container-entrypoint.sh /usr/local/bin/container-entrypoint
RUN chmod +x /usr/local/bin/container-entrypoint

WORKDIR /data
EXPOSE 25565/tcp 25569/tcp
ENV EULA=TRUE MEMORY=3G SERVER_PORT=25565
ENTRYPOINT ["/usr/local/bin/container-entrypoint"]
