#!/usr/bin/env bash
# Installs the prebuilt goose CLI for Termux from Dankgowndove/goose-termux releases.
set -euo pipefail

REPO="${GOOSE_TERMUX_REPO:-Dankgowndove/goose-termux}"
# android: bionic build (preferred) | musl: static fallback
VARIANT="${GOOSE_TERMUX_VARIANT:-android}"
VERSION="${GOOSE_TERMUX_VERSION:-}"

info() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "curl is required (pkg install curl)"
command -v tar >/dev/null 2>&1 || die "tar is required"

if [ -z "${TERMUX_VERSION:-}" ] && [ "${GOOSE_TERMUX_FORCE:-}" != "1" ]; then
  die "this script installs the Termux build; set GOOSE_TERMUX_FORCE=1 to run it anyway"
fi

case "$(uname -m)" in
  aarch64 | arm64) ;;
  *) die "unsupported architecture $(uname -m); only aarch64 builds are published" ;;
esac

case "$VARIANT" in
  android) asset="goose-aarch64-linux-android.tar.gz" ;;
  musl) asset="goose-aarch64-unknown-linux-musl.tar.gz" ;;
  *) die "GOOSE_TERMUX_VARIANT must be 'android' or 'musl'" ;;
esac

if [ -z "$VERSION" ]; then
  info "resolving the latest release"
  VERSION="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" |
    sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n1)"
  [ -n "$VERSION" ] || die "could not resolve the latest release; set GOOSE_TERMUX_VERSION=termux-v<version>"
fi

download_url="https://github.com/${REPO}/releases/download/${VERSION}/${asset}"
workdir="$(mktemp -d "${TMPDIR:-/tmp}/goose-termux.XXXXXX")"
trap 'rm -rf "$workdir"' EXIT

info "downloading ${asset} (${VERSION})"
curl -fsSL -o "$workdir/goose.tar.gz" "$download_url" || die "download failed: $download_url"
tar -xzf "$workdir/goose.tar.gz" -C "$workdir"

if [ -n "${PREFIX:-}" ] && [ -w "${PREFIX}/bin" ]; then
  install_path="${PREFIX}/bin/goose"
else
  install_path="${HOME}/.local/bin/goose"
fi
mkdir -p "$(dirname "$install_path")"
cp "$workdir/goose" "$install_path"
chmod 755 "$install_path"

if ! "$install_path" --version >/dev/null 2>&1; then
  if [ "$VARIANT" = "android" ]; then
    info "the Android build did not start; retry with the static musl build:"
    info "  GOOSE_TERMUX_VARIANT=musl bash -c \"\$(curl -fsSL https://github.com/${REPO}/releases/latest/download/install.sh)\""
  fi
  die "installed binary failed to run: $install_path"
fi

info "installed $("$install_path" --version 2>&1 | head -n1) at ${install_path}"
case ":$PATH:" in
  *":$(dirname "$install_path"):"*) ;;
  *) info "add $(dirname "$install_path") to PATH" ;;
esac
info "optional clipboard support: pkg install termux-api"
info "next: goose configure"
