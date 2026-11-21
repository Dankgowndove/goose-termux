# goose para Termux (Android)

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Español** · [Français](README.fr.md) · [Deutsch](README.de.md)

> Fork no oficial de [goose](https://github.com/aaif-goose/goose), un agente de IA extensible que
> ejecuta herramientas locales y extensiones MCP, con **binarios precompilados para Termux /
> Android (arm64)** generados por GitHub Actions. Este fork no está afiliado al proyecto original
> y no pretende fusionarse con él.

El proyecto original solo publica compilaciones para Windows, macOS y Linux. Están enlazadas contra
glibc o musl y el libc bionic de Android no puede cargarlas, por eso no funcionan en Termux. Este
fork compila la CLI con el NDK de Android para que se enlace contra el libc del sistema y se cargue
en Termux.

## Por qué los binarios Linux originales no funcionan en Termux

| | Distribución Linux normal | Termux (Android) |
| --- | --- | --- |
| Enlazador dinámico | `/lib/ld-linux-aarch64.so.1` (glibc) o `/lib/ld-musl-aarch64.so.1` | `/system/bin/linker64` (bionic) |
| Biblioteca C | glibc o musl | bionic |
| Bibliotecas compartidas | `libssl`, `libdbus`, … instaladas por la distribución | solo las bibliotecas de sistema bionic de `/system/lib64` |
| Sistema de archivos | FHS: `/bin`, `/usr/bin`, `/lib` | ninguna de esas rutas existe; los ejecutables viven en `$PREFIX/bin` (`/data/data/com.termux/files/usr`) |
| Shebang de scripts | `#!/bin/sh`, `#!/usr/bin/env bash` | `#!/data/data/com.termux/files/usr/bin/bash`, o reescrito por `termux-exec` |
| Segmento TLS en ARM64 | sin restricción | bionic exige alineación de 64 bytes |

Por eso un binario glibc falla en Termux con un error de intérprete ausente o de enlazador, aunque
esté compilado para `aarch64`. La tarea de Android de este fork enlaza con `/system/bin/linker64`
mediante el NDK, solo depende de `libc.so` / `libdl.so` / `libm.so` del sistema y es un PIE
compatible con páginas de 16 KiB.

## Requisitos

- Termux instalado desde [F-Droid](https://f-droid.org/packages/com.termux/) o los
  [releases de GitHub](https://github.com/termux/termux-app/releases): la versión de Play Store
  está desactualizada y goose no la admite.
- Android 7.0 (API 24) o superior.
- Un dispositivo ARM de 64 bits (`aarch64` / `arm64-v8a`). `armv7` y `x86_64` aún no se publican.
- `pkg install curl tar` (el instalador necesita ambos).

## Instalación

### Instalación en una línea (recomendada)

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

El instalador busca la última versión, descarga la compilación de Android, la instala en
`$PREFIX/bin/goose` y verifica que el binario se ejecute.

### Instalación manual

```bash
pkg install curl tar
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-linux-android.tar.gz
tar -xzf goose.tar.gz
mv goose "$PREFIX/bin/goose"
chmod 755 "$PREFIX/bin/goose"
goose --version
```

Si la compilación de Android no arranca por un error del enlazador, usa la versión estática:

```bash
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-unknown-linux-musl.tar.gz
```

### Actualización

Las compilaciones portables no incluyen el comando de autoactualización. Vuelve a ejecutar el
instalador para actualizar:

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

### Desinstalación

```bash
rm -f "$PREFIX/bin/goose"
# opcional: eliminar configuración, sesiones y registros
rm -rf ~/.config/goose ~/.local/share/goose ~/.local/state/goose
```

## Uso

```bash
goose configure     # elegir un proveedor y guardar su API key
goose session       # iniciar una sesión interactiva
goose --help        # ver todos los comandos
```

La configuración está en `~/.config/goose/config.yaml` y las sesiones en
`~/.local/share/goose/sessions.db`. Define `GOOSE_PATH_ROOT=/alguna/ruta` para agrupar todo el estado
de goose en un solo directorio (útil en dispositivos con poco almacenamiento interno).

Las API keys también pueden venir de las variables de entorno habituales de cada proveedor, como
`OPENAI_API_KEY` o `ANTHROPIC_API_KEY`, configuradas en `~/.bashrc` o en `$PREFIX/etc/profile.d/`.

## Notas sobre Termux

| Tema | Comportamiento |
| --- | --- |
| Rutas | Termux no tiene `/bin` ni `/usr/bin`; goose se instala en `$PREFIX/bin/goose` y todo lo demás se resuelve por `PATH`. |
| Shell | La herramienta de shell prefiere `bash` del `PATH` (`$PREFIX/bin/bash`) y `sh` lo aporta el paquete `dash` de Termux, así que no se necesita ninguna ruta FHS. |
| Keyring | Desactivado: goose guarda los secretos en su archivo de configuración en lugar del keystore de Android. |
| Inferencia local | No disponible (sin V8/llama.cpp en estas compilaciones). Usa un proveedor remoto. |
| Portapapeles | Usa `termux-clipboard-set` cuando el paquete `termux-api` está instalado. |
| TLS | Los certificados se validan contra el almacén de raíces de Mozilla incluido. Para una CA privada o corporativa, exporta `SSL_CERT_FILE=/ruta/bundle.pem`. |
| Inicio de sesión web | Termux no tiene un runtime Java al que `webbrowser` pueda llamar, así que los flujos OAuth no pueden abrir el navegador. Copia manualmente la URL mostrada. |
| Tareas en segundo plano | Android mata agresivamente los procesos en segundo plano. Ejecuta `termux-wake-lock` antes de sesiones largas. |
| Almacenamiento | Ejecuta `termux-setup-storage` si goose debe leer o escribir archivos en `/sdcard`. |

## Solución de problemas

**`CANNOT LINK EXECUTABLE ... library "..." not found`** — usa la compilación estática musl con
`GOOSE_TERMUX_VARIANT=musl`.

**`executable's TLS segment is underaligned`** — estás ejecutando una compilación glibc/musl del
proyecto original. Instala la compilación de Android de los releases de este repositorio.

**`goose` termina al instante sin salida** — ejecútalo con `RUST_LOG=debug goose --version` y abre
un issue con la salida, `getprop ro.build.version.release` y `uname -m`.

**Errores TLS como `invalid peer certificate: UnknownIssuer`** — la CA privada no está en las raíces
de Mozilla incluidas. Apunta goose a un bundle PEM con `SSL_CERT_FILE`, por ejemplo
`export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"`.

**`goose configure` falla con `Expect rustls-platform-verifier to be initialized`** — estás usando
una compilación anterior a la corrección de TLS. Reinstala con el comando de arriba.

## Compilar desde el código fuente en Termux

Compilar goose en un teléfono es lento y consume mucha memoria (el workspace descarga cientos de
crates), pero funciona:

```bash
pkg install rust cmake protobuf clang build-essential
cargo build --release -p goose-cli --bin goose --no-default-features --features portable-default
```

El conjunto de features `portable-default` desactiva la inferencia local (V8) y el keyring
D-Bus/SecretService, ninguno de los cuales existe en Android.

## Compilar con GitHub Actions

`.github/workflows/build-termux.yml` compila y publica los binarios:

| Trabajo | Runner | Resultado |
| --- | --- | --- |
| `android_aarch64` | `ubuntu-24.04` + NDK | `goose-aarch64-linux-android.tar.gz` (bionic, recomendado) |
| `musl_aarch64` | `ubuntu-24.04-arm` | `goose-aarch64-unknown-linux-musl.tar.gz` (respaldo estático) |
| `publish` | `ubuntu-24.04` | GitHub Release con ambos archivos, `install.sh` y `SHA256SUMS` |

Actívalo manualmente con **Run workflow** en Actions (`publish` es `true` por defecto) o empujando
un tag que coincida con `termux-v*`. El trabajo de Android compila para `aarch64-linux-android`
(API 24) y verifica el ELF antes de publicar: solo bibliotecas de sistema bionic, la alineación TLS
de 64 bytes que exige bionic y compatibilidad con páginas de 16 KiB.

### Cambios propios de este fork

- `crates/goose/Cargo.toml` — `arboard` (portapapeles) solo se enlaza en objetivos no Android.
- `crates/goose/src/clipboard.rs` — en Android, el portapapeles invoca `termux-clipboard-set`.
- `third_party/sys-info` — `sys-info` vendorizado, cuyo código C llama a `index()`, una función
  eliminada de las cabeceras de Android y rechazada por el clang actual del NDK. Se integra con
  `[patch.crates-io]` y la llamada se reemplaza por `strchr()`.
- `third_party/rustls-platform-verifier` — `reqwest` 0.13 siempre incorpora el verificador de
  plataforma de Android basado en JVM, que entra en pánico con "Expect rustls-platform-verifier to
  be initialized" en cualquier proceso sin JavaVM (incluido Termux). La copia vendorizada hace que
  Android valide con WebPKI contra las raíces de Mozilla incluidas y cualquier bundle indicado por
  `SSL_CERT_FILE` / `SSL_CERT_DIR`.

El resto es código original; el commit correspondiente aparece en el historial del repositorio.

## Comunidad

Enlaces de la comunidad del proyecto original:

- [Discord](https://discord.gg/n8R5VaWDAn)
- [YouTube](https://www.youtube.com/@goose-oss)
- [LinkedIn](https://www.linkedin.com/company/goose-oss)
- [Twitter/X](https://x.com/goose_oss)

## Licencia

Apache-2.0, consulta [LICENSE](LICENSE). Este fork redistribuye compilaciones del proyecto original;
todo el crédito de goose pertenece a sus autores en [aaif-goose](https://github.com/aaif-goose).
