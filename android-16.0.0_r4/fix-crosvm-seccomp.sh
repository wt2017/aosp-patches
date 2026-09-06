#!/usr/bin/env bash
# fix-crosvm-seccomp.sh
#
# Relax the madvise rule in crosvm's RUNTIME seccomp policies.
# Run AFTER every `m` / `installclean`, BEFORE `cvd create`.
#
# Why:
#   crosvm device subprocesses load seccomp allowlists from
#     out/host/linux-x86/usr/share/crosvm/x86_64-linux-gnu/seccomp/*.policy
#   at startup. Those policies allow madvise for only 5 advice values. Newer
#   kernel/glibc + GPU code paths call madvise with other advice values, so the
#   device subprocess is killed by SIGSYS (31), and the parent crosvm only sees
#   "proxy device: Connection reset by peer" -> VIRTUAL_DEVICE_BOOT_FAILED.
#
# Note:
#   This edits BUILD OUTPUT (out/), not source. `m` regenerates it, so re-run
#   this script after every build. For a durable source-level fix, apply
#   patches/0001-crosvm-seccomp-allow-all-madvise.patch (see README.md).
set -euo pipefail

AOSP="${AOSP:-$HOME/projects/aosp}"
S="$AOSP/out/host/linux-x86/usr/share/crosvm/x86_64-linux-gnu/seccomp"
files=(gpu_device gpu_render_server video_device wl_device)

for f in "${files[@]}"; do
  p="$S/$f.policy"
  if [ ! -f "$p" ]; then
    echo "skip (not found): $p"
    continue
  fi
  sed -i 's/^madvise: arg2 ==.*/madvise: 1/' "$p"
done

echo "madvise relaxed (each line should read 'madvise: 1'):"
for f in "${files[@]}"; do
  grep -H '^madvise' "$S/$f.policy"
done
