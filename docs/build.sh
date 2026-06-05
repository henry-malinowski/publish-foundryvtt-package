#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s <output-dir>\n' "$0" >&2
}

if [ "$#" -ne 1 ]; then
  usage
  exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/.." && pwd)
out_dir=$1

if [ -z "$out_dir" ]; then
  usage
  exit 2
fi

if [ -n "${ESBUILD:-}" ]; then
  esbuild=$ESBUILD
else
  esbuild_dir=$(mktemp -d)
  trap 'rm -rf "$esbuild_dir"' EXIT
  (
    cd "$esbuild_dir"
    curl -fsSL https://esbuild.github.io/dl/v0.25.9 | sh
  )
  esbuild=$esbuild_dir/esbuild
fi

"$esbuild" --version

rm -rf "$out_dir"
mkdir -p \
  "$out_dir/css" \
  "$out_dir/js" \
  "$out_dir/vendor/highlight" \
  "$out_dir/vendor/anime"

cp "$repo_dir/docs/index.html" "$out_dir/index.html"
cp -R "$repo_dir/docs/assets" "$out_dir/assets"
cp "$repo_dir/docs/vendor/highlight/LICENSE" "$out_dir/vendor/highlight/LICENSE"
cp "$repo_dir/docs/vendor/anime/LICENSE" "$out_dir/vendor/anime/LICENSE"

"$esbuild" "$repo_dir/docs/css/style.css" \
  --bundle \
  --minify \
  --outfile="$out_dir/css/style.css"

"$esbuild" "$repo_dir/docs/js/docs.js" \
  --bundle \
  --minify \
  --format=esm \
  --outfile="$out_dir/js/docs.js"
