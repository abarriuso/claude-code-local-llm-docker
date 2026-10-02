# Entorno de trabajo aislado: herramientas de desarrollo + agentes de IA (Claude Code y OpenCode)
FROM node:22-bookworm-slim

# Herramientas básicas + GitHub CLI
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git curl ca-certificates openssh-client gnupg less nano jq ripgrep procps python3 \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

# Agentes de IA. Para actualizarlos: reconstruir la imagen (docker compose build --pull)
RUN npm install -g @anthropic-ai/claude-code opencode-ai \
 && npm cache clean --force

# Scripts propios (se quitan los CRLF por si el repo se clonó en Windows)
COPY scripts/ia scripts/entrypoint.sh /usr/local/bin/
RUN sed -i 's/\r$//' /usr/local/bin/ia /usr/local/bin/entrypoint.sh \
 && chmod +x /usr/local/bin/ia /usr/local/bin/entrypoint.sh \
 && mkdir -p /workspace && chown node:node /workspace

# Sin root: el agente no puede tocar el sistema
USER node
WORKDIR /workspace

ENTRYPOINT ["entrypoint.sh"]
CMD ["sleep", "infinity"]
