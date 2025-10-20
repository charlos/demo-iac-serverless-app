#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAMBDA_SRC_DIR="$BASE_DIR/../lambda-src"
LAMBDA_PACKAGE_DIR="$BASE_DIR/../lambda-package"

echo "- Empaquetando Lambdas desde $LAMBDA_SRC_DIR"

for dir in "$LAMBDA_SRC_DIR"/*/; do
  name=$(basename "$dir")
  zip_path="$LAMBDA_PACKAGE_DIR/${name}.zip"
  echo "→ Empaquetando $name -> $zip_path"
  (cd "$dir" && zip -r9 "$zip_path" . >/dev/null)
done

echo "- Todas las Lambdas empaquetadas correctamente"
