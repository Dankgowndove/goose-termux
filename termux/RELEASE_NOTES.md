# goose for Termux

Prebuilt [goose](https://github.com/aaif-goose/goose) CLI binaries for Android/Termux,
built from the `Dankgowndove/goose-termux` fork by GitHub Actions.

- `goose-aarch64-linux-android.tar.gz` — native Android (bionic) build, built with the
  Android NDK. This is the recommended build for Termux on arm64 devices.
- `goose-aarch64-unknown-linux-musl.tar.gz` — fully static build, usable as a fallback.
- `install.sh` — installer script for Termux.
- `SHA256SUMS` — checksums for the archives.

## Install

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

Manual install:

```bash
pkg install curl tar
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-linux-android.tar.gz
tar -xzf goose.tar.gz
mkdir -p "$PREFIX/bin" && mv goose "$PREFIX/bin/goose" && chmod 755 "$PREFIX/bin/goose"
goose --version
```

If the Android build does not start on your device, install the static fallback with
`GOOSE_TERMUX_VARIANT=musl bash install.sh`.

## Notes

These builds use the portable feature set: no local inference (V8/llama.cpp), no
system keyring backend, and no desktop UI. Clipboard integration uses
`termux-clipboard-set` from the `termux-api` package when it is installed.
Browser-based login flows cannot open a browser from Termux; copy the printed URL
into your browser instead.
