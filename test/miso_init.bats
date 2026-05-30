#!/usr/bin/env bats

load 'test_helper/helper'

setup() {
  miso_init_test_setup
}

teardown() {
  miso_init_test_teardown
}

@test "miso-init has valid bash syntax" {
  run bash -n "$MISO_INIT"

  assert_success
}

@test "--help prints usage and does not create files" {
  run "$MISO_INIT" --help

  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "miso-init [OPTIONS] [DIR]"
  assert_output_contains "--miso-ref REF"
  assert_output_contains "--miso-version VERSION"
}

@test "unknown option fails with a helpful message" {
  run "$MISO_INIT" --unknown

  assert_failure
  assert_output_contains "error: unknown option: --unknown"
  assert_output_contains "Usage:"
}

@test "too many positional arguments fail" {
  run "$MISO_INIT" one two

  assert_failure
  assert_output_contains "error: too many arguments"
  assert_output_contains "Usage:"
}

@test "creates a project in the requested directory" {
  local target="$TEST_ROOT/hello-miso"

  run "$MISO_INIT" "$target"

  assert_success
  assert_output_contains "Created project in $target"
  assert_output_contains "Package name: hello-miso"
  assert_basic_project "$target" "hello-miso"
}

@test "creates a project in the current directory when DIR is omitted" {
  local target="$TEST_ROOT/current-app"
  mkdir -p "$target"
  cd "$target"

  run "$MISO_INIT"

  assert_success
  assert_output_contains "Created project in ."
  assert_output_contains "Package name: current-app"
  assert_basic_project "$target" "current-app"
}

@test "--miso-ref sets the generated miso git reference" {
  local target="$TEST_ROOT/hello-miso"
  local ref="2853fb4f26175f51ae7b9aaf0ec683c45070d06e"

  run "$MISO_INIT" --miso-ref "$ref" "$target"

  assert_success
  assert_output_contains "Miso ref: $ref"
  assert_file_contains "$target/cabal.project" "tag: $ref"
  assert_file_contains "$target/hello-miso.cabal" "miso >= 1.9"
}

@test "--miso-version pins the generated release tag and dependency version" {
  local target="$TEST_ROOT/hello-miso"

  run "$MISO_INIT" --miso-version=1.11.0 "$target"

  assert_success
  assert_output_contains "Miso ref: 1.11.0"
  assert_file_contains "$target/cabal.project" "tag: 1.11.0"
  assert_file_contains "$target/hello-miso.cabal" "miso == 1.11.0"
}

@test "miso reference options reject invalid input" {
  local target="$TEST_ROOT/hello-miso"

  run "$MISO_INIT" --miso-ref

  assert_failure
  assert_output_contains "error: --miso-ref requires a value"

  run "$MISO_INIT" --miso-version v1.11.0 "$target"

  assert_failure
  assert_output_contains "error: --miso-version must look like 1.11.0"

  run "$MISO_INIT" --miso-ref master --miso-version 1.11.0 "$target"

  assert_failure
  assert_output_contains "error: --miso-ref and --miso-version cannot be used together"
}

@test "normalizes directory names into valid cabal package names" {
  local target="$TEST_ROOT/Hello_Miso++2026"

  run "$MISO_INIT" "$target"

  assert_success
  assert_output_contains "Package name: hello-miso-2026"
  assert_basic_project "$target" "hello-miso-2026"
}

@test "treats a trailing slash as the same target directory" {
  local target="$TEST_ROOT/hello-miso"

  run "$MISO_INIT" "$target/"

  assert_success
  assert_output_contains "Package name: hello-miso"
  assert_basic_project "$target" "hello-miso"
}

@test "-- allows a directory name that starts with a dash" {
  local target="$TEST_ROOT/-dash-app"

  run "$MISO_INIT" -- "$target"

  assert_success
  assert_output_contains "Package name: dash-app"
  assert_basic_project "$target" "dash-app"
}

@test "existing generated paths fail without --force" {
  local target="$TEST_ROOT/existing-app"
  mkdir -p "$target/app"
  printf 'keep\n' > "$target/app/existing.txt"

  run "$MISO_INIT" "$target"

  assert_failure
  assert_output_contains "error: generated paths already exist"
  assert_output_contains "$target/app"
  assert_path_missing "$target/existing-app.cabal"
}

@test "existing cabal files with different names fail without --force" {
  local target="$TEST_ROOT/existing-app"
  mkdir -p "$target"
  printf 'name: other-app\n' > "$target/other-app.cabal"

  run "$MISO_INIT" "$target"

  assert_failure
  assert_output_contains "error: generated paths already exist"
  assert_output_contains "$target/other-app.cabal"
  assert_path_missing "$target/existing-app.cabal"
}

@test "existing unrelated files do not require --force" {
  local target="$TEST_ROOT/existing-app"
  mkdir -p "$target"
  printf '# Existing docs\n' > "$target/README.md"

  run "$MISO_INIT" "$target"

  assert_success
  assert_basic_project "$target" "existing-app"
  assert_file_contains "$target/README.md" "# Existing docs"
}

@test "--force allows existing generated paths" {
  local target="$TEST_ROOT/existing-app"
  mkdir -p "$target/app"
  printf 'keep\n' > "$target/app/existing.txt"

  run "$MISO_INIT" --force "$target"

  assert_success
  assert_output_contains "Package name: existing-app"
  assert_basic_project "$target" "existing-app"
  assert_file_exists "$target/app/existing.txt"
}

@test "empty generated directories do not count as conflicts" {
  local target="$TEST_ROOT/empty-dirs"
  mkdir -p "$target/app" "$target/static"

  run "$MISO_INIT" "$target"

  assert_success
  assert_basic_project "$target" "empty-dirs"
}

@test "generated build script explains missing ghc-wasm tools" {
  local target="$TEST_ROOT/hello-miso"
  run "$MISO_INIT" "$target"
  assert_success

  run env PATH="/usr/bin:/bin" "$target/bin/build-web.sh"

  assert_status 1
  assert_output_contains "wasm32-wasi-cabal"
  assert_output_contains "source ~/.ghc-wasm/env"
}

@test "generated build script can be run from outside the project root" {
  local target="$TEST_ROOT/hello-miso"
  local tools="$TEST_ROOT/tools"
  local other="$TEST_ROOT/elsewhere"

  run "$MISO_INIT" "$target"
  assert_success

  mkdir -p "$tools/lib" "$other"

  cat > "$tools/wasm32-wasi-cabal" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  build)
    test -f cabal.project
    test -d static
    mkdir -p dist-newstyle/bin
    printf '%s\n' wasm > dist-newstyle/bin/app.wasm
    ;;
  list-bin)
    test "${2:-}" = "exe:app"
    printf '%s\n' "$PWD/dist-newstyle/bin/app.wasm"
    ;;
  *)
    echo "unexpected wasm32-wasi-cabal args: $*" >&2
    exit 1
    ;;
esac
SH

  cat > "$tools/wasm32-wasi-ghc" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

tool_dir="$(cd "$(dirname "$0")" && pwd)"

if [ "${1:-}" = "--print-libdir" ]; then
  printf '%s\n' "$tool_dir/lib"
else
  echo "unexpected wasm32-wasi-ghc args: $*" >&2
  exit 1
fi
SH

  cat > "$tools/lib/post-link.mjs" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

input=""
output=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --input)
      input="$2"
      shift 2
      ;;
    --output)
      output="$2"
      shift 2
      ;;
    *)
      echo "unexpected post-link args: $*" >&2
      exit 1
      ;;
  esac
done

test -f "$input"
printf '%s\n' jsffi > "$output"
SH

  chmod +x "$tools/wasm32-wasi-cabal" "$tools/wasm32-wasi-ghc" "$tools/lib/post-link.mjs"

  cd "$other"
  run env PATH="$tools:/usr/bin:/bin" "$target/bin/build-web.sh"

  assert_success
  assert_file_exists "$target/public/index.html"
  assert_file_exists "$target/public/index.js"
  assert_file_exists "$target/public/ghc_wasm_jsffi.js"
  assert_file_exists "$target/public/app.wasm"
  assert_file_exists "$target/public/.miso-init-generated"
  assert_file_contains "$target/public/.miso-init-generated" "Generated by miso-init."
  assert_path_missing "$other/public"
}

@test "generated build script refuses to delete an unmarked public directory" {
  local target="$TEST_ROOT/hello-miso"
  local tools="$TEST_ROOT/tools"

  run "$MISO_INIT" "$target"
  assert_success

  mkdir -p "$target/public" "$tools"
  printf '%s\n' keep > "$target/public/user-file.txt"

  cat > "$tools/wasm32-wasi-cabal" <<'SH'
#!/usr/bin/env bash
exit 0
SH

  cat > "$tools/wasm32-wasi-ghc" <<'SH'
#!/usr/bin/env bash
exit 0
SH

  chmod +x "$tools/wasm32-wasi-cabal" "$tools/wasm32-wasi-ghc"

  run env PATH="$tools:/usr/bin:/bin" "$target/bin/build-web.sh"

  assert_status 1
  assert_output_contains "public/ exists but was not generated by miso-init"
  assert_output_contains "static/"
  assert_file_contains "$target/public/user-file.txt" "keep"
}

@test "generated serve script serves from the project root" {
  local target="$TEST_ROOT/hello-miso"
  local tools="$TEST_ROOT/tools"
  local other="$TEST_ROOT/elsewhere"
  local log="$TEST_ROOT/serve.log"
  local expected_root

  run "$MISO_INIT" "$target"
  assert_success

  mkdir -p "$tools" "$other"
  expected_root="$(cd "$target" && pwd)"

  cat > "$tools/python3" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$PWD" > "$SERVE_LOG"
printf '%s\n' "$*" >> "$SERVE_LOG"
SH

  chmod +x "$tools/python3"

  cd "$other"
  run env PATH="$tools:/usr/bin:/bin" SERVE_LOG="$log" "$target/bin/serve.sh"

  assert_success
  assert_file_contains "$log" "$expected_root"
  assert_file_contains "$log" "-m http.server 8000 -d public"
}

@test "generated serve script accepts PORT and --port" {
  local target="$TEST_ROOT/hello-miso"
  local tools="$TEST_ROOT/tools"
  local log="$TEST_ROOT/serve.log"

  run "$MISO_INIT" "$target"
  assert_success

  mkdir -p "$tools"

  cat > "$tools/python3" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" > "$SERVE_LOG"
SH

  chmod +x "$tools/python3"

  run env PATH="$tools:/usr/bin:/bin" PORT=8080 SERVE_LOG="$log" "$target/bin/serve.sh"

  assert_success
  assert_file_contains "$log" "-m http.server 8080 -d public"

  run env PATH="$tools:/usr/bin:/bin" PORT=8080 SERVE_LOG="$log" "$target/bin/serve.sh" --port 9090

  assert_success
  assert_file_contains "$log" "-m http.server 9090 -d public"
}
