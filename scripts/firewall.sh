#!/usr/bin/env bash
set -euo pipefail

READY=/run/firewall-ready
rm -f "$READY"

if [ "${FIREWALL:-on}" = "off" ]; then
  echo "[firewall] desactivado (FIREWALL=off)"
  touch "$READY"
  exit 0
fi

DOMAINS=(
  api.anthropic.com console.anthropic.com statsig.anthropic.com
  claude.ai claude.com platform.claude.com
  sentry.io statsig.com
  registry.npmjs.org pypi.org files.pythonhosted.org
  opencode.ai models.dev
  api.openai.com openrouter.ai api.githubcopilot.com generativelanguage.googleapis.com
  update.code.visualstudio.com vscode.download.prss.microsoft.com marketplace.visualstudio.com
)
ALLOW="${FIREWALL_ALLOW:-}"
read -ra EXTRA <<< "${ALLOW//,/ }"

iptables -F
iptables -X
ipset destroy allowed 2>/dev/null || true
ipset create allowed hash:net

allow() {
  local item=$1 ips
  if [[ $item =~ ^[0-9.]+(/[0-9]+)?$ ]]; then
    ipset add -exist allowed "$item"
    return
  fi
  ips=$(getent ahostsv4 "$item" | awk '{print $1}' | sort -u || true)
  if [ -z "$ips" ]; then
    echo "[firewall] aviso: no se resuelve $item"
    return
  fi
  for ip in $ips; do ipset add -exist allowed "$ip"; done
}

for d in "${DOMAINS[@]}" "${EXTRA[@]}"; do allow "$d"; done

if gh_ranges=$(curl -sf --max-time 10 https://api.github.com/meta \
    | jq -r '(.web + .api + .git)[] | select(contains(":") | not)'); then
  for r in $gh_ranges; do ipset add -exist allowed "$r"; done
else
  echo "[firewall] aviso: no se pudieron obtener las direcciones de GitHub"
fi

allow host.docker.internal
for net in $(ip -o -f inet addr show | awk '$2 != "lo" {print $4}'); do
  ipset add -exist allowed "$net"
done

iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m set --match-set allowed dst -j ACCEPT
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

if command -v ip6tables >/dev/null && ip6tables -L >/dev/null 2>&1; then
  ip6tables -F
  ip6tables -A OUTPUT -o lo -j ACCEPT
  ip6tables -P OUTPUT DROP
fi

if curl -s --max-time 5 -o /dev/null https://example.com; then
  echo "[firewall] ERROR: el tráfico no permitido no se bloquea"
  exit 1
fi
if ! curl -s --max-time 10 -o /dev/null https://api.anthropic.com; then
  echo "[firewall] aviso: api.anthropic.com no responde"
fi

touch "$READY"
echo "[firewall] activo"
