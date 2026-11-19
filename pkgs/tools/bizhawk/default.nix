### BizHawk (EmuHawk) packaged from the official Linux x64 release artifact.
###
### Deliberately self-contained — only `fetchurl`, the runtime libraries the
### upstream `Dist/launch-scripts.nix` wires up for 2.11.1, and a wrapper that
### keeps the writable parts out of the Nix store — so the expression can be
### dropped into a NUR repo as-is.
{
  lib,
  stdenv,
  fetchurl,
  coreutils,
  copyDesktopItems,
  makeDesktopItem,
  ### Runtime deps, same set as upstream `genDepsHostTargetFor` for 2.11.1
  ### (needsSDL + needsLibGLVND) minus libudev: the release ships its own
  ### libSDL2.so, which does not link against it.
  mono,
  libgdiplus,
  gtk2-x11,
  gnome-themes-extra,
  lua,
  openal,
  zstd,
  SDL2,
  libGL,
  ### X11 libraries neither the release nor SDL2 links against: both *dlopen*
  ### them at runtime from the managed side (`libXi.so.6`, `libXfixes.so.3`
  ### from BizHawk.Common.dll for relative mouse input / mouse capture;
  ### `libX11.so.6`, `libX11-xcb.so.1`, `libXext.so.6`, `libXss.so.1` from the
  ### bundled libSDL2.so). Without them in LD_LIBRARY_PATH they are simply
  ### absent on a headless/NixOS system, and BizHawk logs
  ### "libXi.so.6 is not present" / "libXfixes.so.3 is not present".
  ### Top-level names preferred: the `xorg` package set is deprecated in
  ### 26.05. The `xorg.*` defaults only serve older channels (CI still
  ### evaluates nixos-24.05, which lacks the top-level `libx*` names).
  xorg,
  libx11 ? xorg.libX11,
  libxext ? xorg.libXext,
  libxi ? xorg.libXi,
  libxfixes ? xorg.libXfixes,
  libxscrnsaver ? xorg.libXScrnSaver,
}:

let
  version = "2.11.1";

  runtimeLibs = [
    gtk2-x11
    libgdiplus
    lua
    mono
    openal
    zstd
    SDL2
    libGL
    libx11
    libxext
    libxi
    libxfixes
    libxscrnsaver
  ];

  ### Directories BizHawk reads *and rewrites* through its PathEntries (the
  ### `Global_NULL` base) rather than next to the executable: they must live in
  ### a writable tree, so the first run copies them into the user's data home.
  ### gamedb / Shaders / defctrl.json stay next to EmuHawk.exe in the store,
  ### exactly like upstream's `splitReleaseArtifact` puts them in `out`.
  seedDirs = [
    "Lua"
    "Tools"
    "ExternalTools"
    "Firmware"
    "Gameboy"
    "NES"
    "overlay"
  ];
in
stdenv.mkDerivation {
  pname = "bizhawk";
  inherit version;

  src = fetchurl {
    url = "https://github.com/TASEmulators/BizHawk/releases/download/${version}/BizHawk-${version}-linux-x64.tar.gz";
    hash = "sha256-OMnBIofjN6Cmkj/VJ3Z8hTRX1h1x59itGnctZM6LyT8=";
  };

  nativeBuildInputs = [ copyDesktopItems ];
  buildInputs = runtimeLibs;

  desktopItems = [
    (makeDesktopItem {
      name = "bizhawk";
      desktopName = "BizHawk";
      genericName = "Multi-system emulator";
      comment = "EmuHawk, the BizHawk multi-system emulator front-end";
      exec = "bizhawk";
      categories = [
        "Game"
        "Emulator"
      ];
      keywords = [
        "emulator"
        "tas"
        "rerecording"
      ];
    })
  ];

  ### The release is a ready-made binary tree: nothing to configure or build.
  dontConfigure = true;
  dontBuild = true;

  ### The bundled `.so` files already carry their own linkage and the wrapper
  ### below supplies every missing library through LD_LIBRARY_PATH, so leave
  ### the prebuilt binaries alone.
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share $out/bin
    cp -a . $out/share/bizhawk

    ### Resolved from $0 rather than baked in: when installed through
    ### environment.systemPackages, $0 is a /run/current-system/sw symlink.
    ### `realpath` refuses `..` after a regular file, hence the two steps.
    cat > $out/bin/bizhawk <<'WRAPPER'
    #!${stdenv.shell}
    set -e

    selfPath="$(${coreutils}/bin/realpath "$0")"
    BIZHAWK_HOME="$(${coreutils}/bin/realpath "''${selfPath%/*}/..")/share/bizhawk"

    ### The release tree is read-only in the store: everything BizHawk writes
    ### (config.json, Lua scripts, tools, palettes) goes to a per-version data
    ### home, seeded from the store on the first run.
    DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}/bizhawk-${version}"

    if [ ! -d "$DATA_HOME" ]; then
      echo "Seeding BizHawk data directory: $DATA_HOME" >&2
      mkdir -p "$DATA_HOME"
      for d in ${lib.escapeShellArgs seedDirs}; do
        if [ -e "$BIZHAWK_HOME/$d" ]; then
          cp -a "$BIZHAWK_HOME/$d" "$DATA_HOME/$d"
        else
          mkdir -p "$DATA_HOME/$d"
        fi
      done
    fi

    ### Only `LastWrittenFrom` (skips config migrations) and the Global_NULL
    ### base path, the same pair upstream's launch-scripts.nix writes.
    if [ ! -e "$DATA_HOME/config.json" ]; then
      printf '{"LastWrittenFrom":"%s","PathEntries":{"Paths":[{"System":"Global_NULL","Type":"Base","Path":"%s"}]}}\n' \
        "${version}" "$DATA_HOME" > "$DATA_HOME/config.json"
    fi

    ### Only existed to skip upstream's tee wrapper; this script never
    ### redirects output.
    if [ "$1" = "--mono-no-redirect" ]; then
      shift
    fi

    export BIZHAWK_HOME
    export BIZHAWK_DATA_HOME="$DATA_HOME"
    ### `$BIZHAWK_HOME/dll` first (the release's own `.so` files), then this
    ### package's lib dirs — note the `:` separator, without it the whole path
    ### collapses into the invalid `$BIZHAWK_HOME/nix/store/...`.
    export LD_LIBRARY_PATH="$BIZHAWK_HOME/dll:$BIZHAWK_HOME:${lib.makeLibraryPath runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    ### Adwaita instead of the beige built-in colourscheme, without the
    ### "unable to locate theme engine" warning upstream fixes the same way.
    export GTK_PATH="${gnome-themes-extra}/lib/gtk-2.0''${GTK_PATH:+:$GTK_PATH}"
    ### https://bugzilla.xamarin.com/show_bug.cgi?id=28047#c9
    export MONO_WINFORMS_XIM_STYLE=disabled
    export MONO_CRASH_NOFILE=1

    cd "$DATA_HOME"
    exec ${lib.getExe' mono "mono"} "$BIZHAWK_HOME/EmuHawk.exe" --config="$DATA_HOME/config.json" "$@"
    WRAPPER
    chmod +x $out/bin/bizhawk

    runHook postInstall
  '';

  meta = {
    description = "Multi-system emulator front-end (EmuHawk), from the official Linux release";
    homepage = "https://github.com/TASEmulators/BizHawk";
    license = lib.licenses.mit;
    mainProgram = "bizhawk";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [
      lib.sourceTypes.binaryNativeCode
      lib.sourceTypes.binaryBytecode
    ];
  };
}
