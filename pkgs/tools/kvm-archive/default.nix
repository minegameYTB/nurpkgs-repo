{
  lib,
  stdenvNoCC,
  makeWrapper,
  coreutils,
  getent,
  gawk,
  gnused,
  findutils,
  gnugrep,
  pv,
  libvirt,
  qemu_kvm,
  gnutar,
  gzip,
  xz,
  zstd,
  zfs,
}:

stdenvNoCC.mkDerivation rec {
  pname = "kvm-archive";
  version = "0.0.0";

  src = ./kvm-archive;

  buildInputs = [
    coreutils
    getent
    gnused
    findutils
    gnugrep
    gawk
    pv
    libvirt
    qemu_kvm
    gnutar
    gzip
    xz
    zstd
    zfs
    makeWrapper
  ];

  dontUnpack = true;

  installPhase = ''
    ### Make gsettings-diff available
    mkdir -p $out/bin
    cp ${src} $out/bin/${pname}

    ### Change to executable file
    chmod +x $out/bin/${pname}
  '';

  postFixup = ''
    ### Add runtime path to gsettings-diff wrapper
    wrapProgram $out/bin/${pname} \
      --set PATH ${
        lib.makeBinPath [
          coreutils
          getent
          gnused
          findutils
          gnugrep
          gawk
          pv
          libvirt
          qemu_kvm
          gnutar
          gzip
          xz
          zstd
          zfs
        ]
      }
  '';

  meta = {
    description = "A tool for import and export libvirt vm";
    mainProgram = "kvm-archive";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
