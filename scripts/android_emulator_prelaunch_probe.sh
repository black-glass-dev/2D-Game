#!/usr/bin/env sh
# This runs after the runner creates the AVD and immediately before it launches.
# It records the boundary without asserting that the emulator has booted.
set -eu

workspace=${GITHUB_WORKSPACE:?GITHUB_WORKSPACE must be set}
build_dir="$workspace/build"
mkdir -p "$build_dir"

{
  echo "ANDROID_EMULATOR_PRELAUNCH_REACHED"
  printf 'pwd=%s\n' "$(pwd)"
  printf 'android_home=%s\n' "${ANDROID_HOME:-unset}"
  printf 'android_avd_home=%s\n' "${ANDROID_AVD_HOME:-unset}"
  printf 'emulator_port=%s\n' "${EMULATOR_PORT:-unset}"
  "$ANDROID_HOME/emulator/emulator" -version
  find "${ANDROID_AVD_HOME:-/nonexistent}" -maxdepth 2 -type f -name config.ini -print | sort
} > "$build_dir/android-emulator-prelaunch.log" 2>&1
