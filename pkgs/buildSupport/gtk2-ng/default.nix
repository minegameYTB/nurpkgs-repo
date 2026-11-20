### gtk2-ng: community fork of GTK+ 2.24 keeping GTK2 alive on modern
### systems (https://git.devuan.org/Daemonratte/gtk2-ng), backed by the
### devuanusers.com community and The Lateral Tech Foundation. ABI-
### compatible with gtk2 (same SONAME libgtk-x11-2.0.so.0, same version
### 0.2400.33), X11-first, receives security/compatibility fixes while
### upstream GTK2 is EOL since 2020. Still actively developed (last
### commits Sep 2026) but pre-1.0 in process: no tags, pinned to a commit
### below — bump the rev/hash together. Experimental: the vendored gtk2
### (../gtk2) stays the default runtime; use via `gtk2-x11 = gtk2-ng`
### overrides (see bizhawk-gtk2ng).
###
### Derived from the vendored nixpkgs gtk2 expression (../gtk2), changes:
###   - src: git archive of gtk2-ng @eb29a34 (2026-09-03) instead of the
###     gtk+-2.24.33 release tarball
###   - preConfigure bootstraps the git tree (no pregenerated configure):
###     NOCONFIGURE=1 ./autogen.sh needs autoconf/automake/libtool/gtk-doc
###   - fribidi added to propagatedBuildInputs: gtk2-ng's configure.ac
###     requires it explicitly (stock gtk2 gets it transitively)
###   - CVE-2024-6655 patch (../gtk2/patches) dropped: already applied
###     upstream in gtk2-ng (find_module no longer loads modules from cwd)
###   - cross-compilation branch and Darwin patches dropped: experimental
###     Linux-only package
{
  lib,
  stdenv,
  fetchzip,
  autoconf,
  automake,
  atk,
  cairo,
  cups,
  fribidi,
  gdk-pixbuf,
  gettext,
  glib,
  gobject-introspection,
  gtk-doc,
  libtool,
  pango,
  perl,
  pkg-config,
  ### `xorg.*` defaults serve older channels (CI still evaluates
  ### nixos-24.05, which predates the top-level `libx*` names); they are
  ### unused wherever the top-level names exist.
  xorg,
  libxcomposite ? xorg.libXcomposite,
  libxcursor ? xorg.libXcursor,
  libxi ? xorg.libXi,
  libxinerama ? xorg.libXinerama,
  libxrandr ? xorg.libXrandr,
  libxrender ? xorg.libXrender,
  gdktarget ? "x11",
  cupsSupport ? stdenv.hostPlatform.isLinux,
  xineramaSupport ? stdenv.hostPlatform.isLinux,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gtk2-ng";
  version = "2.24.33-unstable-2026-09-03";

  src = fetchzip {
    url = "https://git.devuan.org/Daemonratte/gtk2-ng/archive/eb29a34fda1401429581e6e034603b98a46f9434.tar.gz";
    hash = "sha256-x4HP1Haa6bWkd5AFSuZPXy1TCapSSwW6MZQmB2uFtUo=";
  };

  outputs = [
    "out"
    "dev"
    "devdoc"
  ];
  outputBin = "dev";

  setupHooks = [
    ../gtk2/hooks/drop-icon-theme-cache.sh
    ../gtk2/hooks/clean-immodules-cache.sh
  ];

  nativeBuildInputs = finalAttrs.setupHooks ++ [
    autoconf
    automake
    gdk-pixbuf
    gettext
    gobject-introspection
    gtk-doc
    libtool
    perl
    pkg-config
  ];

  ### Same nixpkgs patches as the vendored gtk2; the CVE-2024-6655 patch
  ### is intentionally absent (already applied upstream in gtk2-ng).
  patches = [
    ../gtk2/patches/2.0-immodules.cache.patch
    ../gtk2/patches/gtk2-theme-paths.patch
  ];

  propagatedBuildInputs = [
    atk
    cairo
    fribidi
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
  ++ lib.optional cupsSupport cups;

  ### Git tree has no pregenerated configure: bootstrap it (autogen.sh
  ### runs aclocal/libtoolize/gtkdocize/autoheader/automake/autoconf).
  preConfigure = ''
    NOCONFIGURE=1 ./autogen.sh
  '';

  configureFlags = [
    "--sysconfdir=/etc"
    "--with-gdktarget=${gdktarget}"
    "--with-xinput=yes"
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
    if [ -e "$out/share/gtk-2.0/demo" ]; then
      moveToOutput share/gtk-2.0/demo "$devdoc"
    fi
    if [ -e "$out/bin/gtk-update-icon-cache" ]; then
      moveToOutput bin/gtk-update-icon-cache "$out"
    fi
  '';

  passthru = {
    inherit gdktarget;
  };

  meta = {
    homepage = "https://git.devuan.org/Daemonratte/gtk2-ng";
    description = "Community fork of GTK+ 2.24 that keeps GTK2 alive on modern systems";
    longDescription = ''
      gtk2-ng is an unofficial, community-maintained fork of GTK+ 2.24
      focused on modern compatibility while preserving stability, ABI
      compatibility and original behavior. X11-first, no forced Wayland
      migration. Backed by the devuanusers.com community and The Lateral
      Tech Foundation. It drops-in for gtk2 (same SONAME and versioning)
      and keeps receiving fixes although upstream GTK2 is EOL.
    '';
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.linux;
  };
})
