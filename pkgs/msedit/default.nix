{ pkgs, lib, stdenv, rustPlatform, fetchFromGitHub }:

let
  nightly = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
  rustPlatform = pkgs.makeRustPlatform {
    cargo = nightly;
    rustc = nightly;
  };
in

rustPlatform.buildRustPackage rec {
  pname = "msedit";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "edit";
    rev = "v${version}";
    hash = "sha256-5GUAHa0/7k4uVNWEjn0hd1YvkRnUk6AdxTQhw5z95BY=";
  };

  ### hash from cargo.lock to the edit repository
  cargoHash = "sha256-DEzjfrXSmum/GJdYanaRDKxG4+eNPWf5echLhStxcIg=";

  postInstall = ''
    ### Create doc directory
    mkdir -p $out/share/doc/${pname}

    ### Move files in this directory
    cp $src/LICENSE $out/share/doc/${pname}
    cp $src/README.md $out/share/doc/${pname}

    ### rename "edit" to "msedit"
    mv $out/bin/edit $out/bin/msedit
  '';
    
  meta = {
    description = "A simple editor for simple needs.";
    homepage = "https://github.com/microsoft/edit";
    license = lib.licenses.mit;
    mainProgram = "msedit";
  };
}