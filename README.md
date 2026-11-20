# nur-packages

**My personal [NUR](https://github.com/nix-community/NUR) repository**

<!-- Remove this if you don't use github actions -->
![Build and populate cache](https://github.com/minegameYTB/nurpkgs-repo/workflows/Build%20and%20populate%20cache/badge.svg)

<!--
Uncomment this if you use travis:

[![Build Status](https://travis-ci.com/<YOUR_TRAVIS_USERNAME>/nur-packages.svg?branch=master)](https://travis-ci.com/<YOUR_TRAVIS_USERNAME>/nur-packages)
-->
[![Cachix Cache](https://img.shields.io/badge/cachix-minegameytb-blue.svg)](https://minegameytb.cachix.org)

# How to add my cachix cache

Here an exemple of nix configuration for use the cache

```nix
{
  nix.settings = {
    substituters = [
      "https://minegameytb.cachix.org"
    ];
    trusted-public-keys = [
      "minegameytb.cachix.org-1:JvOgXYklqCayYEJWzlt0Sqc6zvs0S65ZZsWHYWh7qnc="
    ];
  };
}
```

# GTK2 legacy stack

GTK+ 2 is EOL (last release 2.24.33, December 2020) and nixpkgs marks its
`gtk2` package broken with removal planned (NixOS/nixpkgs#410814, ~27.05).
Legacy apps that still load `libgtk-x11-2.0.so` (mono/WinForms, bizhawk,
old editors, theme engines…) would break. This repo keeps them working:

- **`gtk2`** — vendored copy of nixpkgs' gtk2 expression
  (`pkgs/buildSupport/gtk2`), warning on use: legacy fallback only,
  prefer gtk3/gtk4 for new packages. The repo-local
  `callPackage` injects it, so old GTK2 packages keep evaluating after
  nixpkgs drops the attribute.
- **`gtk2-ng`** — experimental: [gtk2-ng](https://git.devuan.org/Daemonratte/gtk2-ng),
  the community fork (Devuan community + The Lateral Tech Foundation)
  that keeps GTK2 maintained on modern systems. Drop-in replacement: same
  SONAME and version (0.2400.33), still receives security fixes, pinned
  to a git commit (upstream has no tags — bump rev/hash together).
- **`bizhawk-gtk2ng`** — bizhawk variant running on gtk2-ng instead of
  the vendored gtk2.

To run any old GTK2 package on gtk2-ng, override its runtime argument:

```nix
someOldPackage.override { gtk2-x11 = nurpkgs-repo.gtk2-ng; }
```

(same recipe as `bizhawk-gtk2ng` in `pkgs/default.nix`).

To keep another package nixpkgs is about to remove, vendor its expression
under `pkgs/buildSupport/`, expose it with `lib.warn` (so nobody uses it
by default), and inject it through the repo-local `callPackage` — see the
header comments in `pkgs/default.nix` and `pkgs/buildSupport/gtk2/`.

