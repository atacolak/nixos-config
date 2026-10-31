{ pkgs, ... }:

let
  observeosTree = pkgs.stdenvNoCC.mkDerivation {
    pname = "observeos-tree";
    version = "0.1.0";
    src = ./files/kwin/observeos-tree;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out
      cp -r $src/. $out/
      substituteInPlace $out/contents/code/tree.js \
        --replace-fail '__OBSERVEOS_CMD_PATH__' '/run/user/1000/observeos-tree.cmd'
    '';
  };
in
{
  xdg.dataFile."kwin/scripts/observeos-tree".source = observeosTree;
  xdg.configFile."kwinrc".text = ''
    [Plugins]
    observeos-treeEnabled=true
  '';
}
