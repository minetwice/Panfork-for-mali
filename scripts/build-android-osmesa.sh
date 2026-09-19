#!/usr/bin/env bash
set -euo pipefail

if [ -z "${ANDROID_NDK_ROOT:-}" ]; then
  echo "ANDROID_NDK_ROOT is not set"
  exit 1
fi

command -v ccache >/dev/null 2>&1 || sudo apt-get install -y ccache || true

envsubst < android-drm-aarch64 > build-crossfile-drm
git clone --depth 1 https://gitlab.freedesktop.org/mesa/drm.git
cd drm
meson setup build-android \
  --prefix=/tmp/drm-static \
  --cross-file ../build-crossfile-drm \
  -Ddefault_library=static \
  -Dintel=disabled \
  -Dradeon=disabled \
  -Damdgpu=disabled \
  -Dnouveau=disabled \
  -Dvmwgfx=disabled \
  -Dvc4=disabled \
  -Detnaviv=disabled \
  -Domap=disabled \
  -Dexynos=disabled \
  -Dtegra=disabled \
  -Dcairo-tests=disabled \
  -Dman-pages=disabled \
  -Dtests=false
ninja -C build-android install
cd ..

# NOTE: This Lunarixus/24.0 tree has struct kbase_ in pan_device.h but is
# missing src/panfrost/base/ (pan_base) from the Pojav CSF panfork.
# Building panfrost therefore fails with incomplete type 'struct kbase_'.
# Ship OSMesa + softpipe (swrast) first so FearLauncher gets libOSMesa_8.so.
# Panfrost/kbase can be restored later by porting src/panfrost/base from
# https://github.com/PojavLauncherTeam/panfork_offscreen_rootless (csf branch).

envsubst < android-aarch64 > build-crossfile
meson setup build-android \
  --prefix=/tmp/pan \
  --cross-file build-crossfile \
  -Dplatforms=android \
  -Dplatform-sdk-version=26 \
  -Dandroid-stub=true \
  -Dllvm=disabled \
  -Dxlib-lease=disabled \
  -Degl=disabled \
  -Dgbm=disabled \
  -Dglx=disabled \
  -Dopengl=true \
  -Dosmesa=true \
  -Dvulkan-drivers= \
  -Dgallium-drivers=swrast \
  -Dshared-glapi=false \
  -Dbuildtype=release
ninja -C build-android install
find /tmp/pan -name '*.so*' | sort
