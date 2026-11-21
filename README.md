# goose for Termux (Android)

**English** · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

> Unofficial fork of [goose](https://github.com/aaif-goose/goose) — an extensible AI agent that
> runs local tools and MCP extensions — with **prebuilt Termux / Android (arm64) binaries**
> produced by GitHub Actions. This fork is not affiliated with the upstream project and is not
> intended to be merged back into it.

Upstream goose ships Windows, macOS and Linux builds. Those are built against glibc or musl and
cannot be executed by Android's bionic libc, which is why they do not run in Termux. This fork
cross-compiles the CLI with the Android NDK so that it links against the platform's own libc and
loads in Termux.

## Why the upstream Linux binaries do not run in Termux

| | Regular Linux distribution | Termux (Android) |
| --- | --- | --- |
| Dynamic linker | `/lib/ld-linux-aarch64.so.1` (glibc) or `/lib/ld-musl-aarch64.so.1` | `/system/bin/linker64` (bionic) |
| C library | glibc or musl | bionic |
| Shared libraries | `libssl`, `libdbus`, … installed per distribution | only the bionic system libraries under `/system/lib64` |
| Filesystem layout | FHS: `/bin`, `/usr/bin`, `/lib` | none of those exist; executables live in `$PREFIX/bin` (`/data/data/com.termux/files/usr`) |
| Script shebangs | `#!/bin/sh`, `#!/usr/bin/env bash` | `#!/data/data/com.termux/files/usr/bin/bash`, or rewritten by `termux-exec` |
| ARM64 TLS segment | no constraint | bionic requires 64-byte TLS alignment |

A glibc binary therefore fails inside Termux with a missing-interpreter or linker error even when
built for `aarch64`. This fork's Android job links against `/system/bin/linker64` with the NDK,
depends only on `libc.so` / `libdl.so` / `libm.so` from the system, and is built as a 16 KiB
page-size compatible PIE.

## Requirements

- Termux installed from [F-Droid](https://f-droid.org/packages/com.termux/) or the
  [GitHub releases](https://github.com/termux/termux-app/releases) — the Play Store build is
  outdated and unsupported by goose.
- Android 7.0 (API 24) or newer.
- A 64-bit ARM device (`aarch64` / `arm64-v8a`). `armv7` and `x86_64` are not published yet.
- `pkg install curl tar` (the installer needs both).

## Install

### One-liner (recommended)

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

The installer resolves the latest release, downloads the Android build, installs it as
`$PREFIX/bin/goose`, and verifies that the binary starts.

> Using another Android terminal app, a Termux fork, or a shell started through `su`/`tmux`?
> The installer detects Android through `$PREFIX` and `/system/bin/linker64`, so it works there
> too. If it ever refuses, prepend `GOOSE_TERMUX_FORCE=1` to the command.

### Manual install

```bash
pkg install curl tar
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-linux-android.tar.gz
tar -xzf goose.tar.gz
mv goose "$PREFIX/bin/goose"
chmod 755 "$PREFIX/bin/goose"
goose --version
```

If the Android build fails to start with a linker error, download the static fallback instead:

```bash
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-unknown-linux-musl.tar.gz
```

### Update

Portable builds do not include the self-update command. Re-run the installer to upgrade:

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

### Uninstall

```bash
rm -f "$PREFIX/bin/goose"
# optional: remove configuration, sessions and logs
rm -rf ~/.config/goose ~/.local/share/goose ~/.local/state/goose
```

## Usage

```bash
goose configure     # choose a provider and store its API key
goose session       # start an interactive session
goose --help        # list all commands
```

Configuration lives in `~/.config/goose/config.yaml`, sessions in
`~/.local/share/goose/sessions.db`. Set `GOOSE_PATH_ROOT=/some/dir` to move all goose state
under a single directory (useful on devices with limited internal storage).

API keys can also come from the usual provider environment variables, for example
`OPENAI_API_KEY` or `ANTHROPIC_API_KEY`, configured in `~/.bashrc` or `$PREFIX/etc/profile.d/`.

## Termux notes

| Topic | Behaviour |
| --- | --- |
| Paths | Termux has no `/bin` or `/usr/bin`; goose is installed to `$PREFIX/bin/goose` and everything else resolves through `PATH`. |
| Shell | The shell tool prefers `bash` from `PATH` (`$PREFIX/bin/bash`), and `sh` is provided by Termux's `dash` package, so no FHS shell path is required. |
| Keyring | Compiled out — goose stores secrets in its config file instead of the Android keystore. |
| Local inference | Not available (no V8/llama.cpp in these builds). Use a remote provider. |
| Clipboard | Uses `termux-clipboard-set` when the `termux-api` package is installed. |
| TLS | Certificates are verified against the bundled Mozilla root store. For a private or corporate CA, export `SSL_CERT_FILE=/path/to/bundle.pem`. |
| Browser login | `webbrowser` has no Java runtime to talk to in Termux, so OAuth device flows cannot open a browser. Copy the printed URL into your browser manually. |
| Background work | Android aggressively kills background processes. Run `termux-wake-lock` before long sessions. |
| Storage | Run `termux-setup-storage` if goose should read/write files under `/sdcard`. |

## Troubleshooting

**`CANNOT LINK EXECUTABLE ... library "..." not found`** — use the static musl build with
`GOOSE_TERMUX_VARIANT=musl`.

**`executable's TLS segment is underaligned`** — you are running a glibc/musl Linux build from
upstream. Install the Android build from this repository's releases instead.

**`goose` exits instantly with no output** — run it under `RUST_LOG=debug goose --version` and
open an issue with the output plus `getprop ro.build.version.release` and `uname -m`.

**TLS errors such as `invalid peer certificate: UnknownIssuer`** — the private CA is not in the
bundled Mozilla roots. Point goose at a PEM bundle with `SSL_CERT_FILE`, for example
`export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"`.

**`goose configure` panics with `Expect rustls-platform-verifier to be initialized`** — you are
running a build from before the TLS fix. Reinstall with the command above.

## Build from source on Termux

Building goose on a phone is slow and memory hungry (the workspace pulls in hundreds of crates),
but it works:

```bash
pkg install rust cmake protobuf clang build-essential
cargo build --release -p goose-cli --bin goose --no-default-features --features portable-default
```

The `portable-default` feature set disables local inference (V8) and the D-Bus/SecretService
keyring, neither of which exists on Android.

## Build via GitHub Actions

`.github/workflows/build-termux.yml` builds and publishes the binaries:

| Job | Runner | Output |
| --- | --- | --- |
| `android_aarch64` | `ubuntu-24.04` + NDK | `goose-aarch64-linux-android.tar.gz` (bionic, recommended) |
| `musl_aarch64` | `ubuntu-24.04-arm` | `goose-aarch64-unknown-linux-musl.tar.gz` (static fallback) |
| `publish` | `ubuntu-24.04` | GitHub Release with both archives, `install.sh` and `SHA256SUMS` |

Trigger it manually with the workflow's **Run workflow** button (`publish` defaults to `true`), or
push a tag matching `termux-v*`. The Android job cross-compiles for `aarch64-linux-android`
(API 24) and asserts that the resulting ELF only depends on bionic system libraries, has the
64-byte TLS alignment bionic requires, and is 16 KiB page-size compatible.

### Fork-only source changes

- `crates/goose/Cargo.toml` — `arboard` (clipboard) is only linked on non-Android targets.
- `crates/goose/src/clipboard.rs` — on Android, clipboard access shells out to
  `termux-clipboard-set`.
- `third_party/sys-info` — vendored `sys-info` whose C code calls `index()`, a function
  removed from Android's headers and rejected by current NDK clang. It is wired in through
  `[patch.crates-io]` and replaces the call with `strchr()`.
- `third_party/rustls-platform-verifier` — `reqwest` 0.13 always pulls in the JVM-backed
  Android platform verifier, which panics with "Expect rustls-platform-verifier to be
  initialized" in any process without a JavaVM (Termux included). The vendored copy makes
  Android verify certificates with WebPKI instead, against the bundled Mozilla roots plus any
  bundle pointed at by `SSL_CERT_FILE` / `SSL_CERT_DIR`.

Everything else is upstream code at the commit shown in the repository history.

## Community

Upstream project community links:

- [Discord](https://discord.gg/n8R5VaWDAn)
- [YouTube](https://www.youtube.com/@goose-oss)
- [LinkedIn](https://www.linkedin.com/company/goose-oss)
- [Twitter/X](https://x.com/goose_oss)

## License

Apache-2.0, see [LICENSE](LICENSE). This fork redistributes builds of the upstream project; all
credits for goose belong to its authors at [aaif-goose](https://github.com/aaif-goose).
