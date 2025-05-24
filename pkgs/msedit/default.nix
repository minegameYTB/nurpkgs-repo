{ lib, stdenvNoCC, fetchurl, xz, autoPatchelfHook }:

let
  system = stdenvNoCC.hostPlatform.system;
  archMap = {
    "x86_64-linux" = "x86_64-linux-gnu";
    "aarch64-linux" = "aarch64-linux-gnu";
  };
  archSuffix = archMap.${system} or (throw "Unsupported system: ${system}");
in

stdenvNoCC.mkDerivation rec {
  ### Name this program with this name bc edit already exist (not the same program)
  pname = "msedit";
  version = "1.0.0";

  src = fetchurl {
    url = "https://github.com/microsoft/edit/releases/download/v${version}/edit-${version}-${archSuffix}.xz";
    sha256 = "sha256-vattsWsWezjvMY55cqEActVixMotuibqfqM88aEGpvo=";
  };
  
  ### stdenv options
  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;
  sourceRoot = ".";

  nativeBuildInputs = [ xz autoPatchelfHook ];

  installPhase = ''
    ### Create directory and move binary
    mkdir -p $out/bin
    
    ### Move program to $out/bin/
    unxz -c $src > $out/bin/${pname}

    ### Make this program executable
    chmod +x $out/bin/${pname}
  '';

  meta = with lib; {
    description = "A simple editor for simple needs.";
    homepage = "https://github.com/microsoft/edit";
    license = licenses.mit;
    mainProgram = "msedit";
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}

