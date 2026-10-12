# WoW Forever on Adreno 840 (GameNative)

Tested 26 September 2026 on a Nubia RedMagic 11 Pro (Adreno 840) with GameNative 1.2.1. Reached the world (Ironforge) using the RP6 Proton/DXVK stack plus a locally rebuilt Turnip, then updated the client from Battle.net in that same container.

This is not the stock RP6 Turnip ZIP. That package is scoped to Adreno 740. On the 840 it compiles shaders but draws stripe garbage and stalls.

## Launch scripts

Both scripts belong on the **WoW Forever Beta** GameNative card, in one container. GameNative hides the console, so a `choice` menu hangs on "Launching game…". Switch the card's executable instead:

| Script | Starts |
|---|---|
| `scripts/Launch-WoW-Direct.bat` | `WowB-ARM64.exe -d3d11` |
| `scripts/Launch-BattleNet.bat` | `Battle.net Launcher.exe` |

Leave the separate Battle.net library card unused. That other prefix is what produced Battle.net error **BLZEBNTAGT0000084B** (folder access / not administrator).

The game install is **`C:\Program Files (x86)\World of Warcraft`** inside the Forever container, not on `G:`. Agent will not update a `G:` copy or a junction onto sdcard. `G:\Battle.net` is only the launcher. `G:` is `/storage/emulated/0/GameNative`.

## Launching from Battle.net

Pressing **Play** in Battle.net starts `WowB-ARM64.exe` in this container. Most GameNative writeups skip the launcher and start that exe directly, because Play usually dies. It works here for three reasons:

- The launcher and the game share **one** container. A second Battle.net card cannot see the install (`BLZEBNTAGT0000084B`).
- The client lives at **`C:\Program Files (x86)\World of Warcraft`**, where Agent is allowed to update it and `CreateProcess` it. A `Data/` copy on `G:` is not an install Agent will launch.
- Wine is **ARM64EC**. Battle.net is x86, so FEXCore runs it. Play then starts the native ARM64 client, and that client gets the container's aarch64 DXVK and Turnip driver. Stock Proton's DXVK libraries are the wrong machine type for a pure ARM64 exe, which is the "game initialization failed" / bad `dxgi.dll` path.

`Launch-WoW-Direct.bat` is still the shorter boot. `Launch-BattleNet.bat` is how the client gets updated, and how Play was confirmed.

On this prefix Battle.net sees ARM64 Windows, so it installs the native ARM64 client when Blizzard ships one (`WowB-ARM64.exe` for Forever, `Wow-ARM64.exe` / `WowClassic-arm64.exe` for the other products). Forever is the client that reached the world. The x64 clients stop in the loader under FEX.

GameNative holds the screen, so an authenticator app on the phone cannot be opened during login. This account had the authenticator removed before the in-container login succeeded.

## GameNative settings

GameNative **1.2.1**. One library card, **WoW Forever Beta**. These are the settings that were on the container when Ironforge loaded and when Battle.net's Play button started the game.

| Tab | Setting | Value |
|---|---|---|
| General | Container variant | bionic |
| General | Wine version | `proton-11.0-90624-arm64ec-1` |
| General | Executable | `Launch-WoW-Direct.bat` or `Launch-BattleNet.bat` |
| General | Screen size | **1344×608** (Custom). Half of the RedMagic 11 Pro panel (2688×1216). **1280×720** also worked. **1920×1080** brings the pipeline assert back. |
| Drives | `G:` | `/storage/emulated/0/GameNative` |
| Graphics | Graphics driver | Wrapper |
| Graphics | Graphics driver version | **Turnip-V32-RP6sched** |
| Graphics | Use Adrenotools Turnip | on |
| Graphics | Display renderer | Vulkan |
| Graphics | DX wrapper | DXVK |
| Graphics | DXVK version | `2.4.1-wow-aarch64-test-1` |
| Graphics | Present mode | mailbox |
| Emulation | FEXCore | **2609-0** for 32-bit and 64-bit |
| Emulation | WINEESYNC | off |
| Environment | `TU_DEBUG` | `noconform,sysmem` |
| Environment | `MESA_VK_WSI_PRESENT_MODE` | `mailbox` |

`sysmem` matters on Adreno 8xx: GMEM is glitchy there. whitebelyash's A8xx notes call that out.

A donor `Config.wtf` in `_classic_beta_/WTF/` with **graphicsQuality / raidGraphicsQuality = 1**, `gxApi D3D11`, and the screen-narrator and photosensitivity flags off avoided the Screen Narrator `ASSERTSAFE` crash on first boot. That file is not in this repo.

While the picture was being debugged, `DXVK_LOG_LEVEL`, `DXVK_LOG_PATH`, and `MESA_LOG_FILE` were added on the Environment tab. They are not part of the launch. The phone was not attached when this note was written, so a live container export was not taken.

## What is in this repo

| Path | What it is |
|---|---|
| `driver/turnip-V32-RP6sched.zip` | The driver ZIP GameNative imports |
| `driver/meta.json` | The metadata packed in that ZIP |
| `patches/limit-barycentric-waits-to-current-block.patch` | RP6 ir3 scheduler skip |
| `patches/vulkan-android-icd-exports.patch` | `vk_icd*` exports only |
| `scripts/Launch-WoW-Direct.bat` | Starts `WowB-ARM64.exe -d3d11` from `C:` |
| `scripts/Launch-BattleNet.bat` | Starts `G:\Battle.net\Battle.net Launcher.exe` |

Not in this repo, and required on the phone: GameNative itself, the RP6 **Proton** and **DXVK** `.wcp` packages, the Battle.net install, and the WoW client. The Proton and DXVK packages come from the RP6 all-in-one bundle (25 September 2026).

## Driver

**whitebelyash Adreno 8xx Turnip (V32 / `turnip/gen8` @ `9c7e022`) + the RP6 ir3 scheduler barycentric-block skip.**

Import `driver/turnip-V32-RP6sched.zip` in GameNative (**Driver Manager → Import ZIP**). Do not unpack it on the phone. Select **Turnip-V32-RP6sched** as the graphics driver version.

`driver/meta.json` is the same metadata packed in the ZIP.

| Driver | Shader compile | Picture |
|---|---|---|
| RP6 `Turnip-WoW-scheduler-test` (a740-tuned) | OK | Stripe garbage / stall on 840 |
| Stock GameNative Gen8 V34 / Mesa 26.3 R3 | Fail (`vkCreateGraphicsPipelines`) | Silent Proton abort |
| Mesa `main` + upstream sched (`2f8dc9ea`) | OK | Same stripe garbage on 840 |
| whitebelyash Mainline Turnip v32 (`9c7e022`) | Fail after login / world shaders | Clean picture until the assert |
| **whitebelyash `9c7e022` + RP6 sched skip** | **OK** | **In-world** |

whitebelyash’s A8xx notes also matter: **GMEM is glitchy on 8xx**. Use **sysmem**.

### Sources

- whitebelyash Mesa: https://github.com/whitebelyash/mesa-unified/tree/turnip/gen8
  commit `9c7e022677dfa3abb356c2b6732cbd2e25783d01` (19 Sep 2026)
- Prebuilt V32 (same tree, no RP6 patch): https://github.com/whitebelyash/AdrenoToolsDrivers/releases/tag/tu_v32
- `patches/limit-barycentric-waits-to-current-block.patch` — RP6 scheduler skip
- `patches/vulkan-android-icd-exports.patch` — `vk_icd*` exports only. Do not apply the rest of the RP6 diagnostic-logging patch.

Mesa version string: `26.3.0-devel-9c7e022+rp6sched`

### Rebuild

NDK **27.1.12297006**, API **35** clang, `lld`.

```text
git clone --depth 1 -b turnip/gen8 https://github.com/whitebelyash/mesa-unified.git mesa-wb
cd mesa-wb
git checkout 9c7e022677dfa3abb356c2b6732cbd2e25783d01
```

Apply both patches. The scheduler change goes in `src/freedreno/ir3/ir3_sched.c`, immediately after the `IR3_INSTR_UNUSED` continue and before `if (!is_scheduled(baryf))`.

Meson cross file (adjust the NDK path):

```ini
[binaries]
ar = '.../ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar'
c = ['.../ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android35-clang']
cpp = ['.../ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android35-clang++']
c_ld = 'lld'
cpp_ld = 'lld'
strip = '.../ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip'

[built-in options]
cpp_args = ['-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables']
cpp_link_args = ['-static-libstdc++']

[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'
```

```bash
meson setup build-android --cross-file android-aarch64.ini \
  -Dbuildtype=release \
  -Dplatforms=android \
  -Dplatform-sdk-version=35 \
  -Dandroid-stub=true \
  -Dgallium-drivers= \
  -Dvulkan-drivers=freedreno \
  -Dvulkan-beta=true \
  -Dfreedreno-kmds=kgsl \
  -Dstrip=true \
  -Dandroid-libbacktrace=disabled \
  -Degl=disabled \
  -Dgbm=disabled \
  -Dglx=disabled \
  -Dopengl=false \
  -Dgles1=disabled \
  -Dgles2=disabled \
  -Dllvm=disabled \
  -Dtools= \
  -Dzstd=disabled

ninja -C build-android src/freedreno/vulkan/libvulkan_freedreno.so
```

Zip `libvulkan_freedreno.so` next to `driver/meta.json` and import that ZIP.

## Credits

- RP6 all-in-one test bundle (Proton 11.0-90624-arm64ec, DXVK 2.4.1-wow, scheduler patch)
- whitebelyash (`mesa-unified` `turnip/gen8`, AdrenoToolsDrivers V32)
- Mesa / Freedreno / Turnip
- GameNative 1.2.1

Unofficial community notes. Not affiliated with Blizzard.
