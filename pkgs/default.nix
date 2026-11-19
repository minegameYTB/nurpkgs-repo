{ lib, pkgs }:

let
  ### Vendored gtk2 (see pkgs/buildSupport/gtk2): nixpkgs marks it broken
  ### and will remove it (NixOS/nixpkgs#410814), but legacy consumers
  ### (bizhawk/mono WinForms, old GTK2 apps) still need libgtk-x11-2.0.so.
  ### The warning fires on every evaluation to remind that this is a legacy
  ### fallback — not recommended for new packages, prefer gtk3/gtk4 when
  ### possible.
  gtk2 =
    lib.warn
      "nurpkgs: using the vendored gtk2 2.24.33 (nixpkgs drops it: NixOS/nixpkgs#410814). Legacy fallback only — not recommended for new packages, prefer gtk3/gtk4 when possible."
      (pkgs.callPackage ./buildSupport/gtk2 { });

  ### callPackage with repo defaults: packages asking for `gtk2` or
  ### `gtk2-x11` pick up the vendored copy above automatically (an explicit
  ### argument still wins), so old GTK2 software keeps evaluating after
  ### nixpkgs removes gtk2. `callPackageWith` filters the injected defaults
  ### through `functionArgs`, unlike explicit arguments, so packages that
  ### do not take gtk2 are unaffected.
  callPackage =
    f: args:
    lib.callPackageWith (
      pkgs
      // {
        inherit gtk2;
        gtk2-x11 = gtk2;
      }
    ) f args;
in
rec {
  inherit gtk2;

  ### Utilities
  sshrm = callPackage ./tools/sshrm { };
  GLFfetch = callPackage ./misc/GLFfetch { };
  GLFfetch-glfos = GLFfetch.override { glfIcon = "GLFos"; };
  gsettings-diff = callPackage ./tools/gsettings-diff { };
  kvm-archive = callPackage ./tools/kvm-archive { };
  rea = callPackage ./tools/rea { };
  rea-ghidra = rea.override (
    {
      withGhidra = true;
    }
    // lib.optionalAttrs (pkgs ? ghidra) { inherit (pkgs) ghidra; }
    ### Ghidra 12.2 requires application.java.min=25; pkgs.jdk may be older.
    // lib.optionalAttrs (pkgs ? jdk25) { jdk = pkgs.jdk25; }
  );

  ### Emulators & MCP
  bizhawk = callPackage ./tools/bizhawk { };
  mcp-bizhawk = callPackage ./tools/mcp-bizhawk { };

  ### dev set
  dev = rec {
    ### Without option (with clang variant)
    fhsEnv-shell = callPackage ./tools/fhsEnv-shell { };
    fhsEnv-shell-clang = fhsEnv-shell.override { useClang = true; };

    ### With kernel-tools
    fhsEnv-shell-krnl = fhsEnv-shell.override { kernel-tools = true; };

    ### With buildroot-tools
    fhsEnv-shell-buildroot = fhsEnv-shell.override { buildroot-tools = true; };

    ### With debian-tools
    fhsEnv-shell-deb-tools = fhsEnv-shell.override { debian-tools = true; };
    fhsEnv-shell-deb-tools-clang = fhsEnv-shell.override {
      debian-tools = true;
      useClang = true;
    };
    fhsEnv-shell-deb-tools-krnl = fhsEnv-shell.override {
      debian-tools = true;
      kernel-tools = true;
    };

    ### With redhat-tools
    fhsEnv-shell-rh-tools = fhsEnv-shell.override { redhat-tools = true; };
    fhsEnv-shell-rh-tools-clang = fhsEnv-shell.override {
      redhat-tools = true;
      useClang = true;
    };
    fhsEnv-shell-rh-tools-krnl = fhsEnv-shell.override {
      redhat-tools = true;
      kernel-tools = true;
    };

    ### All configuration (With or without clang)
    fhsEnv-shell-all = fhsEnv-shell.override {
      kernel-tools = true;
      buildroot-tools = true;
    };
    fhsEnv-shell-all-specific = fhsEnv-shell.override {
      redhat-tools = true;
      debian-tools = true;
      kernel-tools = true;
      buildroot-tools = true;
    };
    fhsEnv-shell-all-specific-nokrnl = fhsEnv-shell.override {
      redhat-tools = true;
      debian-tools = true;
      buildroot-tools = true;
      useClang = true;
    };

    ### 32-bit mirror (i686) - strict mirror of dev.* with i686Support
    i686 = rec {
      fhsEnv-shell = dev.fhsEnv-shell.override { i686Support = true; };
      fhsEnv-shell-clang = fhsEnv-shell.override { useClang = true; };
      fhsEnv-shell-krnl = fhsEnv-shell.override { kernel-tools = true; };
      fhsEnv-shell-buildroot = fhsEnv-shell.override { buildroot-tools = true; };
      fhsEnv-shell-deb-tools = fhsEnv-shell.override { debian-tools = true; };
      fhsEnv-shell-deb-tools-clang = fhsEnv-shell.override {
        debian-tools = true;
        useClang = true;
      };
      fhsEnv-shell-deb-tools-krnl = fhsEnv-shell.override {
        debian-tools = true;
        kernel-tools = true;
      };
      fhsEnv-shell-rh-tools = fhsEnv-shell.override { redhat-tools = true; };
      fhsEnv-shell-rh-tools-clang = fhsEnv-shell.override {
        redhat-tools = true;
        useClang = true;
      };
      fhsEnv-shell-rh-tools-krnl = fhsEnv-shell.override {
        redhat-tools = true;
        kernel-tools = true;
      };
      fhsEnv-shell-all = fhsEnv-shell.override {
        kernel-tools = true;
        buildroot-tools = true;
      };
      fhsEnv-shell-all-specific = fhsEnv-shell.override {
        kernel-tools = true;
        buildroot-tools = true;
        debian-tools = true;
        redhat-tools = true;
      };
      fhsEnv-shell-all-specific-nokrnl = fhsEnv-shell.override {
        buildroot-tools = true;
        debian-tools = true;
        redhat-tools = true;
        useClang = true;
      };
      fhsEnv-shell-all-clang = fhsEnv-shell.override {
        useClang = true;
        kernel-tools = true;
        buildroot-tools = true;
        debian-tools = true;
        redhat-tools = true;
      };
    };
  };

  ### Theme sets
  theme = rec {
    marble-shell-filled = callPackage ./theme/marble-shell-filled { };

  };

  # some-qt5-package = libsForQt5.callPackage ./some-qt5-package { };
  # ...
  # Examples with extra options:
  # fhsEnv-shell-custom = callPackage ./tools/fhsEnv-shell {
  #   extraPkgs = pkgs: with pkgs; [ docker ripgrep jq ];
  #   extraInitCommands = "alias ll='ls -la'";
  # };
}
