#!/data/data/com.termux/files/usr/bin/bash
# Installs the prebuilt goose CLI for Termux from Dankgowndove/goose-termux releases.
# Termux has no FHS /usr/bin; this shebang only matters when the script is executed
# directly. Piping it into bash (the documented install command) also works.
set -euo pipefail

REPO="${GOOSE_TERMUX_REPO:-Dankgowndove/goose-termux}"
# android: bionic build (preferred) | musl: static fallback
VARIANT="${GOOSE_TERMUX_VARIANT:-android}"
VERSION="${GOOSE_TERMUX_VERSION:-}"

info() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "curl is required (pkg install curl)"
command -v tar >/dev/null 2>&1 || die "tar is required"

# Termux detection is deliberately loose: Termux forks, other Android terminal
# apps and shells started via su/tmux do not always export TERMUX_VERSION.
in_android_env() {
  if [ -n "${TERMUX_VERSION:-}" ]; then
    return 0
  fi
  case "${PREFIX:-}" in
    */com.termux/files/usr | */files/usr) return 0 ;;
  esac
  if [ -x "${ANDROID_ROOT:-/nonexistent}/bin/linker64" ]; then
    return 0
  fi
  if [ -x /system/bin/linker64 ]; then
    return 0
  fi
  return 1
}

if ! in_android_env && [ "${GOOSE_TERMUX_FORCE:-}" != "1" ]; then
  die "this installer ships the Android/Termux build and this does not look like Android (no TERMUX_VERSION, \$PREFIX or /system/bin/linker64). Set GOOSE_TERMUX_FORCE=1 to install anyway."
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
tmp_base="${TMPDIR:-${PREFIX:-$HOME}/tmp}"
if [ ! -d "$tmp_base" ]; then
  tmp_base="$HOME"
fi
workdir="$(mktemp -d "$tmp_base/goose-termux.XXXXXX")" || die "cannot create a temporary directory"
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
    info "  curl -fsSL https://github.com/${REPO}/releases/latest/download/install.sh | GOOSE_TERMUX_VARIANT=musl bash"
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
