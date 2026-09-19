# FearLauncher + Panfork (Mali block/texture glitch fix)

This fork is **Mesa 24.0.6** with Panfrost (kbase) + **OSMesa** for Android.
Target: fix Mali GPU **world/block texture glitches** in Minecraft Java (FearLauncher),
while keeping the existing stable OSMesa path (no crash).

## What we changed

1. **AFBC disabled by default on Android** (`src/gallium/drivers/panfrost/pan_screen.c`)
   - AFBC compressed textures frequently corrupt block/chunk textures on Mali
     (G52 / G57 / G610 / G615) when used through kbase + OSMesa.
   - UI / sky often look fine; blocks glitch — classic AFBC symptom.
   - Override later with `PAN_MESA_DEBUG=` (empty) only if you need AFBC again.

2. **CI packages `libOSMesa_8.so`** for FearLauncher  
   Actions → **Build Android OSMesa (FearLauncher)** → download zip.

## Build (GitHub Actions)

1. Open: https://github.com/minetwice/Panfork-for-mali/actions
2. Run workflow **Build Android OSMesa (FearLauncher)** on branch `24.0`
3. Download artifact `fear-launcher-panfork-osmesa-aarch64`
4. Inside zip: `arm64-v8a/libOSMesa_8.so`

## Install into FearLauncher

Copy into native libs (same place current `libOSMesa_8.so` lives), e.g.:

```text
app_pojavlauncher/src/main/jniLibs/arm64-v8a/libOSMesa_8.so
```

or your packaged `lib/arm64` path used by `POJAV_NATIVEDIR`.

### Recommended env (launcher already sets most of these)

```text
LIB_MESA_NAME=libOSMesa_8.so
GALLIUM_DRIVER=panfrost
PAN_MESA_DEBUG=noafbc
MESA_GL_VERSION_OVERRIDE=4.6
MESA_GLSL_VERSION_OVERRIDE=460
```

If Panfrost cannot open the GPU (no kbase access), OSMesa still falls back to
**softpipe/swrast** — game should run, just slower.

## Extra debug flags (if glitches remain)

```text
PAN_MESA_DEBUG=noafbc,linear,nofp16
```

- `linear` — force linear textures (more VRAM, fewer tiling bugs)
- `nofp16` — avoid broken fp16 paths on some Mali revisions

## Scope

- Goal: **texture/block correctness** on Mali, not max FPS.
- Not GLES / gl4es — desktop GL via OSMesa + Panfrost/softpipe.
- Device under test historically: Motorola Edge 60 Fusion (Mali-G615 MC2).

## Upstream

Based on [Lunarixus/panfork_offscreen_rootless](https://github.com/Lunarixus/panfork_offscreen_rootless)
(Mesa 24.0 Panfrost Android rootless / OSMesa).
