# Termux(Android)용 goose

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · **한국어** · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

> [goose](https://github.com/aaif-goose/goose)의 비공식 포크입니다. goose는 로컬 도구와 MCP
> 확장을 실행할 수 있는 확장 가능한 AI 에이전트입니다. 이 저장소는 GitHub Actions로 빌드한
> **Termux / Android(arm64)용 사전 빌드 바이너리**를 제공합니다. 이 포크는 상류 프로젝트와
> 무관하며 상류로 병합될 계획이 없습니다.

상류 goose는 Windows, macOS, Linux 빌드만 배포하며 glibc 또는 musl로 빌드되어 Android의 bionic
libc에서 로드되지 않기 때문에 Termux에서 실행되지 않습니다. 이 포크는 Android NDK로 CLI를
교차 컴파일하여 Android 플랫폼의 libc에 링크되도록 하여 Termux에서 동작하게 합니다.

## 상류 Linux 바이너리가 Termux에서 실행되지 않는 이유

| | 일반 Linux 배포판 | Termux(Android) |
| --- | --- | --- |
| 동적 링커 | `/lib/ld-linux-aarch64.so.1`(glibc) 또는 `/lib/ld-musl-aarch64.so.1` | `/system/bin/linker64`(bionic) |
| C 라이브러리 | glibc 또는 musl | bionic |
| 공유 라이브러리 | 배포판별로 설치하는 `libssl`, `libdbus` 등 | `/system/lib64` 아래의 bionic 시스템 라이브러리만 |
| 파일 시스템 | FHS: `/bin`, `/usr/bin`, `/lib` | 해당 경로가 없으며 실행 파일은 `$PREFIX/bin`(`/data/data/com.termux/files/usr`)에 위치 |
| 스크립트 shebang | `#!/bin/sh`, `#!/usr/bin/env bash` | `#!/data/data/com.termux/files/usr/bin/bash` 또는 `termux-exec`가 재작성 |
| ARM64 TLS 세그먼트 | 제약 없음 | bionic은 64바이트 정렬을 요구 |

따라서 `aarch64`용으로 빌드된 glibc 바이너리도 Termux에서는 "인터프리터를 찾을 수 없음" 또는 링크
오류가 발생합니다. 이 포크의 Android 빌드는 NDK로 `/system/bin/linker64`에 링크하고 시스템의
`libc.so` / `libdl.so` / `libm.so`에만 의존하며, 16 KiB 페이지 크기를 지원하는 PIE입니다.

## 요구 사항

- [F-Droid](https://f-droid.org/packages/com.termux/) 또는
  [GitHub Releases](https://github.com/termux/termux-app/releases)에서 설치한 Termux
  (Play 스토어 버전은 오래되어 goose에서 지원하지 않습니다).
- Android 7.0(API 24) 이상.
- 64비트 ARM 기기(`aarch64` / `arm64-v8a`). `armv7`과 `x86_64`는 아직 배포되지 않았습니다.
- `pkg install curl tar`(설치 스크립트가 둘 다 필요로 합니다).

## 설치

### 원라인 설치(권장)

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

설치 스크립트는 최신 릴리스를 확인하고 Android 빌드를 다운로드해 `$PREFIX/bin/goose`로 설치한 뒤
바이너리가 실행되는지 검증합니다.

### 수동 설치

```bash
pkg install curl tar
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-linux-android.tar.gz
tar -xzf goose.tar.gz
mv goose "$PREFIX/bin/goose"
chmod 755 "$PREFIX/bin/goose"
goose --version
```

Android 빌드가 링커 오류로 실행되지 않으면 정적 대체 버전을 사용하세요:

```bash
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-unknown-linux-musl.tar.gz
```

### 업데이트

포터블 빌드에는 자체 업데이트 명령이 없습니다. 설치 스크립트를 다시 실행해 업그레이드하세요:

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

### 삭제

```bash
rm -f "$PREFIX/bin/goose"
# 선택 사항: 설정, 세션, 로그 삭제
rm -rf ~/.config/goose ~/.local/share/goose ~/.local/state/goose
```

## 사용법

```bash
goose configure     # 공급자를 선택하고 API 키 저장
goose session       # 대화형 세션 시작
goose --help        # 모든 명령 보기
```

설정은 `~/.config/goose/config.yaml`, 세션은 `~/.local/share/goose/sessions.db`에 저장됩니다.
`GOOSE_PATH_ROOT=/some/dir`를 설정하면 goose의 모든 상태를 한 디렉터리에 모을 수 있습니다
(내부 저장 공간이 부족한 기기에 유용합니다).

API 키는 `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` 같은 공급자 환경 변수로도 제공할 수 있으며
`~/.bashrc` 또는 `$PREFIX/etc/profile.d/` 스크립트에 넣으면 됩니다.

## Termux 참고 사항

| 항목 | 동작 |
| --- | --- |
| 경로 | Termux에는 `/bin`이나 `/usr/bin`이 없습니다. goose는 `$PREFIX/bin/goose`에 설치되고 나머지는 `PATH`로 해석됩니다. |
| 셸 | 셸 도구는 `PATH`의 `bash`(`$PREFIX/bin/bash`)를 우선 사용하며, `sh`는 Termux의 `dash` 패키지가 제공하므로 FHS 셸 경로가 필요 없습니다. |
| 키링 | 제외됨 — goose는 Android keystore 대신 설정 파일에 비밀을 저장합니다. |
| 로컬 추론 | 사용할 수 없습니다(이 빌드에는 V8/llama.cpp 없음). 원격 공급자를 사용하세요. |
| 클립보드 | `termux-api` 패키지가 있으면 `termux-clipboard-set`을 사용합니다. |
| TLS | 인증서는 내장 Mozilla 루트 저장소로 검증합니다. 사설/기업 CA는 `SSL_CERT_FILE=/path/to/bundle.pem`으로 지정하세요. |
| 브라우저 로그인 | Termux에는 `webbrowser`가 호출할 Java 런타임이 없어 OAuth 디바이스 플로가 브라우저를 열 수 없습니다. 출력된 URL을 직접 복사하세요. |
| 백그라운드 작업 | Android는 백그라운드 프로세스를 적극적으로 종료합니다. 긴 세션 전에 `termux-wake-lock`을 실행하세요. |
| 저장 공간 | goose가 `/sdcard` 파일을 읽고 써야 한다면 `termux-setup-storage`를 실행하세요. |

## 문제 해결

**`CANNOT LINK EXECUTABLE ... library "..." not found`** — `GOOSE_TERMUX_VARIANT=musl`로 정적 musl
빌드를 사용하세요.

**`executable's TLS segment is underaligned`** — 상류 glibc/musl Linux 빌드를 실행 중입니다.
이 저장소 릴리스의 Android 빌드를 설치하세요.

**`goose`가 아무 출력 없이 즉시 종료** — `RUST_LOG=debug goose --version`으로 실행하고 출력과
`getprop ro.build.version.release`, `uname -m`을 함께 이슈에 남겨 주세요.

**`invalid peer certificate: UnknownIssuer` 같은 TLS 오류** — 사설 CA가 내장 Mozilla 루트에 없습니다.
`SSL_CERT_FILE`로 PEM 번들을 지정하세요. 예: `export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"`.

**`goose configure`에서 `Expect rustls-platform-verifier to be initialized`** — TLS 수정 이전
빌드입니다. 위 명령으로 다시 설치하세요.

## Termux에서 소스로 빌드

휴대폰에서 goose를 빌드하는 것은 느리고 메모리를 많이 사용하지만(워크스페이스가 수백 개 crate를
가져옵니다) 가능합니다:

```bash
pkg install rust cmake protobuf clang build-essential
cargo build --release -p goose-cli --bin goose --no-default-features --features portable-default
```

`portable-default` 기능 집합은 로컬 추론(V8)과 D-Bus/SecretService 키링을 비활성화합니다.
둘 다 Android에는 존재하지 않습니다.

## GitHub Actions로 빌드

`.github/workflows/build-termux.yml`이 바이너리를 빌드하고 게시합니다:

| 작업 | 실행 환경 | 산출물 |
| --- | --- | --- |
| `android_aarch64` | `ubuntu-24.04` + NDK | `goose-aarch64-linux-android.tar.gz`(bionic, 권장) |
| `musl_aarch64` | `ubuntu-24.04-arm` | `goose-aarch64-unknown-linux-musl.tar.gz`(정적 대체) |
| `publish` | `ubuntu-24.04` | 두 아카이브, `install.sh`, `SHA256SUMS`를 포함한 GitHub Release |

Actions 페이지에서 **Run workflow**로 수동 실행(`publish` 기본값 `true`)하거나 `termux-v*`와
일치하는 태그를 푸시하세요. Android 작업은 `aarch64-linux-android`(API 24)로 교차 컴파일하고
게시 전에 ELF를 검증합니다: bionic 시스템 라이브러리에만 의존, bionic이 요구하는 64바이트 TLS
정렬, 16 KiB 페이지 크기 호환.

### 이 포크에만 있는 소스 변경

- `crates/goose/Cargo.toml` — `arboard`(클립보드)는 비 Android 대상에서만 링크됩니다.
- `crates/goose/src/clipboard.rs` — Android에서는 클립보드 접근이 `termux-clipboard-set`을 호출합니다.
- `third_party/sys-info` — Android 헤더에서 제거되어 최신 NDK clang이 거부하는 `index()`를 호출하던
  `sys-info`를 vendored했습니다. `[patch.crates-io]`로 연결하고 호출을 `strchr()`로 바꿨습니다.
- `third_party/rustls-platform-verifier` — `reqwest` 0.13은 항상 JVM 기반 Android 플랫폼 검증기를
  끌어옵니다. JavaVM이 없는 프로세스(Termux 포함)에서는
  "Expect rustls-platform-verifier to be initialized"로 panic합니다. vendored 버전은 Android가
  WebPKI로 검증하도록 하며, 내장 Mozilla 루트와 `SSL_CERT_FILE` / `SSL_CERT_DIR` 번들을 함께 사용합니다.

나머지는 모두 상류 코드이며 해당 커밋은 저장소 기록에서 확인할 수 있습니다.

## 커뮤니티

상류 프로젝트 커뮤니티 링크:

- [Discord](https://discord.gg/n8R5VaWDAn)
- [YouTube](https://www.youtube.com/@goose-oss)
- [LinkedIn](https://www.linkedin.com/company/goose-oss)
- [Twitter/X](https://x.com/goose_oss)

## 라이선스

Apache-2.0, [LICENSE](LICENSE) 참조. 이 포크는 상류 프로젝트의 빌드 산출물을 재배포할 뿐이며
goose에 대한 모든 권리는 [aaif-goose](https://github.com/aaif-goose)의 저자에게 있습니다.
