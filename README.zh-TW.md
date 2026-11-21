# 適用於 Termux 的 goose（Android）

[English](README.md) · [简体中文](README.zh-CN.md) · **繁體中文** · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

> [goose](https://github.com/aaif-goose/goose) 的非官方分支（fork）——一個可擴充的 AI Agent，
> 能執行本機工具與 MCP 擴充功能。本儲存庫透過 GitHub Actions 提供**預先編譯的 Termux / Android
> （arm64）二進位檔**。本分支與上游專案無關，也不會合併回上游。

上游 goose 只發佈 Windows、macOS 與 Linux 版本，它們以 glibc 或 musl 建置，無法被 Android 的
bionic libc 載入，因此無法在 Termux 中執行。本分支使用 Android NDK 交叉編譯 CLI，讓它連結
Android 平台自帶的 libc，因而能在 Termux 中正常執行。

## 為什麼上游 Linux 二進位檔在 Termux 中無法執行

| | 一般 Linux 發行版 | Termux（Android） |
| --- | --- | --- |
| 動態連結器 | `/lib/ld-linux-aarch64.so.1`（glibc）或 `/lib/ld-musl-aarch64.so.1` | `/system/bin/linker64`（bionic） |
| C 執行期函式庫 | glibc 或 musl | bionic |
| 共用函式庫 | 依發行版安裝的 `libssl`、`libdbus` 等 | 僅 `/system/lib64` 下的 bionic 系統函式庫 |
| 檔案系統配置 | FHS：`/bin`、`/usr/bin`、`/lib` | 這些路徑都不存在；可執行檔位於 `$PREFIX/bin`（`/data/data/com.termux/files/usr`） |
| 指令碼 shebang | `#!/bin/sh`、`#!/usr/bin/env bash` | `#!/data/data/com.termux/files/usr/bin/bash`，或由 `termux-exec` 自動改寫 |
| ARM64 TLS 區段 | 無要求 | bionic 要求 64 位元組對齊 |

因此，即使是 `aarch64` 架構的 glibc 二進位檔，在 Termux 中也只會出現「找不到解譯器」或連結錯誤。
本分支的 Android 建置使用 NDK 連結 `/system/bin/linker64`，只依賴系統自帶的
`libc.so` / `libdl.so` / `libm.so`，且是相容 16 KiB 頁面大小的 PIE 執行檔。

## 系統需求

- 從 [F-Droid](https://f-droid.org/packages/com.termux/) 或
  [GitHub Releases](https://github.com/termux/termux-app/releases) 安裝的 Termux —— Play 商店版本
  過於老舊，不受 goose 支援。
- Android 7.0（API 24）或更新版本。
- 64 位元 ARM 裝置（`aarch64` / `arm64-v8a`）。尚未發佈 `armv7` 與 `x86_64` 版本。
- 執行 `pkg install curl tar`（安裝指令碼需要這兩者）。

## 安裝

### 一行指令安裝（建議）

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

安裝指令碼會解析最新 Release、下載 Android 版本、安裝到 `$PREFIX/bin/goose`，並驗證二進位檔能否啟動。

> 使用其他 Android 終端 App、Termux 分支，或透過 `su`/`tmux` 啟動的 shell 同樣可以：安裝指令碼會
> 透過 `$PREFIX` 與 `/system/bin/linker64` 辨識 Android 環境。若仍被拒絕，在指令前加上
> `GOOSE_TERMUX_FORCE=1` 即可。

### 手動安裝

```bash
pkg install curl tar
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-linux-android.tar.gz
tar -xzf goose.tar.gz
mv goose "$PREFIX/bin/goose"
chmod 755 "$PREFIX/bin/goose"
goose --version
```

如果 Android 版本因連結錯誤無法啟動，改用靜態備援版：

```bash
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-unknown-linux-musl.tar.gz
```

### 更新

精簡建置不包含自動更新指令，重新執行安裝指令碼即可升級：

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

### 解除安裝

```bash
rm -f "$PREFIX/bin/goose"
# 選用：刪除設定、工作階段與日誌
rm -rf ~/.config/goose ~/.local/share/goose ~/.local/state/goose
```

## 使用方式

```bash
goose configure     # 選擇模型供應商並儲存 API Key
goose session       # 啟動互動式工作階段
goose --help        # 列出所有指令
```

設定檔位於 `~/.config/goose/config.yaml`，工作階段資料在 `~/.local/share/goose/sessions.db`。
設定 `GOOSE_PATH_ROOT=/某個目錄` 可將 goose 的所有狀態集中到單一目錄（適合內部儲存空間有限的裝置）。

API Key 也可以透過常見供應商的環境變數提供，例如 `OPENAI_API_KEY` 或 `ANTHROPIC_API_KEY`，
可寫入 `~/.bashrc` 或 `$PREFIX/etc/profile.d/` 下的指令碼。

## Termux 注意事項

| 項目 | 行為 |
| --- | --- |
| 路徑 | Termux 沒有 `/bin` 或 `/usr/bin`；goose 安裝到 `$PREFIX/bin/goose`，其餘指令都透過 `PATH` 解析。 |
| Shell | shell 工具優先使用 `PATH` 中的 `bash`（`$PREFIX/bin/bash`），`sh` 由 Termux 的 `dash` 套件提供，因此不依賴 FHS 路徑。 |
| Keyring | 已移除 —— goose 將密鑰保存在自己的設定檔中，而非 Android keystore。 |
| 本機推論 | 無法使用（這些建置不含 V8/llama.cpp），請改用遠端供應商。 |
| 剪貼簿 | 安裝 `termux-api` 套件後透過 `termux-clipboard-set` 運作。 |
| TLS | 使用內建的 Mozilla 根憑證驗證憑證。若需要私有/企業 CA，請匯出 `SSL_CERT_FILE=/路徑/bundle.pem`。 |
| 瀏覽器登入 | Termux 中沒有可供 `webbrowser` 呼叫的 Java 執行期，OAuth 裝置流程無法自動開啟瀏覽器，請手動複製輸出的 URL。 |
| 背景工作 | Android 會積極終止背景程序，長時間工作階段前先執行 `termux-wake-lock`。 |
| 儲存空間 | 若 goose 需要讀寫 `/sdcard` 下的檔案，先執行 `termux-setup-storage`。 |

## 疑難排解

**`CANNOT LINK EXECUTABLE ... library "..." not found`** —— 使用靜態 musl 版本：
`GOOSE_TERMUX_VARIANT=musl`。

**`executable's TLS segment is underaligned`** —— 你執行的是上游的 glibc/musl Linux 版本，
請改用本儲存庫 Release 中的 Android 版本。

**`goose` 立即結束且沒有任何輸出** —— 用 `RUST_LOG=debug goose --version` 執行，並將輸出連同
`getprop ro.build.version.release` 與 `uname -m` 一起提交 issue。

**TLS 錯誤如 `invalid peer certificate: UnknownIssuer`** —— 私有 CA 不在內建 Mozilla 根憑證中。
透過 `SSL_CERT_FILE` 指向 PEM 憑證包，例如 `export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"`。

**`goose configure` 出現 `Expect rustls-platform-verifier to be initialized`** —— 你使用的是 TLS
修正之前的舊建置，請以上方指令重新安裝。

## 在 Termux 中從原始碼建置

在手機上建置 goose 很慢且相當耗記憶體（工作區會拉取數百個 crate），但確實可行：

```bash
pkg install rust cmake protobuf clang build-essential
cargo build --release -p goose-cli --bin goose --no-default-features --features portable-default
```

`portable-default` 特性集關閉了本機推論（V8）與 D-Bus/SecretService keyring，兩者在 Android 上都不存在。

## 透過 GitHub Actions 建置

`.github/workflows/build-termux.yml` 負責建置並發佈二進位檔：

| 任務 | 執行環境 | 產物 |
| --- | --- | --- |
| `android_aarch64` | `ubuntu-24.04` + NDK | `goose-aarch64-linux-android.tar.gz`（bionic，建議） |
| `musl_aarch64` | `ubuntu-24.04-arm` | `goose-aarch64-unknown-linux-musl.tar.gz`（靜態備援版） |
| `publish` | `ubuntu-24.04` | 發佈 GitHub Release，包含兩個壓縮檔、`install.sh` 與 `SHA256SUMS` |

可在 Actions 頁面點 **Run workflow** 手動觸發（`publish` 預設 `true`），或推送符合 `termux-v*`
的 tag。Android 任務會交叉編譯至 `aarch64-linux-android`（API 24），並在發佈前驗證 ELF：只依賴
bionic 系統函式庫、符合 bionic 要求的 64 位元組 TLS 對齊、相容 16 KiB 頁面大小。

### 僅本分支的原始碼變更

- `crates/goose/Cargo.toml` —— `arboard`（剪貼簿）僅在非 Android 目標上連結。
- `crates/goose/src/clipboard.rs` —— Android 下剪貼簿改為呼叫 `termux-clipboard-set`。
- `third_party/sys-info` —— vendored 的 `sys-info`，其 C 程式碼呼叫了已從 Android 標頭檔移除、
  目前 NDK clang 會拒絕的 `index()`。透過 `[patch.crates-io]` 接入，並將呼叫改為 `strchr()`。
- `third_party/rustls-platform-verifier` —— `reqwest` 0.13 總是引入依賴 JVM 的 Android 平台驗證器，
  在沒有 JavaVM 的程序（包括 Termux）中會 panic："Expect rustls-platform-verifier to be
  initialized"。vendored 版本讓 Android 改用 WebPKI 驗證：內建 Mozilla 根憑證，並額外載入
  `SSL_CERT_FILE` / `SSL_CERT_DIR` 指定的憑證包。

其餘程式碼皆為上游程式碼，對應提交見儲存庫歷史。

## 社群

上游專案社群連結：

- [Discord](https://discord.gg/n8R5VaWDAn)
- [YouTube](https://www.youtube.com/@goose-oss)
- [LinkedIn](https://www.linkedin.com/company/goose-oss)
- [Twitter/X](https://x.com/goose_oss)

## 授權條款

Apache-2.0，詳見 [LICENSE](LICENSE)。本分支僅重新散佈上游專案的建置產物；goose 的所有版權
歸 [aaif-goose](https://github.com/aaif-goose) 的作者所有。
