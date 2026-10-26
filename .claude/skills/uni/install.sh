#!/usr/bin/env bash
# Instala la skill "uni" (campus de Elisava) en tu ordenador para Claude Code.
#   bash .claude/skills/uni/install.sh
# Hace tres cosas:
#   1. Copia la skill a ~/.claude/skills/uni, para usarla en cualquier proyecto.
#   2. Instala Playwright y el navegador Chromium que usa para el login.
#   3. Pide tu usuario y tu contraseña de Elisava y los guarda en
#      ~/.config/elisava/credentials, legible solo por ti.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.claude/skills/uni"
DATA="$HOME/.config/elisava"

if ! command -v node >/dev/null || ! command -v npm >/dev/null; then
  echo "Falta Node.js. Instálalo desde https://nodejs.org (o en Mac: brew install node) y vuelve a ejecutar este script."
  exit 1
fi

if [ "$SRC" != "$DEST" ]; then
  echo "→ Copiando la skill a $DEST"
  mkdir -p "$DEST"
  cp -R "$SRC/." "$DEST/"
fi

echo "→ Instalando Playwright y Chromium (puede tardar un par de minutos)"
cd "$DEST"
[ -f package.json ] || echo '{ "private": true }' > package.json
npm install --silent --no-fund --no-audit playwright
npx --yes playwright install chromium

mkdir -p "$DATA" && chmod 700 "$DATA"
if [ -f "$DATA/credentials" ]; then
  echo "→ Ya hay credenciales guardadas en $DATA/credentials (bórralo para cambiarlas)"
elif [ -n "${ELISAVA_USER:-}" ] && [ -n "${ELISAVA_PASSWORD:-}" ]; then
  echo "→ Se usarán las variables ELISAVA_USER y ELISAVA_PASSWORD"
else
  read -rp "Usuario de Elisava (ej. nombre@elisava.net): " user
  read -rsp "Contraseña: " pass; echo
  umask 077
  printf 'ELISAVA_USER=%s\nELISAVA_PASSWORD=%s\n' "$user" "$pass" > "$DATA/credentials"
  echo "→ Credenciales guardadas en $DATA/credentials"
fi

command -v pdftotext >/dev/null || echo "Consejo: instala poppler (en Mac: brew install poppler) para leer los PDF más rápido. Sin él, Claude los lee igualmente."

echo
echo "✅ Listo. Abre Claude Code en cualquier carpeta y pregunta algo sobre Elisava."
echo "   La primera vez te pasará un número para aprobar en Microsoft Authenticator."
