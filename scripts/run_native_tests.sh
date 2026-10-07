#!/usr/bin/env bash
# Build and run the engine-independent C++ gameplay tests.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/native/bin"
mkdir -p "$BUILD_DIR"

g++ -std=c++20 -Wall -Wextra -Werror -pedantic \
  -I "$ROOT/native/include" \
  "$ROOT/native/src/operation_core.cpp" \
  "$ROOT/native/tests/operation_core_test.cpp" \
  -o "$BUILD_DIR/operation_core_test"

"$BUILD_DIR/operation_core_test"
