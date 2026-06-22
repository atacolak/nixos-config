{ config, pkgs, ... }:

{
  home.username = "sf";
  home.homeDirectory = "/home/sf";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  xdg.enable = true;

  home.packages = with pkgs; [
    ripgrep
    fd
    fzf
    bat
    eza
    tree
    htop
    btop
    jq
    unzip

    kitty
    waybar
    fuzzel
    mako
    hyprpaper
    hyprlock
    hypridle
    brightnessctl
    playerctl
    networkmanagerapplet
    pavucontrol
    wl-clipboard
    grim
    slurp
    nautilus
  ];

  programs.bash.enable = true;

  home.shellAliases = {
    ata-herdr = "herdr --remote sf@ata-ubuntu";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };

      "ata-ubuntu" = {
        User = "sf";
        HostName = "ata-ubuntu";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };
    };
  };

  xdg.configFile."herdr/config.toml".text = ''
    [advanced]
    scrollback_limit_bytes = 2000000

    [ui]
    mouse_capture = false
    mouse_scroll_lines = 2

    [ui.toast]
    delivery = "off"
  '';

  home.sessionVariables.HERDR_CONFIG_PATH = "${config.xdg.configHome}/herdr/config.toml";
}
