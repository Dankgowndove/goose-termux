# Termux（Android）版 goose

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · **日本語** · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

> [goose](https://github.com/aaif-goose/goose) の非公式フォークです。goose はローカルツールや
> MCP 拡張を実行できる拡張性の高い AI エージェントです。このリポジトリは GitHub Actions で
> ビルドした **Termux / Android（arm64）向けのビルド済みバイナリ**を提供します。本フォークは
> 上流プロジェクトとは無関係で、上流へマージする予定もありません。

上流の goose は Windows・macOS・Linux 向けのみを配布しており、それらは glibc または musl で
ビルドされているため Android の bionic libc では読み込めず、Termux では動作しません。本フォークは
Android NDK で CLI をクロスコンパイルし、Android 標準の libc にリンクすることで Termux 上で
動作するようにしています。

## 上流の Linux バイナリが Termux で動かない理由

| | 一般的な Linux ディストリビューション | Termux（Android） |
| --- | --- | --- |
| 動的リンカ | `/lib/ld-linux-aarch64.so.1`（glibc）または `/lib/ld-musl-aarch64.so.1` | `/system/bin/linker64`（bionic） |
| C ライブラリ | glibc または musl | bionic |
| 共有ライブラリ | ディストリビューションごとに導入する `libssl`、`libdbus` など | `/system/lib64` 配下の bionic システムライブラリのみ |
| ファイルシステム | FHS：`/bin`、`/usr/bin`、`/lib` | これらのパスは存在せず、実行ファイルは `$PREFIX/bin`（`/data/data/com.termux/files/usr`）に置かれる |
| スクリプトの shebang | `#!/bin/sh`、`#!/usr/bin/env bash` | `#!/data/data/com.termux/files/usr/bin/bash`、または `termux-exec` による書き換え |
| ARM64 の TLS セグメント | 制約なし | bionic は 64 バイト境界のアラインメントを要求 |

そのため、`aarch64` 向けにビルドされていても glibc バイナリは Termux 内で「インタプリタが見つからない」
またはリンクエラーになります。本フォークの Android ビルドは NDK で `/system/bin/linker64` にリンクし、
システムの `libc.so` / `libdl.so` / `libm.so` のみに依存し、16 KiB ページサイズに対応した PIE です。

## 動作要件

- [F-Droid](https://f-droid.org/packages/com.termux/) または
  [GitHub Releases](https://github.com/termux/termux-app/releases) からインストールした Termux
  （Play ストア版は古く、goose ではサポートしていません）。
- Android 7.0（API 24）以降。
- 64 ビット ARM デバイス（`aarch64` / `arm64-v8a`）。`armv7` と `x86_64` は未配布です。
- `pkg install curl tar`（インストーラが両方を使用します）。

## インストール

### ワンライナー（推奨）

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

インストーラは最新リリースを解決し、Android 版をダウンロードして `$PREFIX/bin/goose` に配置し、
バイナリが起動するか検証します。

### 手動インストール

```bash
pkg install curl tar
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-linux-android.tar.gz
tar -xzf goose.tar.gz
mv goose "$PREFIX/bin/goose"
chmod 755 "$PREFIX/bin/goose"
goose --version
```

Android 版がリンカエラーで起動しない場合は、静的フォールバック版を使用してください：

```bash
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-unknown-linux-musl.tar.gz
```

### アップデート

ポータブルビルドには自己更新コマンドが含まれません。インストーラを再実行して更新します：

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

### アンインストール

```bash
rm -f "$PREFIX/bin/goose"
# 任意：設定・セッション・ログを削除
rm -rf ~/.config/goose ~/.local/share/goose ~/.local/state/goose
```

## 使い方

```bash
goose configure     # プロバイダーを選択して API キーを保存
goose session       # 対話セッションを開始
goose --help        # すべてのコマンドを表示
```

設定は `~/.config/goose/config.yaml`、セッションは `~/.local/share/goose/sessions.db` に保存されます。
`GOOSE_PATH_ROOT=/some/dir` を設定すると goose の状態を 1 つのディレクトリにまとめられます
（内部ストレージが少ない端末で便利です）。

API キーは各プロバイダーの環境変数（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY` など）でも指定でき、
`~/.bashrc` や `$PREFIX/etc/profile.d/` のスクリプトに記述できます。

## Termux での注意点

| 項目 | 動作 |
| --- | --- |
| パス | Termux には `/bin` や `/usr/bin` がありません。goose は `$PREFIX/bin/goose` にインストールされ、その他は `PATH` で解決されます。 |
| シェル | シェルツールは `PATH` 上の `bash`（`$PREFIX/bin/bash`）を優先し、`sh` は Termux の `dash` パッケージが提供するため FHS のシェルパスは不要です。 |
| キーリング | 無効化済み。goose は Android keystore ではなく設定ファイルにシークレットを保存します。 |
| ローカル推論 | 利用できません（これらのビルドに V8/llama.cpp は含まれません）。リモートのプロバイダーを使用してください。 |
| クリップボード | `termux-api` パッケージが入っていれば `termux-clipboard-set` を使用します。 |
| TLS | 証明書は同梱の Mozilla ルートストアで検証します。プライベート/企業 CA を使う場合は `SSL_CERT_FILE=/path/to/bundle.pem` を設定してください。 |
| ブラウザログイン | Termux には `webbrowser` が呼び出せる Java ランタイムがないため、OAuth デバイスフローはブラウザを開けません。表示された URL を手動でコピーしてください。 |
| バックグラウンド処理 | Android はバックグラウンドプロセスを積極的に終了します。長時間のセッション前に `termux-wake-lock` を実行してください。 |
| ストレージ | `/sdcard` 配下のファイルを読み書きする場合は `termux-setup-storage` を実行してください。 |

## トラブルシューティング

**`CANNOT LINK EXECUTABLE ... library "..." not found`** —— `GOOSE_TERMUX_VARIANT=musl` で静的 musl 版を使用してください。

**`executable's TLS segment is underaligned`** —— 上流の glibc/musl Linux 版を実行しています。
本リポジトリのリリースにある Android 版をインストールしてください。

**`goose` が何も出力せずに即終了する** —— `RUST_LOG=debug goose --version` で実行し、
出力と `getprop ro.build.version.release`、`uname -m` を添えて issue を作成してください。

**`invalid peer certificate: UnknownIssuer` などの TLS エラー** —— プライベート CA が同梱の
Mozilla ルートに含まれていません。`SSL_CERT_FILE` で PEM バンドルを指定してください。例：
`export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"`。

**`goose configure` で `Expect rustls-platform-verifier to be initialized` が出る** —— TLS 修正前の
古いビルドです。上記のコマンドで再インストールしてください。

## Termux でソースからビルド

スマートフォンでのビルドは遅くメモリも大量に必要ですが（ワークスペースは数百の crate を取得します）、
動作はします：

```bash
pkg install rust cmake protobuf clang build-essential
cargo build --release -p goose-cli --bin goose --no-default-features --features portable-default
```

`portable-default` 機能セットはローカル推論（V8）と D-Bus/SecretService キーリングを無効化します。
どちらも Android には存在しません。

## GitHub Actions でのビルド

`.github/workflows/build-termux.yml` がバイナリをビルドして公開します：

| ジョブ | ランナー | 成果物 |
| --- | --- | --- |
| `android_aarch64` | `ubuntu-24.04` + NDK | `goose-aarch64-linux-android.tar.gz`（bionic、推奨） |
| `musl_aarch64` | `ubuntu-24.04-arm` | `goose-aarch64-unknown-linux-musl.tar.gz`（静的フォールバック） |
| `publish` | `ubuntu-24.04` | 2 つのアーカイブ、`install.sh`、`SHA256SUMS` を含む GitHub Release |

Actions 画面の **Run workflow** で手動実行（`publish` の既定値は `true`）するか、`termux-v*` に
一致するタグを push してください。Android ジョブは `aarch64-linux-android`（API 24）に
クロスコンパイルし、公開前に ELF を検証します：bionic のシステムライブラリのみに依存すること、
bionic が要求する 64 バイトの TLS アラインメント、16 KiB ページサイズ対応。

### 本フォーク独自のソース変更

- `crates/goose/Cargo.toml` —— `arboard`（クリップボード）は非 Android ターゲットでのみリンク。
- `crates/goose/src/clipboard.rs` —— Android ではクリップボード操作を `termux-clipboard-set` に委譲。
- `third_party/sys-info` —— Android のヘッダーから削除され、現在の NDK clang が拒否する
  `index()` を呼んでいた `sys-info` を vendored。`[patch.crates-io]` で組み込み、呼び出しを
  `strchr()` に置き換え。
- `third_party/rustls-platform-verifier` —— `reqwest` 0.13 は常に JVM 依存の Android プラットフォーム
  検証器を引き込みます。JavaVM を持たないプロセス（Termux を含む）では
  "Expect rustls-platform-verifier to be initialized" で panic します。vendored 版では Android が
  WebPKI で検証するようにし、同梱の Mozilla ルートに加えて `SSL_CERT_FILE` / `SSL_CERT_DIR` の
  バンドルも読み込みます。

それ以外はすべて上流のコードです（対応するコミットはリポジトリ履歴を参照）。

## コミュニティ

上流プロジェクトのコミュニティリンク：

- [Discord](https://discord.gg/n8R5VaWDAn)
- [YouTube](https://www.youtube.com/@goose-oss)
- [LinkedIn](https://www.linkedin.com/company/goose-oss)
- [Twitter/X](https://x.com/goose_oss)

## ライセンス

Apache-2.0。[LICENSE](LICENSE) を参照してください。本フォークは上流プロジェクトのビルド成果物を
再配布するもので、goose の著作権は [aaif-goose](https://github.com/aaif-goose) の作者に帰属します。
