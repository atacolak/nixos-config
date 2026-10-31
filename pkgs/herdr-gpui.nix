# Native graphical client for the existing Herdr daemon; no second server.
{ lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper
, alsa-lib, fontconfig, freetype, libxkbcommon, libxcb
, vulkan-loader, wayland, libGL, wl-clipboard, xclip
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "herdr-gpui";
  version = "20261028.1";
  src = fetchurl {
    url = "https://github.com/penso/herdr-gpui/releases/download/v${finalAttrs.version}/Herdr-${finalAttrs.version}-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256:2ab531fbcd935c0c387c93f14d620c8a88a9f53a1d0cecd7234a8377ee650a85";
  };
  sourceRoot = "Herdr-${finalAttrs.version}-x86_64-unknown-linux-gnu";

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [
    alsa-lib fontconfig freetype libxkbcommon libxcb vulkan-loader
    wayland libGL stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/herdr-gpui "$out/bin/herdr-gpui"
    install -Dm755 bin/herdr-acp "$out/bin/herdr-acp"
    install -Dm755 bin/herdr-remote-control "$out/bin/herdr-remote-control"
    install -Dm755 bin/herdr-automate "$out/bin/herdr-automate"
    install -Dm644 share/applications/so.pen.herdr-gpui.desktop "$out/share/applications/so.pen.herdr-gpui.desktop"
    install -Dm644 share/icons/hicolor/scalable/apps/herdr-gpui.svg "$out/share/icons/hicolor/scalable/apps/herdr-gpui.svg"
    runHook postInstall
  '';

  # GPUI loads Vulkan and Wayland dynamically rather than linking them.
  postFixup = ''
    patchelf --add-rpath ${lib.makeLibraryPath [ vulkan-loader wayland ]} "$out/bin/herdr-gpui"
    wrapProgram "$out/bin/herdr-gpui" \
      --prefix PATH : ${lib.makeBinPath [ wl-clipboard xclip ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ vulkan-loader wayland ]}
  '';

  meta = with lib; {
    description = "Native graphical client for the existing Herdr server";
    homepage = "https://herdrui.dev";
    license = licenses.asl20;
    mainProgram = "herdr-gpui";
    platforms = [ "x86_64-linux" ];
  };
})
