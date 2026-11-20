{
  lib,
  stdenv,
  cmake,
  pkg-config,
  git,
  python3,
  python3Packages,
  libusb1,
  libevdev,
  openssl,
  json_c,
  curl,
  systemd,
  wayland,
  cargo,
  rustc,
  rustPlatform,
  fetchgit,
}:

let
  runtimeLibs = [
    libusb1
    libevdev
    openssl
    json_c
    curl
    systemd
    wayland
  ];
in
stdenv.mkDerivation {
  pname = "xr-driver";
  version = "2.11.9-unstable-2026-11-20";

  src = fetchgit {
    url = "https://github.com/wheaney/XRLinuxDriver";
    rev = "da303d2bc594bb5bf8a9123c6203f81f5869d955";
    fetchSubmodules = true;
    hash = "sha256-A6cF/kMkeDuh+aqzy4Z5/Nv5RQYN+H8R2H0Ep9sxO8M=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    git
    cargo
    rustc
    rustPlatform.cargoSetupHook
    (python3.withPackages (ps: [ ps.pyyaml ]))
  ];

  buildInputs = runtimeLibs;

  cargoRoot = "modules/xrealOneDeviceKit/modules/xreal_one_driver";
  cargoDeps = rustPlatform.fetchCargoVendor {
    src = fetchgit {
      url = "https://github.com/rohitsangwan01/xreal_one_driver";
      rev = "3e912315ec16e94e9a47688770d649cfef293624";
      hash = "sha256-WvO91NSBo5bYeCkOX5IdkhiCCgn/rbJ2dd2cuSIS4qM=";
    };
    hash = "sha256-ISgdmB5MEZ3P9KWCeURzr1PbIeb4BOCf1Z+Rs8wnJdM=";
  };

  installPhase = ''
    runHook preInstall
    cd "$NIX_BUILD_TOP/$sourceRoot"
    binPath=build/xrDriver
    if [ ! -f "$binPath" ]; then binPath=xrDriver; fi
    install -Dm755 "$binPath" $out/bin/xrDriver
    install -Dm755 bin/xr_driver_cli $out/bin/xr_driver_cli
    mkdir -p $out/lib/xr-driver
    cp -r lib/x86_64 $out/lib/xr-driver/x86_64
    mkdir -p $out/etc/udev/rules.d
    cp udev/*.rules $out/etc/udev/rules.d/
    runHook postInstall
  '';

  preFixup = ''
    patchelf --set-rpath "$out/lib/xr-driver/x86_64:$out/lib/xr-driver/x86_64/viture:${lib.makeLibraryPath runtimeLibs}:${stdenv.cc.cc.lib}/lib" "$out/bin/xrDriver"
  '';

  meta = with lib; {
    description = "User-space driver for XR glasses (VITURE, XREAL, Rokid, RayNeo)";
    homepage = "https://github.com/wheaney/XRLinuxDriver";
    license = licenses.gpl3Only;
    sourceProvenance = with sourceTypes; [ fromSource binaryNativeCode ];
    platforms = platforms.linux;
  };
}
