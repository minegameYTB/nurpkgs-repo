{ pkgs, lib, stdenv, rustPlatform, fetchFromGitHub }:

let
  nightly = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
  rustPlatform = pkgs.makeRustPlatform {
    cargo = nightly;
    rustc = nightly;
  };
in

rustPlatform.buildRustPackage rec {
  pname = "edit";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-5GUAHa0/7k4uVNWEjn0hd1YvkRnUk6AdxTQhw5z95BY=";
  };
  cargoHash = "sha256-DEzjfrXSmum/GJdYanaRDKxG4+eNPWf5echLhStxcIg=";
}

