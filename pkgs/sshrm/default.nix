{ lib, stdenvNoCC, openssh, makeWrapper, fetchFromGitHub, callPackage }:

let
  ### Import sshUtilsOnly derivation
  sshUtilsOnly = callPackage ./deps/sshUtilsOnly.nix {};
in

stdenvNoCC.mkDerivation rec {
  pname = "sshrm";
  version = "git-${builtins.substring 0 7 src.rev}";

  src = fetchFromGitHub {
    owner = "aaaaadrien";
    repo = pname;
    rev = "0803f982130ebcceb43abe4fe84da3541856ed46";
    sha256 = "sha256-Sm9RAK6UdvL0yHfE12gIjoLfy3pZBqgRtfm20X1FWm0=";
  };

  outputs = [ "out" "doc" ];
  outputsToInstall = outputs;
  buildInputs = [ sshUtilsOnly makeWrapper ];

  installPhase = ''
    ### Rendre sshrm disponible
    mkdir -p $out/bin $doc/share/doc/${pname}
    cp ${pname} $out/bin/${pname}

    ### Ajouter le fichier de licence accessible dans le répertoire doc
    cp LICENSE $doc/share/doc/${pname}/LICENSE
    cp README.md $doc/share/doc/${pname}/README.md
  '';

  postFixup = ''
    ### Ajouter le chemin d'exécution à l'outil sshrm
    wrapProgram $out/bin/${pname} \
      --set PATH ${lib.makeBinPath [ sshUtilsOnly ]} \
      --set TERM xterm-256color
  '';

  meta = {
    description = "A tool to remove quickly all keys belonging to the specified host from a known_hosts file.";
    homepage = "https://github.com/aaaaadrien/sshrm";
    license = lib.licenses.mit;
    mainProgram = "sshrm";
  };
}
