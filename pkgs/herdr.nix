{
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "herdr";
  version = "0.9.1";

  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v0.9.1/herdr-linux-x86_64";
    hash = "sha256-KgL+0WvrZR7wBuHUPwSPZSyk3FitBTzS1ERQVj1cVLc=";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm755 "$src" "$out/bin/herdr"
  '';
}
