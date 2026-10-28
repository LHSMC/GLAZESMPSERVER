FROM eclipse-temurin:21-jre-jammy

ARG PAPER_VERSION=1.21.1
ARG PAPER_BUILD=latest
ARG EAGLERXPAPER_URL=https://github.com/PlanetDogeCodes/EaglerXPaper/releases/download/v1.1.1-S2/EaglerXPaper-v1.1.1-Stable2.jar

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

# Download EaglerXPaper and the Via* plugins from Modrinth's public API.
RUN set -eux; \
    curl -fL "$EAGLERXPAPER_URL" -o /opt/downloads/EaglerXPaper.jar; \
    UA='GLAZESMPSERVER/1.0 (https://github.com/LHSMC/GLAZESMPSERVER)'; \
    for slug in viaversion viabackwards viarewind; do \
      json="$(curl -fsSL -H "User-Agent: $UA" "https://api.modrinth.com/v2/project/$slug/version?loaders=%5B%22paper%22%5D&featured=true")"; \
      download="$(printf '%s' "$json" | jq -r '[.[] | select(.loaders | index("paper")) | .files[] | select(.primary == true) | .url][0] // empty')"; \
      if [ -z "$download" ] || [ "$download" = "null" ]; then \
        echo "Could not resolve a Paper plugin download for $slug from Modrinth" >&2; exit 1; \
      fi; \
      curl -fL -H "User-Agent: $UA" "$download" -o "/opt/downloads/$slug.jar"; \
    done
COPY container-entrypoint.sh /usr/local/bin/container-entrypoint
RUN chmod +x /usr/local/bin/container-entrypoint

WORKDIR /data
EXPOSE 25565/tcp 25569/tcp
ENV EULA=TRUE MEMORY=3G SERVER_PORT=25565
ENTRYPOINT ["/usr/local/bin/container-entrypoint"]
