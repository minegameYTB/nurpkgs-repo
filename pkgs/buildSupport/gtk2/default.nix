### Vendored copy of nixpkgs' gtk2 (MIT), kept in this repo because nixpkgs
### marks it broken and will remove it: NixOS/nixpkgs#410814 — 2.24.33 is
### EOL since 2020, removal targeted at 27.05. mono's WinForms (bizhawk) and
### other legacy apps still need libgtk-x11-2.0.so, so this copy survives
### the removal and stays available for packaging old GTK2 software.
###
### Vendored from nixpkgs @4fe25e12 (pkgs/by-name/gt/gtk2/package.nix),
### changed only where noted:
###   - `buildPackages.gtk2` now re-imports *this* expression instead of
###     nixpkgs' gtk2 (cross-compilation branch only), so evaluation keeps
###     working after nixpkgs drops gtk2.
###   - `replaceVars` dropped: the immodules-cache hook ships
###     pre-substituted (replaceVars does not exist on nixos-24.05; the
###     substituted values are gtk2 constants).
###   - `xorg.*` defaults on the top-level `libx*` args for older channels.
### On Linux this is equivalent to nixpkgs' `gtk2-x11` (gdktarget defaults
### to x11, cairo/pango ship with x11Support). Prefer gtk3/gtk4 for new
### packages — exposed as `gtk2` with an evaluation warning for that reason.
{
  config,
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  atk,
  buildPackages,
  cairo,
  cups,
  gdk-pixbuf,
  gettext,
  glib,
  gobject-introspection,
  ### `xorg.*` defaults serve older channels (CI still evaluates
  ### nixos-24.05, which predates the top-level `libx*` names); they are
  ### unused wherever the top-level names exist.
  xorg,
  libxcomposite ? xorg.libXcomposite,
  libxcursor ? xorg.libXcursor,
  libxdamage ? xorg.libXdamage,
  libxi ? xorg.libXi,
  libxinerama ? xorg.libXinerama,
  libxrandr ? xorg.libXrandr,
  libxrender ? xorg.libXrender,
  pango,
  perl,
  pkg-config,
  testers,
  gdktarget ? if stdenv.hostPlatform.isDarwin then "quartz" else "x11",
  cupsSupport ? config.gtk2.cups or stdenv.hostPlatform.isLinux,
  xineramaSupport ? stdenv.hostPlatform.isLinux,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gtk+";
  version = "2.24.33";

  src = fetchurl {
    url = "mirror://gnome/sources/gtk+/2.24/gtk+-${finalAttrs.version}.tar.xz";
    hash = "sha256-rCrHV/WULTGKMRpUsMgLXvKV8pnCpzxjL2v7H/Scxto=";
  };

  outputs = [
    "out"
    "dev"
    "devdoc"
  ];
  outputBin = "dev";

  setupHooks = [
    ./hooks/drop-icon-theme-cache.sh
    ### Pre-substituted instead of `replaceVars` (absent on nixos-24.05);
    ### gtk-2.0 / 2.10.0 are gtk2 constants baked into the file.
    ./hooks/clean-immodules-cache.sh
  ];

  nativeBuildInputs = finalAttrs.setupHooks ++ [
    gdk-pixbuf
    gettext
    gobject-introspection
    perl
    pkg-config
  ];

  patches = [
    ./patches/2.0-immodules.cache.patch
    ./patches/gtk2-theme-paths.patch
    (fetchpatch {
      # https://gitlab.gnome.org/GNOME/gtk/-/issues/6786
      name = "CVE-2024-6655.patch";
      url = "https://gitlab.gnome.org/GNOME/gtk/-/commit/3bbf0b6176d42836d23c36a6ac410e807ec0a7a7.patch";
      hash = "sha256-mstOPk9NNpUwScrdEbvGhmAv8jlds3SBdj53T0q33vM=";
    })
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    ./patches/2.0-gnome_bugzilla_557780_306776_freeciv_darwin.patch
    ./patches/2.0-darwin-x11.patch
    # Fixes an incompatible function pointer conversion and implicit int errors with clang 16.
    ./patches/2.0-clang.patch
  ];

  propagatedBuildInputs = [
    atk
    cairo
    gdk-pixbuf
    glib
    pango
  ]
  ++ lib.optionals (stdenv.hostPlatform.isLinux || stdenv.hostPlatform.isDarwin) [
    libxcomposite
    libxcursor
    libxi
    libxrandr
    libxrender
  ]
  ++ lib.optional xineramaSupport libxinerama
  ++ lib.optional cupsSupport cups
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ libxdamage ];

  preConfigure = lib.optionalString (
    stdenv.hostPlatform.isDarwin && lib.versionAtLeast stdenv.hostPlatform.darwinMinVersion "11"
  ) "MACOSX_DEPLOYMENT_TARGET=10.16";

  configureFlags = [
    "--sysconfdir=/etc"
    "--with-gdktarget=${gdktarget}"
    "--with-xinput=yes"
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    "--disable-glibtest"
    "--disable-introspection"
    "--disable-visibility"
  ]
  ++ lib.optionals (stdenv.buildPlatform != stdenv.hostPlatform) [
    ### Self-reference instead of `buildPackages.gtk2`: nixpkgs' gtk2 is
    ### being removed (NixOS/nixpkgs#410814) and this branch is only
    ### forced when cross-compiling.
    "ac_cv_path_GTK_UPDATE_ICON_CACHE=${
      buildPackages.callPackage ./default.nix { }
    }/bin/gtk-update-icon-cache"
    "ac_cv_path_GDK_PIXBUF_CSOURCE=${buildPackages.gdk-pixbuf.dev}/bin/gdk-pixbuf-csource"
  ];

  env = lib.optionalAttrs stdenv.cc.isGNU {
    NIX_CFLAGS_COMPILE = toString [
      "-Wno-error=implicit-int"
      "-Wno-error=incompatible-pointer-types"
    ];
  };

  enableParallelBuilding = true;

  installFlags = [ "sysconfdir=${placeholder "out"}/etc" ];

  doCheck = false; # needs X11

  postInstall = ''
    moveToOutput share/gtk-2.0/demo "$devdoc"
    # The updater is needed for nixos env and it's tiny.
    moveToOutput bin/gtk-update-icon-cache "$out"
  '';

  passthru = {
    gtkExeEnvPostBuild = ''
      rm $out/lib/gtk-2.0/2.10.0/immodules.cache
      $out/bin/gtk-query-immodules-2.0 $out/lib/gtk-2.0/2.10.0/immodules/*.so > $out/lib/gtk-2.0/2.10.0/immodules.cache
    ''; # workaround for bug of nix-mode for Emacs */ '';
    inherit gdktarget;
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    homepage = "https://www.gtk.org/";
    description = "Multi-platform toolkit for creating graphical user interfaces";
    longDescription = ''
      GTK is a highly usable, feature rich toolkit for creating graphical user
      interfaces which boasts cross platform compatibility and an easy to use
      API.  GTK it is written in C, but has bindings to many other popular
      programming languages such as C++, Python and C# among others.  GTK is
      licensed under the GNU LGPL 2.1 allowing development of both free and
      proprietary software with GTK without any license fees or royalties.
    '';
    changelog = "https://gitlab.gnome.org/GNOME/gtk/-/raw/${finalAttrs.version}/NEWS";
    license = lib.licenses.lgpl2Plus;
    maintainers = with lib.maintainers; [ raskin ];
    platforms = lib.platforms.all;
    pkgConfigModules = [
      "gdk-2.0"
      "gtk+-2.0"
    ]
    ++ lib.optionals (gdktarget == "x11") [
      "gdk-x11-2.0"
      "gtk+-x11-2.0"
    ];
    ### Note: nixpkgs' `meta.problems.broken` removal notice deliberately
    ### NOT vendored — see the header comment: this copy must stay
    ### evaluable (NixOS/nixpkgs#410814).

  };
})
