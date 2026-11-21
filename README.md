# goose for Termux (Android)

> Unofficial fork of [goose](https://github.com/aaif-goose/goose) — an extensible AI agent that
> runs local tools and MCP extensions — with **prebuilt Termux / Android (arm64) binaries**
> produced by GitHub Actions. This fork is not affiliated with the upstream project and is not
> intended to be merged back into it.

Upstream goose ships Windows, macOS and Linux builds. Those are built against glibc or musl and
cannot be executed by Android's bionic libc, which is why they do not run in Termux. This fork
cross-compiles the CLI with the Android NDK so that it links against the platform's own libc and
loads in Termux.

## 中文速览

Termux 一键安装（arm64 设备）：

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
goose --version
goose configure   # 选择模型提供商并填入 API Key
```

如果 Android 版本无法启动，改用静态 musl 版本：

```bash
GOOSE_TERMUX_VARIANT=musl bash install.sh
```

> 发布页：<https://github.com/Dankgowndove/goose-termux/releases>

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
| Keyring | Compiled out — goose stores secrets in its config file instead of the Android keystore. |
| Local inference | Not available (no V8/llama.cpp in these builds). Use a remote provider. |
| Clipboard | Uses `termux-clipboard-set` when the `termux-api` package is installed. |
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
