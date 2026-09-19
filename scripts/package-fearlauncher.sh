#!/usr/bin/env bash
set -euo pipefail

mkdir -p out/arm64-v8a
find /tmp/pan -name 'libOSMesa*.so*' -exec cp -v {} out/arm64-v8a/ \;
find /tmp/pan -name 'libgallium*.so*' -exec cp -v {} out/arm64-v8a/ \; 2>/dev/null || true

cd out/arm64-v8a
if [ -f libOSMesa.so.8 ]; then
  cp -v libOSMesa.so.8 libOSMesa_8.so
elif [ -f libOSMesa.so ]; then
  cp -v libOSMesa.so libOSMesa_8.so
fi
ls -la
cd ../..

cat > out/README.txt << 'EOF'
FearLauncher Mali Panfork package
Copy libOSMesa_8.so into launcher jniLibs/arm64-v8a
Env: LIB_MESA_NAME=libOSMesa_8.so GALLIUM_DRIVER=panfrost PAN_MESA_DEBUG=noafbc
EOF

(cd out && zip -r fear-launcher-panfork-osmesa-arm64.zip arm64-v8a README.txt)
ls -la out/
