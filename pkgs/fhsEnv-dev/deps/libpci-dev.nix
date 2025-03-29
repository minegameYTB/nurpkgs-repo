{ stdenvNoCC, dpkg, lib, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "libpci-dev";
  version = "3.13.0-1+b1";
  arch = "amd64";

  src = fetchurl {
    url = "https://snapshot.debian.org/archive/debian/20241102T084005Z/pool/main/p/pciutils/${pname}_${version}_${arch}.deb";
    sha256 = "sha256-ceNDassfgQsGyB9pdpus80C1BqXPMFLr6Z9MJq7xViI=";
  };

  nativeBuildInputs = [ dpkg ];

  unpackPhase = ''
    dpkg -x $src .
  '';

  installPhase = ''
    mkdir -p $out
    cp -r usr/* $out/
  '';

  meta = with lib; {
    description = "Development files for libpci";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
