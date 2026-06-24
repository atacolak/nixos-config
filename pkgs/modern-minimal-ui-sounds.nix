{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "modern-minimal-ui-sounds";
  version = "2026-06-21";

  src = fetchFromGitHub {
    owner = "cadecomposer";
    repo = "modern-minimal-ui-sounds";
    rev = "2a391669f0d79cd0e2de502c0963b446c3728708";
    hash = "sha256-l8/nxuzBns2cyhGFral+XrTGSbI6jasoBvowQz72VOI=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    theme_dir="$out/share/sounds/modern-minimal-ui-sounds"
    mkdir -p "$theme_dir"
    cp -r index.theme stereo cinnamon "$theme_dir/"

    runHook postInstall
  '';

  meta = {
    description = "Modern Minimal UI freedesktop sound theme";
    homepage = "https://github.com/cadecomposer/modern-minimal-ui-sounds";
  };
}
