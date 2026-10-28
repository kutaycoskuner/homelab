#!/usr/bin/env bash
# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-28
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
# server_base.sh -- installs, updates and checks the server's base software: Docker (engine
# and Compose plugin) and Portainer (from stacks/portainer/docker-compose.yml).
#
# Exists because everything else runs on these two, and neither can be managed from inside:
# Portainer can't update itself (it would stop its own container), tofu/portainer only
# manages the stacks inside Portainer, and Docker comes from the system's packages.
#
# Requires: Debian-based Linux (Raspberry Pi OS, Debian, Ubuntu) with sudo; curl; network.
#
# Run: bash scripts/server_base/server_base.sh --help
#
# Every change asks first; without a terminal it only reports. Data stays where it is
# (containers' volumes, the portainer_data volume); nothing here deletes data.
# --update only uses the Portainer image tag the compose file names: run git pull first,
# so a merged Renovate update is in the compose file.

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$(cd "$DIR/../../stacks/portainer" && pwd)/docker-compose.yml"
CONTAINER="portainer"
VOLUME="portainer_data"
STATUS_URL="http://localhost:9000/api/system/status"
DOCKER_PACKAGES=(docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin)
ME="$(id -un)"   # the current user; $ME isn't set in every shell

# -----------------------------------------------------------------------------------------
#   helpers
# -----------------------------------------------------------------------------------------

usage() {
    cat <<EOF
Installs, updates and checks the server's base software: Docker and Portainer.

commands:
  --status       Docker and Compose versions; is Portainer running, its version, how it was started
  --install      install Docker if missing (and add you to the docker group), then start Portainer
                 from stacks/portainer; offers to replace an old docker run Portainer container
  --update       update the Docker packages through apt, then pull Portainer's image and restart
                 it only if the image changed

options:
  --dry-run      with --install or --update: show what would happen, change nothing

examples:
  bash scripts/server_base/server_base.sh --status
  bash scripts/server_base/server_base.sh --install --dry-run
  bash scripts/server_base/server_base.sh --install
  git pull && bash scripts/server_base/server_base.sh --update

details: scripts/server_base/README.md
EOF
}

say() { printf '%s\n' "$*"; }

ask() {
    # yes/no question; "no" without a terminal, so nothing changes unattended
    local answer=""
    if [[ ! -t 0 ]]; then
        say "$1 [y/n] -> no terminal, answering no"
        return 1
    fi
    read -r -p "$1 [y/n] " answer || return 1
    [[ "$answer" == "y" ]]
}

have_docker_cli() { command -v docker >/dev/null 2>&1; }

docker_usable() { docker version >/dev/null 2>&1; }

compose() { docker compose -f "$COMPOSE_FILE" "$@"; }

container_exists() { docker inspect "$CONTAINER" >/dev/null 2>&1; }

started_by() {
    # "stack" when the compose project label is set, otherwise "docker run"
    local project
    project="$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$CONTAINER" 2>/dev/null || true)"
    if [[ -n "$project" && "$project" != "<no value>" ]]; then echo "stack ($project)"; else echo "docker run"; fi
}

portainer_version() {
    # Portainer reports its version through its own API; empty when it doesn't answer
    curl -fsS --max-time 5 "$STATUS_URL" 2>/dev/null | sed -n 's/.*"Version":"\([^"]*\)".*/\1/p' || true
}

image_id() { docker image inspect -f '{{ .Id }}' "$1" 2>/dev/null || true; }

compose_image() { sed -n 's/^[[:space:]]*image:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$COMPOSE_FILE" | head -1; }

need_docker_access() {
    # Docker is installed but this user can't use it yet (not in the docker group, or not logged in again)
    if ! docker_usable; then
        say "Docker is installed but not usable by $ME yet."
        say "If you were just added to the docker group: log out and back in (or run: newgrp docker), then run this again."
        exit 1
    fi
}

# -----------------------------------------------------------------------------------------
#   docker
# -----------------------------------------------------------------------------------------

docker_status() {
    if ! have_docker_cli; then
        say "Docker              : not installed"
        return
    fi
    if docker_usable; then
        say "Docker              : $(docker version -f '{{ .Server.Version }}' 2>/dev/null)"
        say "Compose plugin      : $(docker compose version --short 2>/dev/null || echo 'missing')"
    else
        say "Docker              : installed, but not usable by $ME (docker group?)"
    fi
}

docker_install() {
    local dry_run="$1"
    if have_docker_cli; then
        say "Docker is already installed: $(docker --version)"
    else
        say "Docker is missing. It will be installed with Docker's official script (get.docker.com), which adds Docker's apt repository."
        if [[ "$dry_run" == "yes" ]]; then
            say "dry run: would run: curl -fsSL https://get.docker.com | sudo sh"
        else
            ask "Install Docker now (needs sudo)?" || { say "Docker not installed; stopping here."; exit 1; }
            curl -fsSL https://get.docker.com | sudo sh
        fi
    fi
    if id -nG "$ME" 2>/dev/null | grep -qw docker; then
        say "$ME is in the docker group."
    elif [[ "$dry_run" == "yes" ]]; then
        say "dry run: would run: sudo usermod -aG docker $ME"
    elif ask "Add $ME to the docker group, so docker works without sudo?"; then
        sudo usermod -aG docker "$ME"
        say "Added. Log out and back in (or run: newgrp docker), then run --install again to start Portainer."
        exit 0
    fi
}

docker_update() {
    local dry_run="$1" pkgs
    say "Checking the Docker packages for updates (sudo apt-get update) ..."
    if [[ "$dry_run" == "yes" ]]; then
        say "dry run: would run sudo apt-get update and list upgradable Docker packages"
        return
    fi
    sudo apt-get update -qq
    pkgs="$(apt list --upgradable 2>/dev/null | cut -d/ -f1 | grep -xF -f <(printf '%s\n' "${DOCKER_PACKAGES[@]}") || true)"
    if [[ -z "$pkgs" ]]; then
        say "Docker is up to date ($(docker version -f '{{ .Server.Version }}' 2>/dev/null || docker --version))."
        return
    fi
    say "Updates available for: $(echo "$pkgs" | tr '\n' ' ')"
    say "Updating Docker restarts the Docker service: all containers stop briefly and come back by their restart policy."
    ask "Update these packages now?" || { say "Docker not updated."; return; }
    # shellcheck disable=SC2086  # one package name per word on purpose
    sudo apt-get install --only-upgrade -y $pkgs
    say "Docker now: $(docker version -f '{{ .Server.Version }}' 2>/dev/null || docker --version)"
}

# -----------------------------------------------------------------------------------------
#   portainer
# -----------------------------------------------------------------------------------------

portainer_status() {
    if ! have_docker_cli || ! docker_usable; then
        say "Portainer           : unknown (Docker not usable)"
        return
    fi
    if ! container_exists; then
        say "Portainer           : not installed (no container named $CONTAINER)"
        return
    fi
    local version; version="$(portainer_version)"
    say "Portainer           : $(docker inspect -f '{{ .State.Status }}' "$CONTAINER"), version ${version:-unknown, no answer from $STATUS_URL}"
    say "  started by        : $(started_by)"
    say "  image             : $(docker inspect -f '{{ .Config.Image }}' "$CONTAINER")"
    if docker volume inspect "$VOLUME" >/dev/null 2>&1; then
        say "  data volume       : $VOLUME (kept on install and update)"
    else
        say "  data volume       : $VOLUME not found (a first install creates it)"
    fi
}

portainer_install() {
    local dry_run="$1"
    if container_exists; then
        local by; by="$(started_by)"
        if [[ "$by" == stack* ]]; then
            say "Portainer is already installed from a compose file ($by). Use --update to update it."
            return
        fi
        say "Found a Portainer container started by docker run. It will be replaced by the compose stack;"
        say "its data stays in the $VOLUME volume, which the compose file reuses."
        if [[ "$dry_run" == "yes" ]]; then
            say "dry run: would stop and remove the container '$CONTAINER', then start it from $COMPOSE_FILE"
            return
        fi
        ask "Stop and remove the old container (not its data)?" || { say "Portainer unchanged."; return; }
        docker stop "$CONTAINER" >/dev/null && docker rm "$CONTAINER" >/dev/null
        say "Old container removed."
    elif [[ "$dry_run" == "yes" ]]; then
        say "dry run: would start Portainer from $COMPOSE_FILE (image $(compose_image))"
        return
    fi
    ask "Start Portainer from the compose file now?" || { say "Portainer not started."; return; }
    compose up -d
    say "Started. Open https://<server-ip>:9443 and create the admin user right away (Portainer times out the first setup)."
}

portainer_update() {
    local dry_run="$1" image before after old_version
    if ! container_exists || [[ "$(started_by)" != stack* ]]; then
        say "Portainer isn't running from the compose file yet: run --install first."
        return
    fi
    image="$(compose_image)"
    old_version="$(portainer_version)"
    if [[ "$dry_run" == "yes" ]]; then
        say "dry run: would pull $image and restart Portainer only if the image changed (now: ${old_version:-unknown version})"
        return
    fi
    before="$(image_id "$image")"
    say "Pulling $image ..."
    compose pull --quiet
    after="$(image_id "$image")"
    if [[ "$before" == "$after" ]]; then
        say "Portainer already has the newest image for $image (version ${old_version:-unknown}). Not restarted."
        return
    fi
    say "A new Portainer image is downloaded."
    ask "Restart Portainer with it now? (its web UI is unavailable for a few seconds)" || { say "Not restarted; the new image is used on the next restart."; return; }
    compose up -d
    sleep 5
    say "Portainer updated: ${old_version:-unknown} -> $(portainer_version)"
}

# -----------------------------------------------------------------------------------------
#   main
# -----------------------------------------------------------------------------------------

main() {
    # 1. Read the arguments: one command word, optional --dry-run
    local command="" dry_run="no" arg
    for arg in "$@"; do
        case "$arg" in
            --status|--install|--update)
                if [[ -n "$command" ]]; then say "Only one command at a time: $command or $arg."; exit 2; fi
                command="$arg" ;;
            --dry-run) dry_run="yes" ;;
            -h|--help) usage; exit 0 ;;
            *) say "Unknown option: $arg"; echo; usage; exit 2 ;;
        esac
    done

    # 2. No command word: print the help; with only --dry-run, also the command to add
    if [[ -z "$command" ]]; then
        usage
        if [[ "$dry_run" == "yes" ]]; then
            echo; say "Nothing run: add a command, e.g. bash scripts/server_base/server_base.sh --update --dry-run"
            exit 2
        fi
        exit 0
    fi

    # 3. Run it: Docker first, Portainer on top of it
    case "$command" in
        --status)
            docker_status
            portainer_status ;;
        --install)
            docker_install "$dry_run"
            if [[ "$dry_run" == "no" ]]; then need_docker_access; fi
            portainer_install "$dry_run" ;;
        --update)
            if ! have_docker_cli; then say "Docker isn't installed: run --install first."; exit 1; fi
            docker_update "$dry_run"
            if [[ "$dry_run" == "no" ]]; then need_docker_access; fi
            portainer_update "$dry_run" ;;
    esac
}

main "$@"
