# AOSP baseline: android-16.0.0_r4

本目录存放针对该 AOSP 版本基线的补丁与工具。换 baseline 请新建同级目录、更新下面记录并重新验证。

## 版本基线（记录于 2026-09-06）

- manifest 默认 revision：`refs/tags/android-16.0.0_r4`
- 编译产物：build id `BP4A.251205.006` / incremental `eng.uu26wy` / flavor `mainline-userdebug`
- host：Ubuntu VM（Fedora Boxes / QEMU），内核 `7.0.0-31-generic`，KVM 可用
- cuttlefish（deb 管理层）：`1.57.0`（VCS `0e00d696`）→ `cvd` / `cvd_server` / `cvd_internal_*`
- `device/google/cuttlefish_vmm` @ `154651c`（2025-07-24, 25Q4-release）
- `external/crosvm` @ `738b7016f`（2025-09-25, 25Q4-release）
- AOSP 检出：`/home/uu26wyou/projects/aosp`

## 改动 1：放宽 crosvm seccomp 的 madvise（本机启动必需）

- 症状：`cvd create` → `VIRTUAL_DEVICE_BOOT_FAILED`；`launcher.log` 见
  `failed to create proxy device: … Connection reset by peer`；内核 audit
  `type=1326 … comm="pcivirtio-gpu" sig=31 syscall=28`（x86_64 的 28 = **madvise**）
- 根因：crosvm 沙箱子进程的 seccomp 白名单只允许 madvise 的 5 种 advice，
  新 glibc / GPU 路径用到别的 advice → SIGSYS 秒杀。与命名空间 / AppArmor 无关。
- 涉及（x86_64）：`device/google/cuttlefish_vmm/x86_64-linux-gnu/etc/seccomp/`
  的 `gpu_device.policy`、`gpu_render_server.policy`、`video_device.policy`、`wl_device.policy`
  （第 31/34 行附近 `madvise: arg2 == …` → `madvise: 1`）。

### 推荐用法（运行时，改 out/ 产物，免重编译）

每次 `m` / `installclean` 之后、`cvd create` 之前：

```bash
~/projects/aosp-patches/android-16.0.0_r4/fix-crosvm-seccomp.sh
```

幂等；`AOSP` 检出不在 `$HOME/projects/aosp` 时可 `AOSP=/path` 覆盖。

### 可选：改源码彻底固化（“第 1 步”，本机暂未做）

```bash
cd /home/uu26wyou/projects/aosp/device/google/cuttlefish_vmm
git apply ~/projects/aosp-patches/android-16.0.0_r4/patches/0001-crosvm-seccomp-allow-all-madvise.patch
# 之后 m cvd-host_package 重建; repo sync 会还原, 需重打
```

## 目录

- `fix-crosvm-seccomp.sh` — 运行时补丁脚本（改 `out/` 产物）
- `patches/0001-crosvm-seccomp-allow-all-madvise.patch` — 源码级 diff（可选固化）
- `README.md` — 版本基线 + 改动说明（本文件）
