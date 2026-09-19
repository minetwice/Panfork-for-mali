#!/usr/bin/env bash
set -euo pipefail

if [ -z "${ANDROID_NDK_ROOT:-}" ]; then
  echo "ANDROID_NDK_ROOT is not set"
  exit 1
fi

envsubst < android-drm-aarch64 > build-crossfile-drm
git clone --depth 1 https://gitlab.freedesktop.org/mesa/drm.git
cd drm
meson setup build-android \
  --prefix=/tmp/drm-static \
  --cross-file ../build-crossfile-drm \
  -Ddefault_library=static \
  -Dintel=disabled -Dradeon=disabled -Damdgpu=disabled \
  -Dnouveau=disabled -Dvmwgfx=disabled -Dfreedreno=disabled \
  -Dvc4=disabled -Detnaviv=disabled
ninja -C build-android install
cd ..

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
  -Dgallium-drivers=swrast,panfrost \
  -Dshared-glapi=false \
  -Dbuildtype=release
ninja -C build-android install
find /tmp/pan -name '*.so*' | sort
