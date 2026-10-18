#!/usr/bin/env bash
# Build and run engine-independent C++ gameplay and topology tests.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/native/bin"
mkdir -p "$BUILD_DIR"

CXX_FLAGS=(
  -std=c++20
  -Wall
  -Wextra
  -Werror
  -pedantic
  -I "$ROOT/native/include"
)

g++ "${CXX_FLAGS[@]}" \
  "$ROOT/native/src/operation_core.cpp" \
  "$ROOT/native/tests/operation_core_test.cpp" \
  -o "$BUILD_DIR/operation_core_test"

g++ "${CXX_FLAGS[@]}" \
  "$ROOT/native/src/route_topology.cpp" \
  "$ROOT/native/tests/route_topology_test.cpp" \
  -o "$BUILD_DIR/route_topology_test"

"$BUILD_DIR/operation_core_test"
"$BUILD_DIR/route_topology_test"
