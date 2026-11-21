# goose für Termux (Android)

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · **Deutsch**

> Inoffizieller Fork von [goose](https://github.com/aaif-goose/goose) — einem erweiterbaren
> KI-Agenten, der lokale Tools und MCP-Erweiterungen ausführt — mit **vorkompilierten Binärdateien
> für Termux / Android (arm64)**, die über GitHub Actions erstellt werden. Dieser Fork gehört nicht
> zum Upstream-Projekt und soll nicht dorthin zurückgeführt werden.

Upstream goose liefert nur Builds für Windows, macOS und Linux. Diese sind gegen glibc oder musl
gelinkt, was Androids bionic libc nicht laden kann – deshalb laufen sie nicht in Termux. Dieser
Fork kompiliert die CLI mit dem Android NDK, sodass sie gegen die plattformeigene libc gelinkt wird
und in Termux lädt.

## Warum die Upstream-Linux-Binärdateien nicht in Termux laufen

| | Normale Linux-Distribution | Termux (Android) |
| --- | --- | --- |
| Dynamischer Linker | `/lib/ld-linux-aarch64.so.1` (glibc) oder `/lib/ld-musl-aarch64.so.1` | `/system/bin/linker64` (bionic) |
| C-Bibliothek | glibc oder musl | bionic |
| Gemeinsame Bibliotheken | pro Distribution installierte `libssl`, `libdbus`, … | nur die bionic-Systembibliotheken unter `/system/lib64` |
| Dateisystem | FHS: `/bin`, `/usr/bin`, `/lib` | keine dieser Pfade existieren; Programme liegen in `$PREFIX/bin` (`/data/data/com.termux/files/usr`) |
| Shebangs von Skripten | `#!/bin/sh`, `#!/usr/bin/env bash` | `#!/data/data/com.termux/files/usr/bin/bash` oder von `termux-exec` umgeschrieben |
| ARM64-TLS-Segment | keine Vorgabe | bionic verlangt 64-Byte-Ausrichtung |

Ein glibc-Binary schlägt daher in Termux mit einem Fehler über einen fehlenden Interpreter oder
Linker fehl, auch wenn es für `aarch64` gebaut wurde. Der Android-Job dieses Forks linkt mit dem NDK
gegen `/system/bin/linker64`, hängt nur von `libc.so` / `libdl.so` / `libm.so` des Systems ab und ist
ein mit 16-KiB-Seiten kompatibles PIE.

## Voraussetzungen

- Termux aus [F-Droid](https://f-droid.org/packages/com.termux/) oder den
  [GitHub-Releases](https://github.com/termux/termux-app/releases) — die Play-Store-Version ist
  veraltet und wird von goose nicht unterstützt.
- Android 7.0 (API 24) oder neuer.
- Ein 64-Bit-ARM-Gerät (`aarch64` / `arm64-v8a`). `armv7` und `x86_64` werden noch nicht
  veröffentlicht.
- `pkg install curl tar` (der Installer benötigt beides).

## Installation

### Einzeiler (empfohlen)

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

Der Installer ermittelt die neueste Version, lädt den Android-Build herunter, installiert ihn als
`$PREFIX/bin/goose` und prüft, ob die Binärdatei startet.

### Manuelle Installation

```bash
pkg install curl tar
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-linux-android.tar.gz
tar -xzf goose.tar.gz
mv goose "$PREFIX/bin/goose"
chmod 755 "$PREFIX/bin/goose"
goose --version
```

Startet der Android-Build wegen eines Linker-Fehlers nicht, verwenden Sie den statischen
Fallback-Build:

```bash
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-unknown-linux-musl.tar.gz
```

### Aktualisieren

Portable Builds enthalten keinen Selbstupdate-Befehl. Führen Sie den Installer erneut aus:

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

### Deinstallieren

```bash
rm -f "$PREFIX/bin/goose"
# optional: Konfiguration, Sitzungen und Logs löschen
rm -rf ~/.config/goose ~/.local/share/goose ~/.local/state/goose
```

## Verwendung

```bash
goose configure     # Provider wählen und API-Key speichern
goose session       # interaktive Sitzung starten
goose --help        # alle Befehle anzeigen
```

Die Konfiguration liegt in `~/.config/goose/config.yaml`, Sitzungen in
`~/.local/share/goose/sessions.db`. Mit `GOOSE_PATH_ROOT=/ein/verzeichnis` lässt sich der gesamte
goose-Zustand in einem Verzeichnis bündeln (praktisch bei knappem internen Speicher).

API-Keys können auch über die üblichen Umgebungsvariablen der Provider kommen, etwa
`OPENAI_API_KEY` oder `ANTHROPIC_API_KEY`, gesetzt in `~/.bashrc` oder unter
`$PREFIX/etc/profile.d/`.

## Hinweise zu Termux

| Thema | Verhalten |
| --- | --- |
| Pfade | Termux kennt kein `/bin` oder `/usr/bin`; goose wird unter `$PREFIX/bin/goose` installiert und alles andere über `PATH` aufgelöst. |
| Shell | Das Shell-Tool bevorzugt `bash` aus dem `PATH` (`$PREFIX/bin/bash`), und `sh` liefert das Termux-Paket `dash` — es wird kein FHS-Shellpfad benötigt. |
| Keyring | Entfernt — goose speichert Geheimnisse in seiner Konfigurationsdatei statt im Android-Keystore. |
| Lokale Inferenz | Nicht verfügbar (kein V8/llama.cpp in diesen Builds). Nutzen Sie einen Remote-Provider. |
| Zwischenablage | Nutzt `termux-clipboard-set`, wenn das Paket `termux-api` installiert ist. |
| TLS | Zertifikate werden gegen den mitgelieferten Mozilla-Roots-Speicher geprüft. Für eine private oder Unternehmens-CA `SSL_CERT_FILE=/pfad/bundle.pem` exportieren. |
| Browser-Login | In Termux gibt es keine Java-Laufzeit für `webbrowser`, daher können OAuth-Geräteflüsse keinen Browser öffnen. Kopieren Sie die angezeigte URL manuell. |
| Hintergrundarbeit | Android beendet Hintergrundprozesse aggressiv. Führen Sie vor langen Sitzungen `termux-wake-lock` aus. |
| Speicher | Führen Sie `termux-setup-storage` aus, wenn goose Dateien unter `/sdcard` lesen oder schreiben soll. |

## Fehlerbehebung

**`CANNOT LINK EXECUTABLE ... library "..." not found`** — nutzen Sie den statischen musl-Build mit
`GOOSE_TERMUX_VARIANT=musl`.

**`executable's TLS segment is underaligned`** — Sie führen einen glibc/musl-Linux-Build des
Upstream-Projekts aus. Installieren Sie stattdessen den Android-Build aus den Releases dieses
Repositorys.

**`goose` beendet sich sofort ohne Ausgabe** — mit `RUST_LOG=debug goose --version` ausführen und
ein Issue mit der Ausgabe, `getprop ro.build.version.release` und `uname -m` erstellen.

**TLS-Fehler wie `invalid peer certificate: UnknownIssuer`** — die private CA fehlt in den
mitgelieferten Mozilla-Roots. Weisen Sie goose per `SSL_CERT_FILE` auf ein PEM-Bundle hin, zum
Beispiel `export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"`.

**`goose configure` bricht mit `Expect rustls-platform-verifier to be initialized` ab** — Sie
verwenden einen Build vor dem TLS-Fix. Installieren Sie ihn mit dem obigen Befehl neu.

## Aus dem Quellcode in Termux bauen

goose auf einem Telefon zu bauen ist langsam und speicherhungrig (der Workspace zieht Hunderte von
Crates), funktioniert aber:

```bash
pkg install rust cmake protobuf clang build-essential
cargo build --release -p goose-cli --bin goose --no-default-features --features portable-default
```

Das Feature-Set `portable-default` deaktiviert lokale Inferenz (V8) und den D-Bus/SecretService-
Keyring, die es unter Android beide nicht gibt.

## Über GitHub Actions bauen

`.github/workflows/build-termux.yml` baut und veröffentlicht die Binärdateien:

| Job | Runner | Ergebnis |
| --- | --- | --- |
| `android_aarch64` | `ubuntu-24.04` + NDK | `goose-aarch64-linux-android.tar.gz` (bionic, empfohlen) |
| `musl_aarch64` | `ubuntu-24.04-arm` | `goose-aarch64-unknown-linux-musl.tar.gz` (statischer Fallback) |
| `publish` | `ubuntu-24.04` | GitHub Release mit beiden Archiven, `install.sh` und `SHA256SUMS` |

Manuell auslösen über **Run workflow** in Actions (`publish` ist standardmäßig `true`) oder durch
Push eines Tags, der `termux-v*` entspricht. Der Android-Job kompiliert für
`aarch64-linux-android` (API 24) und prüft das ELF vor der Veröffentlichung: nur bionic-
Systembibliotheken, die von bionic verlangte 64-Byte-TLS-Ausrichtung und Kompatibilität mit
16-KiB-Seiten.

### Nur in diesem Fork enthaltene Quellcodeänderungen

- `crates/goose/Cargo.toml` — `arboard` (Zwischenablage) wird nur für Nicht-Android-Ziele gelinkt.
- `crates/goose/src/clipboard.rs` — unter Android ruft der Zwischenablagezugriff
  `termux-clipboard-set` auf.
- `third_party/sys-info` — vendored `sys-info`, dessen C-Code `index()` aufruft — eine Funktion,
  die aus Androids Headern entfernt wurde und vom aktuellen NDK-clang abgelehnt wird. Über
  `[patch.crates-io]` eingebunden; der Aufruf wurde durch `strchr()` ersetzt.
- `third_party/rustls-platform-verifier` — `reqwest` 0.13 zieht immer den JVM-basierten
  Android-Plattformverifier ein, der in Prozessen ohne JavaVM (auch Termux) mit „Expect
  rustls-platform-verifier to be initialized" panikt. Die vendored Kopie lässt Android stattdessen
  mit WebPKI prüfen — gegen die mitgelieferten Mozilla-Roots und jedes über `SSL_CERT_FILE` /
  `SSL_CERT_DIR` angegebene Bundle.

Alles Weitere ist Upstream-Code; der zugehörige Commit steht in der Repository-Historie.

## Community

Community-Links des Upstream-Projekts:

- [Discord](https://discord.gg/n8R5VaWDAn)
- [YouTube](https://www.youtube.com/@goose-oss)
- [LinkedIn](https://www.linkedin.com/company/goose-oss)
- [Twitter/X](https://x.com/goose_oss)

## Lizenz

Apache-2.0, siehe [LICENSE](LICENSE). Dieser Fork verteilt Builds des Upstream-Projekts weiter;
alle Credits für goose gehören den Autoren bei [aaif-goose](https://github.com/aaif-goose).
