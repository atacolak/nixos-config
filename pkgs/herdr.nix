{
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "herdr";
  version = "0.7.5";

  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v0.7.5/herdr-linux-x86_64";
    hash = "sha256-PcgyiAc+TC08Z5ow576XvMqRQcb9F7u5khkULpXFklM=";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm755 "$src" "$out/bin/herdr"
  '';
}
