#!/usr/bin/env sh
# This file is deliberately invoked as one command by android-emulator-runner.
# The action parses each line of its `script` input independently, so shell
# control flow must live in this POSIX script rather than in a YAML block.
set -eu

mkdir -p build
exec > build/android-emulator-probe.log 2>&1
set -x

adb wait-for-device
adb shell getprop sys.boot_completed | tr -d '\r' | grep -qx '1'
adb logcat -c
adb install -r build/OperationRedline-debug.apk | tee build/android-emulator-install.log
adb shell pm path com.operationredline.outpost | grep -q '^package:'
adb shell monkey -p com.operationredline.outpost 1

foreground=false
attempt=1
while [ "$attempt" -le 30 ]; do
  if adb shell dumpsys activity activities | grep -q 'mResumedActivity.*com.operationredline.outpost'; then
    foreground=true
    break
  fi
  sleep 1
  attempt=$((attempt + 1))
done

adb logcat -d -t 1200 > build/android-emulator.log
if grep -E 'FATAL EXCEPTION|AndroidRuntime.*Process.*com\.operationredline\.outpost' build/android-emulator.log; then
  echo "Android runtime crash found in logcat."
  exit 1
fi

if [ "$foreground" != true ]; then
  echo "Operation Redline did not reach a resumed Android activity."
  exit 1
fi
