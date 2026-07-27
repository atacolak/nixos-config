{ pkgs, ... }:

let
  swayI3Session = (pkgs.writeTextDir "share/wayland-sessions/sway-i3-port.desktop" ''
[Desktop Entry]
Name=Sway (i3 port)
Comment=i3-style Sway session managed by /home/sf/nixos-config
Exec=${pkgs.coreutils}/bin/env XDG_CURRENT_DESKTOP=sway XDG_SESSION_DESKTOP=sway NIXOS_OZONE_WL=1 ${pkgs.sway}/bin/sway
TryExec=${pkgs.sway}/bin/sway
Type=Application
DesktopNames=sway;wlroots
  '').overrideAttrs (_: {
    providedSessions = [ "sway-i3-port" ];
  });
in
{
  services.xserver = {
    enable = true;

    xkb = {
      layout = "au";
      variant = "";
    };
  };

  # Keep GDM as the greeter/login manager, but do not expose a GNOME desktop
  # session by default. Sway is the intended daily driver.
  services.displayManager.gdm.enable = true;

  # i3-on-wayland daily driver.
  programs.sway = {
    enable = true;
    xwayland.enable = true;
    extraPackages = with pkgs; [
      swayidle
      swaylock
      sway-contrib.grimshot
      xwayland-satellite
    ];
  };

  security.pam.services.swaylock = { };

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  services.gvfs.enable = true;
  services.tumbler.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.common.default = [ "wlr" "gtk" ];
  };

  # The upstream sway.desktop says `Exec=sway`. GDM on this host runs with a
  # narrow PATH, so expose a second explicit session with an absolute Exec.
  services.displayManager.sessionPackages = [ swayI3Session ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Thunar needs exo-open for "Open Terminal Here" and for launching
  # Terminal=true .desktop apps (vim, etc.).
  environment.systemPackages = [ pkgs.xfce.exo ];
}
