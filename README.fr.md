# goose pour Termux (Android)

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · **Français** · [Deutsch](README.de.md)

> Fork non officiel de [goose](https://github.com/aaif-goose/goose) — un agent IA extensible qui
> exécute des outils locaux et des extensions MCP — avec des **binaires précompilés pour Termux /
> Android (arm64)** produits par GitHub Actions. Ce fork n'est pas affilié au projet amont et n'a
> pas vocation à être fusionné avec lui.

Le projet amont ne publie que des versions Windows, macOS et Linux. Elles sont liées à glibc ou
musl, que la libc bionic d'Android ne peut pas charger : c'est pourquoi elles ne fonctionnent pas
dans Termux. Ce fork compile la CLI avec le NDK Android afin qu'elle se lie à la libc de la
plateforme et se charge dans Termux.

## Pourquoi les binaires Linux amont ne fonctionnent pas dans Termux

| | Distribution Linux classique | Termux (Android) |
| --- | --- | --- |
| Éditeur de liens dynamique | `/lib/ld-linux-aarch64.so.1` (glibc) ou `/lib/ld-musl-aarch64.so.1` | `/system/bin/linker64` (bionic) |
| Bibliothèque C | glibc ou musl | bionic |
| Bibliothèques partagées | `libssl`, `libdbus`, … installées par la distribution | uniquement les bibliothèques système bionic de `/system/lib64` |
| Arborescence | FHS : `/bin`, `/usr/bin`, `/lib` | ces chemins n'existent pas ; les exécutables sont dans `$PREFIX/bin` (`/data/data/com.termux/files/usr`) |
| Shebang des scripts | `#!/bin/sh`, `#!/usr/bin/env bash` | `#!/data/data/com.termux/files/usr/bin/bash`, ou réécrit par `termux-exec` |
| Segment TLS ARM64 | aucune contrainte | bionic exige un alignement de 64 octets |

Un binaire glibc échoue donc dans Termux avec une erreur d'interpréteur manquant ou d'édition de
liens, même compilé pour `aarch64`. La tâche Android de ce fork se lie à `/system/bin/linker64` via
le NDK, ne dépend que de `libc.so` / `libdl.so` / `libm.so` du système et est un PIE compatible avec
les pages de 16 Kio.

## Prérequis

- Termux installé depuis [F-Droid](https://f-droid.org/packages/com.termux/) ou les
  [releases GitHub](https://github.com/termux/termux-app/releases) — la version du Play Store est
  obsolète et non prise en charge par goose.
- Android 7.0 (API 24) ou plus récent.
- Un appareil ARM 64 bits (`aarch64` / `arm64-v8a`). `armv7` et `x86_64` ne sont pas encore publiés.
- `pkg install curl tar` (l'installateur a besoin des deux).

## Installation

### En une ligne (recommandé)

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

L'installateur résout la dernière version, télécharge la compilation Android, l'installe dans
`$PREFIX/bin/goose` et vérifie que le binaire démarre.

### Installation manuelle

```bash
pkg install curl tar
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-linux-android.tar.gz
tar -xzf goose.tar.gz
mv goose "$PREFIX/bin/goose"
chmod 755 "$PREFIX/bin/goose"
goose --version
```

Si la compilation Android ne démarre pas à cause d'une erreur d'édition de liens, utilisez la
version statique de repli :

```bash
curl -fL -o goose.tar.gz \
  https://github.com/Dankgowndove/goose-termux/releases/latest/download/goose-aarch64-unknown-linux-musl.tar.gz
```

### Mise à jour

Les compilations portables n'incluent pas la commande d'auto-mise à jour. Relancez l'installateur
pour mettre à jour :

```bash
curl -fsSL https://github.com/Dankgowndove/goose-termux/releases/latest/download/install.sh | bash
```

### Désinstallation

```bash
rm -f "$PREFIX/bin/goose"
# facultatif : supprimer la configuration, les sessions et les journaux
rm -rf ~/.config/goose ~/.local/share/goose ~/.local/state/goose
```

## Utilisation

```bash
goose configure     # choisir un fournisseur et enregistrer sa clé API
goose session       # démarrer une session interactive
goose --help        # lister toutes les commandes
```

La configuration se trouve dans `~/.config/goose/config.yaml` et les sessions dans
`~/.local/share/goose/sessions.db`. Définissez `GOOSE_PATH_ROOT=/un/chemin` pour regrouper tout
l'état de goose dans un seul répertoire (utile sur les appareils peu dotés en stockage interne).

Les clés API peuvent aussi provenir des variables d'environnement habituelles des fournisseurs, par
exemple `OPENAI_API_KEY` ou `ANTHROPIC_API_KEY`, définies dans `~/.bashrc` ou
`$PREFIX/etc/profile.d/`.

## Notes spécifiques à Termux

| Sujet | Comportement |
| --- | --- |
| Chemins | Termux n'a ni `/bin` ni `/usr/bin` ; goose est installé dans `$PREFIX/bin/goose` et le reste est résolu via `PATH`. |
| Shell | L'outil shell privilégie `bash` du `PATH` (`$PREFIX/bin/bash`) et `sh` est fourni par le paquet `dash` de Termux : aucun chemin FHS n'est nécessaire. |
| Keyring | Désactivé — goose stocke les secrets dans son fichier de configuration au lieu du keystore Android. |
| Inférence locale | Indisponible (pas de V8/llama.cpp dans ces compilations). Utilisez un fournisseur distant. |
| Presse-papiers | Utilise `termux-clipboard-set` lorsque le paquet `termux-api` est installé. |
| TLS | Les certificats sont vérifiés avec le magasin de racines Mozilla intégré. Pour une AC privée ou d'entreprise, exportez `SSL_CERT_FILE=/chemin/bundle.pem`. |
| Connexion navigateur | `webbrowser` n'a pas de runtime Java à appeler dans Termux : les flux OAuth ne peuvent pas ouvrir de navigateur. Copiez l'URL affichée manuellement. |
| Tâches en arrière-plan | Android tue agressivement les processus en arrière-plan. Lancez `termux-wake-lock` avant les sessions longues. |
| Stockage | Lancez `termux-setup-storage` si goose doit lire/écrire des fichiers sous `/sdcard`. |

## Dépannage

**`CANNOT LINK EXECUTABLE ... library "..." not found`** — utilisez la compilation musl statique
avec `GOOSE_TERMUX_VARIANT=musl`.

**`executable's TLS segment is underaligned`** — vous exécutez une compilation glibc/musl du projet
amont. Installez plutôt la compilation Android des releases de ce dépôt.

**`goose` quitte immédiatement sans sortie** — lancez-le avec `RUST_LOG=debug goose --version` et
ouvrez un ticket avec la sortie, `getprop ro.build.version.release` et `uname -m`.

**Erreurs TLS telles que `invalid peer certificate: UnknownIssuer`** — l'AC privée n'est pas dans
les racines Mozilla intégrées. Indiquez un bundle PEM à goose via `SSL_CERT_FILE`, par exemple
`export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"`.

**`goose configure` échoue avec `Expect rustls-platform-verifier to be initialized`** — vous
utilisez une compilation antérieure au correctif TLS. Réinstallez avec la commande ci-dessus.

## Compiler depuis les sources dans Termux

Compiler goose sur un téléphone est lent et gourmand en mémoire (le workspace récupère des centaines
de crates), mais cela fonctionne :

```bash
pkg install rust cmake protobuf clang build-essential
cargo build --release -p goose-cli --bin goose --no-default-features --features portable-default
```

Le jeu de fonctionnalités `portable-default` désactive l'inférence locale (V8) et le keyring
D-Bus/SecretService, tous deux absents d'Android.

## Compiler via GitHub Actions

`.github/workflows/build-termux.yml` compile et publie les binaires :

| Tâche | Runner | Résultat |
| --- | --- | --- |
| `android_aarch64` | `ubuntu-24.04` + NDK | `goose-aarch64-linux-android.tar.gz` (bionic, recommandé) |
| `musl_aarch64` | `ubuntu-24.04-arm` | `goose-aarch64-unknown-linux-musl.tar.gz` (repli statique) |
| `publish` | `ubuntu-24.04` | GitHub Release avec les deux archives, `install.sh` et `SHA256SUMS` |

Déclenchez-le manuellement via **Run workflow** dans Actions (`publish` vaut `true` par défaut) ou
en poussant un tag correspondant à `termux-v*`. La tâche Android compile pour
`aarch64-linux-android` (API 24) et vérifie l'ELF avant publication : dépendances limitées aux
bibliothèques système bionic, alignement TLS de 64 octets exigé par bionic et compatibilité avec
les pages de 16 Kio.

### Modifications propres à ce fork

- `crates/goose/Cargo.toml` — `arboard` (presse-papiers) n'est lié que sur les cibles non Android.
- `crates/goose/src/clipboard.rs` — sous Android, l'accès au presse-papiers appelle
  `termux-clipboard-set`.
- `third_party/sys-info` — `sys-info` vendorisé, dont le code C appelle `index()`, une fonction
  supprimée des en-têtes Android et rejetée par le clang actuel du NDK. Il est intégré via
  `[patch.crates-io]` et l'appel est remplacé par `strchr()`.
- `third_party/rustls-platform-verifier` — `reqwest` 0.13 tire toujours le vérificateur de
  plateforme Android basé sur la JVM, qui panique avec « Expect rustls-platform-verifier to be
  initialized » dans tout processus sans JavaVM (Termux inclus). La copie vendorisée fait vérifier
  les certificats par WebPKI sous Android, avec les racines Mozilla intégrées et tout bundle indiqué
  par `SSL_CERT_FILE` / `SSL_CERT_DIR`.

Le reste est le code amont ; le commit correspondant figure dans l'historique du dépôt.

## Communauté

Liens de la communauté du projet amont :

- [Discord](https://discord.gg/n8R5VaWDAn)
- [YouTube](https://www.youtube.com/@goose-oss)
- [LinkedIn](https://www.linkedin.com/company/goose-oss)
- [Twitter/X](https://x.com/goose_oss)

## Licence

Apache-2.0, voir [LICENSE](LICENSE). Ce fork redistribue des compilations du projet amont ; tout le
mérite de goose revient à ses auteurs chez [aaif-goose](https://github.com/aaif-goose).
