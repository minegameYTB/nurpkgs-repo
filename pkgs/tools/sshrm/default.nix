{
  lib,
  stdenvNoCC,
  makeWrapper,
  fetchFromGitHub,
  callPackage,
  coreutils,
}:

let
  ### Import sshUtilsOnly derivation
  sshUtilsOnly = callPackage ./deps/sshUtilsOnly.nix { };
in

stdenvNoCC.mkDerivation rec {
  pname = "sshrm";
  version = "0.0.0";

  src = ./sshrm;

  buildInputs = [
    sshUtilsOnly
    coreutils
    makeWrapper
  ];

  installPhase = ''
    ### Make sshrm available
    mkdir -p $out/bin $out/share/doc/${pname}
    cp ${pname} $out/bin/${pname}
  '';

  postFixup = ''
    ### Add runtime path to sshrm tool
    wrapProgram $out/bin/${pname} \
      --set PATH ${
        lib.makeBinPath [
          sshUtilsOnly
          coreutils
        ]
      } \
      --set TERM xterm-256color
  '';

  meta = {
    description = "A tool to remove quickly all keys belonging to the specified host from a known_hosts file.";
    homepage = "https://github.com/aaaaadrien/sshrm";
    license = lib.licenses.mit;
    mainProgram = "sshrm";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
