{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # Cloak Chromium is a generic Linux ELF (not a nix store chrome).
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glib
    nss
    nspr
    atk
    at-spi2-atk
    at-spi2-core
    cups
    dbus
    libdrm
    mesa
    libglvnd
    wayland
    pango
    cairo
    gtk3
    alsa-lib
    libxkbcommon
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    libgbm
    expat
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
