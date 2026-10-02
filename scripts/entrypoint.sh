#!/usr/bin/env bash
set -euo pipefail

/usr/local/bin/firewall.sh

as_node() { setpriv --reuid=node --regid=node --init-groups -- "$@"; }

if [ -n "${GIT_USER_NAME:-}" ]; then as_node git config --global user.name "$GIT_USER_NAME"; fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then as_node git config --global user.email "$GIT_USER_EMAIL"; fi
as_node git config --global init.defaultBranch main
as_node git config --global core.autocrlf input

exec setpriv --reuid=node --regid=node --init-groups -- "$@"
