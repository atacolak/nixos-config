{ pkgs, ... }:

let
  observeosTree = pkgs.stdenvNoCC.mkDerivation {
    pname = "observeos-tree";
    version = "0.1.0";
    src = ../home/files/kwin/observeos-tree;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/kwin/scripts/observeos-tree
      cp -r $src/. $out/share/kwin/scripts/observeos-tree/
      substituteInPlace $out/share/kwin/scripts/observeos-tree/contents/code/tree.js \
        --replace-fail '__OBSERVEOS_CMD_PATH__' '/run/user/1000/observeos-tree.cmd'
    '';
  };
in
{
  environment.systemPackages = [ observeosTree ];
}
