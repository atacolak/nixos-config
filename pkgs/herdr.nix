{
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "herdr";
  version = "0.7.0";

  src = fetchurl {
    url = "https://github.com/ogulcancelik/herdr/releases/download/v0.7.0/herdr-linux-x86_64";
    hash = "sha256-rSpdSApOBGCandMKGewHhUV432tfDqkpkkaWO69ANjs=";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm755 "$src" "$out/bin/herdr"
  '';
}
