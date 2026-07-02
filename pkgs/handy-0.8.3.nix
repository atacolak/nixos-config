{ appimageTools, lib, makeDesktopItem, requireFile, symlinkJoin }:

let
  pname = "handy";
  version = "0.8.3";

  src = requireFile {
    name = "Handy_0.8.3_amd64.AppImage";
    hash = "sha256-8rQJVpABydLXGlyLNIdw/cilAcmwvmAb93VoaJJ+KJQ=";
    message = ''
      Handy is distributed as a manually downloaded AppImage.

      Put the exact file in the Nix store with:

        nix-store --add-fixed sha256 /home/sf/Downloads/Handy_0.8.3_amd64.AppImage

      Expected sha256:
        sha256-8rQJVpABydLXGlyLNIdw/cilAcmwvmAb93VoaJJ+KJQ=
    '';
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };

  appimage = appimageTools.wrapType2 {
    inherit pname version src;
  };

  desktopItem = makeDesktopItem {
    name = "handy";
    desktopName = "Handy";
    comment = "Handy";
    exec = "handy";
    icon = "handy";
    startupWMClass = "handy";
    categories = [ "Utility" ];
  };
in
symlinkJoin {
  name = "${pname}-${version}";
  paths = [ appimage desktopItem ];

  postBuild = ''
    install -Dm444 ${appimageContents}/Handy.png       $out/share/icons/hicolor/512x512/apps/handy.png
  '';

  meta = {
    description = "Handy desktop app packaged from the upstream AppImage";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "handy";
  };
}
