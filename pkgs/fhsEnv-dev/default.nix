{
 stdenvNoCC,
 buildFHSEnv,
 lib,
 libsForQt5,
 pkgs,
 gcc,
 ncurses,
 bashInteractive,
 writeScript,
 kernel-tools ? false,  ### Option to enable kernel development tools
 buildroot-tools ? false,  ### Option to enable Buildroot-specific tools
 useClang ? false, ### Enable this to use clang instead of gcc
 test ? false
}:

let
  ### Selection of stdenv based on the chosen compiler
  stdenv = if useClang then pkgs.clangStdenv else pkgs.stdenv;

  ### System configuration (host platform)
  system = lib.systems.elaborate stdenv.hostPlatform;

  fhsEnv = buildFHSEnv {
    name = "fhsEnv-shell";
    targetPkgs = pkgs: with pkgs; [
      ### Core compilation tools (always included)
      nettools
      ncurses5
      (if useClang then clang else gcc)
      gnumake
      gnupatch
      git
      gnutar
      gzip
      bzip2
      xz
      rsync
      wget
      cpio
      perl
      python3
      which
      file
      findutils
      util-linux
      openssl
      bc
      unzip
      pkg-config

      ### Additional essential tools for compatibility and flexibility
      flex
      bison
      gawk
      gettext
      texinfo
    ] ++ lib.optionals kernel-tools ([
      ### Kernel-specific tools (enabled with kernel-tools = true)
      libsForQt5.qt5.qtbase
      libcap_ng
      pciutils

      ### Rust tools
      rustc
      rust-bindgen
      
      ### Headers
      openssl.dev
      ncurses5.dev
      libsForQt5.qt5.qtbase.dev
    ] ++ pkgs.linux.nativeBuildInputs) ++ lib.optionals buildroot-tools ([
      ### Buildroot-specific tools (enabled with buildroot-tools = true) 
      ### When kernel-tools is not used, include these tools in case
      flex
      bison
      gawk
      gettext
      texinfo

      ### Buildroot dependancies in additions to other tools
      patchutils
      swig
      gperf
      libtool
      libmpc
      libelf
      mpfr
      gmp
    ]) ++ lib.optionals test ([
      cowsay
      hello
    ]);

    ### Shell script that run automacally when enterred in this environment
    runScript = pkgs.writeScript "init.sh" ''
      ### Environment variables
      export ARCH=${lib.head (lib.splitString "-" system.config)}
      export hardeningDisable=all

      ### Variable used for compilation
      export CC="${if useClang then "clang" else "gcc"}"
      export CXX="${if useClang then "clang++" else "g++"}"

      ${lib.optionalString kernel-tools ''
        ### Add env variable for qt5 (kernel-tools = true)
        export PKG_CONFIG_PATH="${ncurses.dev}/lib/pkgconfig:${libsForQt5.qt5.qtbase.dev}/lib/pkgconfig"    
        export QT_QPA_PLATFORM_PLUGIN_PATH="${libsForQt5.qt5.qtbase.bin}/lib/qt-${libsForQt5.qt5.qtbase.version}/plugins"
      ''}
      ### Custom PS1 for the shell environment (NixOS style)
      export PROMPT_COMMAND='PS1="\[\e[1;32m\][fhsEnv-shell:\w]\$\[\e[0m\] "'

      exec ${bashInteractive}/bin/bash
    '';
  };
in stdenv.mkDerivation {
  pname = "fhsEnv-shell";
  version = gcc.version;

  ### stdenv options
  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;
  dontPatchElf = true;

  installPhase = ''
    mkdir $out
    ln -s ${fhsEnv}/bin $out/bin
  '';

  meta = with lib; {
    description = "A multi-platform, multi-distribution development environment for Linux kernel and Buildroot tooling.";
    license = licenses.gpl3;
    mainProgram = "fhsEnv-shell";
  };
}
