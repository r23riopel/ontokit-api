#!/usr/bin/env bash
set -euo pipefail

readonly WEB_REPOSITORY="https://github.com/r23riopel/ontokit-web.git"
readonly API_DIRECTORY="$(git rev-parse --show-toplevel)"
readonly WORKSPACES_DIRECTORY="$(dirname "$API_DIRECTORY")"
readonly WEB_DIRECTORY="$WORKSPACES_DIRECTORY/ontokit-web"

if [ -d "$WEB_DIRECTORY/.git" ]; then
    echo "Using existing ontokit-web checkout at $WEB_DIRECTORY"
elif [ -e "$WEB_DIRECTORY" ]; then
    echo "Cannot clone ontokit-web: $WEB_DIRECTORY exists but is not a Git checkout." >&2
    exit 1
else
    echo "Cloning $WEB_REPOSITORY into $WEB_DIRECTORY"
    git clone "$WEB_REPOSITORY" "$WEB_DIRECTORY"
fi

# Seed ignored development environment files without ever overwriting local
# values. The Zitadel setup command fills in its generated credentials later.
if [ ! -e "$API_DIRECTORY/.env" ]; then
    cp "$API_DIRECTORY/.env.example" "$API_DIRECTORY/.env"
fi
if [ ! -e "$WEB_DIRECTORY/.env.local" ]; then
    cp "$WEB_DIRECTORY/.env.example" "$WEB_DIRECTORY/.env.local"
fi
