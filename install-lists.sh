#!/bin/sh
# install-lists.sh — télécharge et déploie les listes .bin pré-compilées
# depuis les releases GitHub de custos-lists, côté routeur (OpenWrt/POSIX sh).
#
# Usage :
#   install-lists.sh [full|lowmem] [tag]
#     profil : full (custom + toulouse) ou lowmem (custom seul). Défaut : lowmem.
#     tag    : tag de release. Défaut : latest.
#
# Variables d'environnement :
#   CUSTOS_LISTS_REPO  dépôt GitHub (défaut : jperon/custos-lists)
#   CUSTOS_LISTS_DIR   destination (défaut : /etc/custos/lists)
#
# Vérifie SHA256SUMS, extrait de façon atomique, puis envoie SIGHUP au daemon
# si présent (rechargement à chaud des sets nft).
set -eu

profile="${1:-lowmem}"
tag="${2:-latest}"
repo="${CUSTOS_LISTS_REPO:-jperon/custos-lists}"
dest="${CUSTOS_LISTS_DIR:-/etc/custos/lists}"

case "$profile" in
  full|lowmem) ;;
  *) echo "profil invalide : $profile (attendu : full|lowmem)" >&2; exit 1 ;;
esac

archive="custos-lists-${profile}.tar.zst"
base="https://github.com/${repo}/releases/download/${tag}"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/custos-lists.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

echo "Téléchargement de $archive (tag $tag)…" >&2
curl --silent --location --fail -o "$tmp/$archive"   "$base/$archive"
curl --silent --location --fail -o "$tmp/SHA256SUMS" "$base/SHA256SUMS"

echo "Vérification SHA256…" >&2
( cd "$tmp" && grep " $archive\$" SHA256SUMS | sha256sum -c - )

echo "Extraction vers $dest…" >&2
mkdir -p "$dest"
# Extraction dans un dossier intermédiaire puis synchronisation atomique.
mkdir -p "$tmp/extract"
zstd -dc "$tmp/$archive" | tar -xf - -C "$tmp/extract"
cp -a "$tmp/extract/." "$dest/"

# Rechargement à chaud si le daemon tourne.
if pgrep -f "luajit.*main" >/dev/null 2>&1; then
  pkill -SIGHUP -f "luajit.*main" && echo "SIGHUP envoyé au daemon." >&2
fi

echo "Listes déployées ($profile, $tag) dans $dest." >&2
