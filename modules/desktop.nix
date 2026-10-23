{ pkgs, ... }:

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
  services.desktopManager.plasma6.enable = true;

  # The upstream sway.desktop says `Exec=sway`, and the display-manager unit
  # runs with a narrow store PATH, so put sway's bin on that PATH instead of
  # shipping a duplicate session with an absolute Exec.
  systemd.services.display-manager.path = [ pkgs.sway ];

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
    wlr = {
      enable = true;

      # The portal runs under a unit whose PATH is a minimal store closure (no
      # fuzzel), and its built-in chooser chain skips the slurp/simple chooser
      # for window requests. Without an absolute-path dmenu chooser, Window
      # Capture in OBS and window screenshare in Firefox silently fail to list
      # sources.
      settings.screencast = {
        chooser_type = "dmenu";
        chooser_cmd = "${pkgs.fuzzel}/bin/fuzzel -d -l 20 -p 'Select source to share: '";
      };
    };
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.sway.default = pkgs.lib.mkForce [ "wlr" "gtk" ];
  };

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
