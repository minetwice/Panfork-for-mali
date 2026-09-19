#!/usr/bin/env bash
set -euo pipefail

if [ -z "${ANDROID_NDK_ROOT:-}" ]; then
  echo "ANDROID_NDK_ROOT is not set"
  exit 1
fi

command -v ccache >/dev/null 2>&1 || sudo apt-get install -y ccache || true

envsubst < android-drm-aarch64 > build-crossfile-drm
if [ ! -d drm/.git ]; then
  git clone --depth 1 https://gitlab.freedesktop.org/mesa/drm.git
fi
cd drm
rm -rf build-android
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

envsubst < android-aarch64 > build-crossfile
rm -rf build-android

# swrast only: panfrost needs full pan_base (missing in this tree).
# OSMesa + softpipe is enough for FearLauncher libOSMesa_8.so.
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
echo "=== installed shared libs ==="
find /tmp/pan -name '*.so*' | sort
