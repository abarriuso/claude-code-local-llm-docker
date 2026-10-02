#!/usr/bin/env bash
# Preparación al arrancar el contenedor
set -e

if [ -n "${GIT_USER_NAME:-}" ]; then git config --global user.name "$GIT_USER_NAME"; fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then git config --global user.email "$GIT_USER_EMAIL"; fi
git config --global init.defaultBranch main
git config --global core.autocrlf input

exec "$@"
