{
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "herdr";
  version = "0.9.0";

  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v0.9.0/herdr-linux-x86_64";
    hash = "sha256-T6GgEVjdgEPaktMbJweAsNzBBgMDjZthysTYGrY/tx8=";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm755 "$src" "$out/bin/herdr"
  '';
}
