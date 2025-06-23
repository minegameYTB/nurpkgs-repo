{
  lib, 
  rustPlatform,
  icu,
  makeWrapper,
  fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "msedit";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "edit";
    rev = "v${version}";
    hash = "sha256-ubdZynQVwCYhZA/z4P/v6aX5rRG9BCcWKih/PzuPSeE=";
  };
  
  ### Use rust nightly from this variable
  env.RUSTC_BOOTSTRAP = 1;

  ### hash from cargo.lock to the edit repository
  cargoHash = "sha256-qT4u8LuKX/QbZojNDoK43cRnxXwMjvEwybeuZIK6DQQ=";
  
  ### Disable install check (found here: https://github.com/RossSmyth/nixpkgs/blob/4f09843cb4edf26fac02a021eecfd9e5af0e5206/pkgs/by-name/ms/ms-edit/package.nix)
  doInstallCheck = false;

  ### Build inputs
  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    ### Create doc directory
    mkdir -p $out/share/doc/${pname}

    ### Move files in this directory
    cp $src/LICENSE $out/share/doc/${pname}
    cp $src/README.md $out/share/doc/${pname}

    ### rename "edit" to "msedit"
    mv $out/bin/edit $out/bin/msedit
    
    ### Add icu ("Unicode and globalization support library") to the app environment
    ### (based on https://github.com/dtomvan/nur-packages/blob/0d9b84b67786425c259ecdb83f7a88165f06395d/pkgs/microsoft-edit/package.nix)
    wrapProgram $out/bin/msedit \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ icu ]}
  '';
    
  meta = {
    description = "A simple editor for simple needs.";
    homepage = "https://github.com/microsoft/edit";
    license = lib.licenses.mit;
    mainProgram = "msedit";
  };
}
