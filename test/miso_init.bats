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
  assert_output_contains "error: existing non-empty paths found"
  assert_output_contains "$target/app"
  assert_path_missing "$target/existing-app.cabal"
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
