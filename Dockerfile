FROM node:22-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git curl ca-certificates openssh-client gnupg less nano jq ripgrep procps python3 \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code opencode-ai \
 && npm cache clean --force

COPY scripts/ia scripts/entrypoint.sh /usr/local/bin/
RUN sed -i 's/\r$//' /usr/local/bin/ia /usr/local/bin/entrypoint.sh \
 && chmod +x /usr/local/bin/ia /usr/local/bin/entrypoint.sh \
 && mkdir -p /workspace && chown node:node /workspace

USER node
WORKDIR /workspace

ENTRYPOINT ["entrypoint.sh"]
CMD ["sleep", "infinity"]
