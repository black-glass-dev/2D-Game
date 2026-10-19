#!/usr/bin/env sh
# Collect factual Android-install and launch evidence for later reviewer entry in
# physical_qa_evidence.template.json. This helper never assigns D01-D12 results
# and never labels a device as tested.
set -eu

PACKAGE_ID="com.operationredline.outpost"

usage() {
  cat <<'USAGE'
Usage:
  docs/capture_physical_android_qa.sh --apk <debug.apk> --output <empty-directory> [--serial <adb-serial>]

Collects device identity, APK SHA-256, adb install -r output, package lookup,
launch output, resumed-activity state, and bounded logcat output. It exits
non-zero if installation or package lookup fails. The generated files are
factual collection material only: a reviewer must still complete every D01-D12
row and validate the completed JSON record separately.
USAGE
}

fail() {
  printf '%s\n' "PHYSICAL_QA_CAPTURE_ERROR: $*" >&2
  exit 2
}

apk=""
output=""
serial=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --apk)
      [ "$#" -ge 2 ] || fail "--apk requires a path"
      apk=$2
      shift 2
      ;;
    --output)
      [ "$#" -ge 2 ] || fail "--output requires a path"
      output=$2
      shift 2
      ;;
    --serial)
      [ "$#" -ge 2 ] || fail "--serial requires an adb serial"
      serial=$2
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[ -n "$apk" ] || fail "--apk is required"
[ -n "$output" ] || fail "--output is required"
[ -f "$apk" ] || fail "APK does not exist: $apk"
[ ! -e "$output" ] || fail "output path must not already exist: $output"
command -v adb >/dev/null 2>&1 || fail "adb is not available on PATH"
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is not available on PATH"

mkdir -p "$output"

adb_target() {
  if [ -n "$serial" ]; then
    adb -s "$serial" "$@"
  else
    adb "$@"
  fi
}

capture() {
  name=$1
  shift
  "$@" > "$output/$name" 2>&1
}

printf 'captured_at=%s\n' "$(date -Iseconds)" > "$output/capture-manifest.txt"
printf 'package_id=%s\n' "$PACKAGE_ID" >> "$output/capture-manifest.txt"
printf 'apk=%s\n' "$apk" >> "$output/capture-manifest.txt"
printf 'requested_serial=%s\n' "${serial:-auto}" >> "$output/capture-manifest.txt"
sha256sum "$apk" > "$output/apk.sha256"

capture adb-devices.txt adb devices -l
capture adb-state.txt adb_target get-state
capture adb-serial.txt adb_target get-serialno
capture device-properties.txt adb_target shell sh -c '
  getprop ro.product.manufacturer
  getprop ro.product.model
  getprop ro.product.device
  getprop ro.build.version.release
  getprop ro.build.fingerprint
  wm size || true
  settings get system peak_refresh_rate || true
  getevent -lp || true
'

capture clear-logcat.txt adb_target logcat -c
set +e
adb_target install -r "$apk" > "$output/install-output.txt" 2>&1
install_code=$?
set -e
printf 'adb_install_exit=%s\n' "$install_code" >> "$output/capture-manifest.txt"
if [ "$install_code" -ne 0 ]; then
  printf '%s\n' "PHYSICAL_QA_CAPTURE_BLOCKED: adb install -r failed; inspect $output/install-output.txt" >&2
  exit "$install_code"
fi

capture package-path.txt adb_target shell pm path "$PACKAGE_ID"
if ! grep -q '^package:' "$output/package-path.txt"; then
  printf '%s\n' "PHYSICAL_QA_CAPTURE_BLOCKED: package lookup failed; inspect $output/package-path.txt" >&2
  exit 1
fi

capture launch-output.txt adb_target shell monkey -p "$PACKAGE_ID" 1
sleep 5
capture resumed-activity.txt adb_target shell dumpsys activity activities
capture logcat.txt adb_target logcat -d -t 1200
if grep -E 'FATAL EXCEPTION|AndroidRuntime.*Process.*com\.operationredline\.outpost' "$output/logcat.txt" > "$output/crash-scan.txt"; then
  printf 'crash_scan=matches_found\n' >> "$output/capture-manifest.txt"
else
  printf 'crash_scan=no_matches_in_bounded_log\n' >> "$output/capture-manifest.txt"
fi

printf '%s\n' "PHYSICAL_QA_CAPTURE_COLLECTED: reviewer completion is still required before any D01-D12 or device-tested claim."
