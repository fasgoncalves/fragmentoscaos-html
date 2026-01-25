#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# Extrai ficheiros (pdf/doc/docx/ppt/pptx) de um WordPress local
# para um directório destino "Files"
#
# Uso:
#   ./extract_wp_files.sh /caminho/para/wordpress/wp-content Files
#
# Exemplos:
#   ./extract_wp_files.sh /var/www/html/wp-content Files
#   ./extract_wp_files.sh ../contents/wp-content Files
#
# Flags opcionais (env vars):
#   PRESERVE_TREE=1   -> preserva estrutura relativa (default: 1)
#   DRY_RUN=1         -> não copia, só lista
# ==========================================================

SRC="${1:-}"
DEST="${2:-Files}"

if [[ -z "$SRC" ]]; then
  echo "Uso: $0 <wp-content-dir> [dest-dir]"
  exit 1
fi

SRC="$(realpath "$SRC")"
DEST="$(realpath "$DEST" 2>/dev/null || true)"

if [[ ! -d "$SRC" ]]; then
  echo "[ERRO] Directório de origem não existe: $SRC"
  exit 2
fi

mkdir -p "$DEST"

PRESERVE_TREE="${PRESERVE_TREE:-1}"
DRY_RUN="${DRY_RUN:-0}"

# Extensões alvo
# Nota: -iname apanha maiúsculas/minúsculas
FIND_EXPR=(
  -type f
  \( -iname "*.pdf" -o -iname "*.doc" -o -iname "*.docx" -o -iname "*.ppt" -o -iname "*.pptx" \)
)

MANIFEST="$DEST/manifest_$(date +%Y%m%d_%H%M%S).txt"

echo "[INFO] Origem:  $SRC"
echo "[INFO] Destino: $DEST"
echo "[INFO] Preservar árvore: $PRESERVE_TREE"
echo "[INFO] Dry-run: $DRY_RUN"
echo "[INFO] Manifest: $MANIFEST"
echo ""

# Função para copiar com nome único se já existir
unique_copy() {
  local src_file="$1"
  local out_file="$2"

  if [[ ! -e "$out_file" ]]; then
    cp -p "$src_file" "$out_file"
    return
  fi

  local dir base ext stem i candidate
  dir="$(dirname "$out_file")"
  base="$(basename "$out_file")"
  ext="${base##*.}"
  stem="${base%.*}"

  for i in $(seq 2 9999); do
    candidate="$dir/${stem}__${i}.${ext}"
    if [[ ! -e "$candidate" ]]; then
      cp -p "$src_file" "$candidate"
      return
    fi
  done

  echo "[ERRO] Colisões a mais para: $out_file" >&2
  return 1
}

# Percorrer ficheiros com separador NUL (seguro para espaços e caracteres estranhos)
COUNT=0
COPIED=0

# Opcional: se só quiseres uploads, troca "$SRC" por "$SRC/uploads"
# ROOT_SCAN="$SRC/uploads"
ROOT_SCAN="$SRC"

while IFS= read -r -d '' f; do
  COUNT=$((COUNT + 1))

  # caminho relativo
  rel="${f#$ROOT_SCAN/}"

  if [[ "$PRESERVE_TREE" == "1" ]]; then
    target_dir="$DEST/$(dirname "$rel")"
    mkdir -p "$target_dir"
    target_file="$target_dir/$(basename "$rel")"
  else
    target_file="$DEST/$(basename "$rel")"
  fi

  echo "$f" >> "$MANIFEST"

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[LISTA] $f"
  else
    unique_copy "$f" "$target_file"
    COPIED=$((COPIED + 1))
    echo "[OK] $(basename "$target_file")"
  fi
done < <(find "$ROOT_SCAN" "${FIND_EXPR[@]}" -print0)

echo ""
echo "=== RESUMO ==="
echo "Encontrados:   $COUNT"
echo "Copiados:     $COPIED"
echo "Manifest:     $MANIFEST"

