#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
miso_init="${MISO_INIT:-$repo_root/bin/miso-init}"
miso_ref="${SMOKE_MISO_REF:-}"
miso_version="${SMOKE_MISO_VERSION:-}"
smoke_keep="${SMOKE_KEEP:-0}"

if [ -n "$miso_ref" ] && [ -n "$miso_version" ]; then
  echo "error: set only one of SMOKE_MISO_REF or SMOKE_MISO_VERSION." >&2
  exit 1
fi

command -v wasm32-wasi-cabal >/dev/null 2>&1 || {
  echo "error: wasm32-wasi-cabal was not found. Run 'source ~/.ghc-wasm/env' first." >&2
  exit 1
}
command -v wasm32-wasi-ghc >/dev/null 2>&1 || {
  echo "error: wasm32-wasi-ghc was not found. Run 'source ~/.ghc-wasm/env' first." >&2
  exit 1
}

cleanup_smoke_root=1
if [ -n "${SMOKE_ROOT:-}" ]; then
  smoke_root="$SMOKE_ROOT"
  cleanup_smoke_root=0
  mkdir -p "$smoke_root"
else
  smoke_root="$(mktemp -d "${TMPDIR:-/tmp}/miso-init.smoke.XXXXXX")"
fi

if [ "$smoke_keep" = "1" ]; then
  cleanup_smoke_root=0
fi

cleanup() {
  if [ "$cleanup_smoke_root" -eq 1 ]; then
    rm -rf "$smoke_root"
  fi
}
trap cleanup EXIT INT TERM

project_dir="$smoke_root/hello-miso"
if [ -e "$project_dir" ]; then
  echo "error: smoke project already exists: $project_dir" >&2
  exit 1
fi

miso_args=()
if [ -n "$miso_ref" ]; then
  miso_args=(--miso-ref "$miso_ref")
elif [ -n "$miso_version" ]; then
  miso_args=(--miso-version "$miso_version")
fi

echo "Generating smoke project: $project_dir"
"$miso_init" "${miso_args[@]}" "$project_dir"

echo "Building generated project..."
"$project_dir/bin/build-web.sh"

for path in \
  "$project_dir/public/index.html" \
  "$project_dir/public/index.js" \
  "$project_dir/public/ghc_wasm_jsffi.js" \
  "$project_dir/public/app.wasm" \
  "$project_dir/public/.miso-init-generated"
do
  if [ ! -f "$path" ]; then
    echo "error: expected smoke output file to exist: $path" >&2
    exit 1
  fi
done

echo "Smoke build passed."
if [ "$cleanup_smoke_root" -eq 0 ]; then
  echo "Smoke project kept at: $project_dir"
fi
