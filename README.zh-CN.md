# 适用于 Termux 的 goose（Android）

[English](README.md) · **简体中文** · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

> [goose](https://github.com/aaif-goose/goose) 的非官方分支（fork）——一个可扩展的 AI Agent，
> 可运行本地工具与 MCP 扩展。本仓库通过 GitHub Actions 提供**预编译的 Termux / Android（arm64）
> 二进制**。本分支与上游项目无关，也不会合并回上游。

上游 goose 只发布 Windows、macOS 和 Linux 版本，它们基于 glibc 或 musl 构建，无法被 Android 的
bionic libc 加载，所以不能在 Termux 中运行。本分支使用 Android NDK 交叉编译 CLI，使其链接
Android 平台自带的 libc，从而可以在 Termux 中正常运行。

## 为什么上游 Linux 二进制在 Termux 里跑不起来

| | 普通 Linux 发行版 | Termux（Android） |
| --- | --- | --- |
| 动态链接器 | `/lib/ld-linux-aarch64.so.1`（glibc）或 `/lib/ld-musl-aarch64.so.1` | `/system/bin/linker64`（bionic） |
| C 运行库 | glibc 或 musl | bionic |
| 共享库 | 按发行版安装的 `libssl`、`libdbus` 等 | 仅 `/system/lib64` 下的 bionic 系统库 |
| 文件系统布局 | FHS：`/bin`、`/usr/bin`、`/lib` | 这些路径都不存在；可执行文件位于 `$PREFIX/bin`（`/data/data/com.termux/files/usr`） |
| 脚本 shebang | `#!/bin/sh`、`#!/usr/bin/env bash` | `#!/data/data/com.termux/files/usr/bin/bash`，或由 `termux-exec` 自动重写 |
| ARM64 TLS 段 | 无要求 | bionic 要求 64 字节对齐 |

因此，即使是 `aarch64` 架构的 glibc 二进制，在 Termux 中也只会报"找不到解释器"或链接错误。
本分支的 Android 构建使用 NDK 链接 `/system/bin/linker64`，只依赖系统自带的
`libc.so` / `libdl.so` / `libm.so`，并且是兼容 16 KiB 页大小的 PIE 可执行文件。

## 环境要求

- 通过 [F-Droid](https://f-droid.org/packages/com.termux/) 或
  [GitHub Releases](https://github.com/termux/termux-app/releases) 安装的 Termux —— Play 商店版本
  过于陈旧，不受 goose 支持。
- Android 7.0（API 24）或更高版本。
- 64 位 ARM 设备（`aarch64` / `arm64-v8a`）。暂未发布 `armv7` 和 `x86_64` 版本。
- 执行 `pkg install curl tar`（安装脚本需要这两者）。

## 安装

### 一键安装（推荐）

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

安装脚本会解析最新 Release、下载 Android 版本、安装到 `$PREFIX/bin/goose`，并验证二进制能否启动。

> 使用其他 Android 终端 App、Termux 分支，或通过 `su`/`tmux` 启动的 shell 同样可以：安装脚本会
> 通过 `$PREFIX` 和 `/system/bin/linker64` 识别 Android 环境。若仍被拒绝，在命令前加上
> `GOOSE_TERMUX_FORCE=1` 即可。

### 手动安装

```bash
pkg install curl tar
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-linux-android.tar.gz
tar -xzf goose.tar.gz
mv goose "$PREFIX/bin/goose"
chmod 755 "$PREFIX/bin/goose"
goose --version
```

如果 Android 版本因链接错误无法启动，改用静态回退版：

```bash
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-unknown-linux-musl.tar.gz
```

### 更新

精简构建不包含自更新命令，重跑安装脚本即可升级：

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

### 卸载

```bash
rm -f "$PREFIX/bin/goose"
# 可选：删除配置、会话和日志
rm -rf ~/.config/goose ~/.local/share/goose ~/.local/state/goose
```

## 使用

```bash
goose configure     # 选择模型提供商并保存 API Key
goose session       # 启动交互式会话
goose --help        # 查看所有命令
```

配置保存在 `~/.config/goose/config.yaml`，会话数据在 `~/.local/share/goose/sessions.db`。
设置 `GOOSE_PATH_ROOT=/某个目录` 可以把 goose 的全部状态集中到一个目录（适合内部存储紧张的设备）。

API Key 也可以通过常见提供商的环境变量提供，例如 `OPENAI_API_KEY` 或 `ANTHROPIC_API_KEY`，
可写入 `~/.bashrc` 或 `$PREFIX/etc/profile.d/` 下的脚本。

## Termux 注意事项

| 项目 | 行为 |
| --- | --- |
| 路径 | Termux 没有 `/bin` 或 `/usr/bin`；goose 安装到 `$PREFIX/bin/goose`，其余命令都通过 `PATH` 解析。 |
| Shell | shell 工具优先使用 `PATH` 中的 `bash`（`$PREFIX/bin/bash`），`sh` 由 Termux 的 `dash` 包提供，因此不依赖 FHS 路径。 |
| Keyring | 已裁剪 —— goose 把密钥保存在自己的配置文件中，而不是 Android keystore。 |
| 本地推理 | 不可用（这些构建不含 V8/llama.cpp），请使用远程提供商。 |
| 剪贴板 | 安装 `termux-api` 包后通过 `termux-clipboard-set` 工作。 |
| TLS | 使用内置的 Mozilla 根证书校验证书。如需私有/企业 CA，导出 `SSL_CERT_FILE=/路径/bundle.pem`。 |
| 浏览器登录 | Termux 中没有可供 `webbrowser` 调用的 Java 运行时，OAuth 设备流无法自动打开浏览器，请手动复制打印出的 URL。 |
| 后台任务 | Android 会积极杀后台进程，长时间会话前先执行 `termux-wake-lock`。 |
| 存储 | 如果 goose 需要读写 `/sdcard` 下的文件，先执行 `termux-setup-storage`。 |

## 常见问题排查

**`CANNOT LINK EXECUTABLE ... library "..." not found`** —— 使用静态 musl 版本：
`GOOSE_TERMUX_VARIANT=musl`。

**`executable's TLS segment is underaligned`** —— 你运行的是上游的 glibc/musl Linux 版本，
请改用本仓库 Release 中的 Android 版本。

**`goose` 立即退出且没有任何输出** —— 用 `RUST_LOG=debug goose --version` 运行，并把输出连同
`getprop ro.build.version.release` 和 `uname -m` 一起提交 issue。

**TLS 报错如 `invalid peer certificate: UnknownIssuer`** —— 私有 CA 不在内置 Mozilla 根证书中。
通过 `SSL_CERT_FILE` 指向 PEM 证书包，例如 `export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"`。

**`goose configure` 报 `Expect rustls-platform-verifier to be initialized`** —— 你使用的是 TLS
修复之前的旧构建，请用上面的命令重新安装。

## 在 Termux 中从源码构建

在手机上构建 goose 很慢且很吃内存（工作区会拉取数百个 crate），但确实可行：

```bash
pkg install rust cmake protobuf clang build-essential
cargo build --release -p goose-cli --bin goose --no-default-features --features portable-default
```

`portable-default` 特性集关闭了本地推理（V8）和 D-Bus/SecretService keyring，二者在 Android 上都不存在。

## 通过 GitHub Actions 构建

`.github/workflows/build-termux.yml` 负责构建并发布二进制：

| 任务 | 运行环境 | 产物 |
| --- | --- | --- |
| `android_aarch64` | `ubuntu-24.04` + NDK | `goose-aarch64-linux-android.tar.gz`（bionic，推荐） |
| `musl_aarch64` | `ubuntu-24.04-arm` | `goose-aarch64-unknown-linux-musl.tar.gz`（静态回退版） |
| `publish` | `ubuntu-24.04` | 发布 GitHub Release，包含两个压缩包、`install.sh` 和 `SHA256SUMS` |

可以在 Actions 页面点 **Run workflow** 手动触发（`publish` 默认 `true`），或推送匹配 `termux-v*`
的 tag。Android 任务会交叉编译到 `aarch64-linux-android`（API 24），并在发布前校验 ELF：只依赖
bionic 系统库、满足 bionic 要求的 64 字节 TLS 对齐、兼容 16 KiB 页大小。

### 仅本分支的源码改动

- `crates/goose/Cargo.toml` —— `arboard`（剪贴板）仅在非 Android 目标上链接。
- `crates/goose/src/clipboard.rs` —— Android 下剪贴板改为调用 `termux-clipboard-set`。
- `third_party/sys-info` —— vendored 的 `sys-info`，其 C 代码调用了已从 Android 头文件移除、
  当前 NDK clang 会拒绝的 `index()`。通过 `[patch.crates-io]` 接入，并把调用改为 `strchr()`。
- `third_party/rustls-platform-verifier` —— `reqwest` 0.13 总是引入依赖 JVM 的 Android 平台校验器，
  在没有 JavaVM 的进程（包括 Termux）中会 panic："Expect rustls-platform-verifier to be
  initialized"。vendored 版本让 Android 改用 WebPKI 校验：内置 Mozilla 根证书，并额外加载
  `SSL_CERT_FILE` / `SSL_CERT_DIR` 指定的证书包。

其余代码均为上游代码，对应提交见仓库历史。

## 社区

上游项目社区链接：

- [Discord](https://discord.gg/n8R5VaWDAn)
- [YouTube](https://www.youtube.com/@goose-oss)
- [LinkedIn](https://www.linkedin.com/company/goose-oss)
- [Twitter/X](https://x.com/goose_oss)

## 许可证

Apache-2.0，详见 [LICENSE](LICENSE)。本分支仅重新分发上游项目的构建产物；goose 的所有版权
归 [aaif-goose](https://github.com/aaif-goose) 的作者所有。
