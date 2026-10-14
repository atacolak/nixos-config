{
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "herdr";
  version = "0.8.2";

  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v0.8.2/herdr-linux-x86_64";
    hash = "sha256:976150a14d490c94b243ea2e1a7eb2dfb67f12e36b182db90936f6728e6aecf4";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm755 "$src" "$out/bin/herdr"
  '';
}
