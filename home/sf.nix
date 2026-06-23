{ config, pkgs, ... }:

let
  kittyShade = pkgs.writeShellApplication {
    name = "kitty-shade";
    runtimeInputs = with pkgs; [ kitty python3 ];
    text = builtins.readFile ./scripts/kitty-shade;
  };

  taskTerminal = pkgs.writeShellApplication {
    name = "task-terminal";
    runtimeInputs = [ kittyShade pkgs.kitty pkgs.tmux ];
    text = builtins.readFile ./scripts/task-terminal;
  };

  audioToggle = pkgs.writeShellApplication {
    name = "audio-toggle";
    runtimeInputs = with pkgs; [ wireplumber gnugrep gnused libnotify ];
    text = builtins.readFile ./scripts/audio-toggle;
  };

  hyprCycleOrRun = pkgs.writeShellApplication {
    name = "hypr-cycle-or-run";
    runtimeInputs = with pkgs; [ hyprland jq util-linux ];
    text = builtins.readFile ./scripts/hypr-cycle-or-run;
  };

  audioInputToggle = pkgs.writeScriptBin "audio-input-toggle" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./scripts/audio-input-toggle}
  '';

  touchpadToggle = pkgs.writeShellApplication {
    name = "touchpad-toggle";
    runtimeInputs = with pkgs; [ hyprland libnotify ];
    text = builtins.readFile ./scripts/touchpad-toggle;
  };

  hyprGroupToggle = pkgs.writeShellApplication {
    name = "hypr-group-toggle";
    runtimeInputs = with pkgs; [ hyprland jq ];
    text = builtins.readFile ./scripts/hypr-group-toggle;
  };

  hyprGroupStart = pkgs.writeShellApplication {
    name = "hypr-group-start";
    runtimeInputs = with pkgs; [ hyprland jq ];
    text = builtins.readFile ./scripts/hypr-group-start;
  };

  hyprKillActive = pkgs.writeShellApplication {
    name = "hypr-kill-active";
    runtimeInputs = with pkgs; [ hyprland jq coreutils ];
    text = builtins.readFile ./scripts/hypr-kill-active;
  };
in
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
    pulseaudio
    libnotify
    wl-clipboard
    grim
    slurp
    nautilus
    blueman
    vscode

    jetbrains-mono
    fira-code

    kittyShade
    taskTerminal
    audioToggle
    audioInputToggle
    hyprCycleOrRun
    touchpadToggle
    hyprGroupToggle
    hyprGroupStart
    hyprKillActive
  ];

  programs.bash.enable = true;

  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    prefix = "C-a";
    escapeTime = 0;
    historyLimit = 100000;
    extraConfig = ''
      set -s copy-command 'wl-copy'
      bind-key -T copy-mode Enter send-keys -X stop-selection
      bind-key -T copy-mode-vi Enter send-keys -X stop-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-no-clear
      bind-key -T copy-mode MouseDragEnd1Pane send-keys -X stop-selection
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X stop-selection
      bind-key -T copy-mode DoubleClick1Pane select-pane \; send-keys -X select-word \; send-keys -X stop-selection
      bind-key -T copy-mode-vi DoubleClick1Pane select-pane \; send-keys -X select-word \; send-keys -X stop-selection
      bind-key -T copy-mode TripleClick1Pane select-pane \; send-keys -X select-line \; send-keys -X stop-selection
      bind-key -T copy-mode-vi TripleClick1Pane select-pane \; send-keys -X select-line \; send-keys -X stop-selection

      unbind C-b
      bind C-a send-prefix

      bind | split-window -h
      bind - split-window -v

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      set -g default-terminal "screen-256color"
      set -g extended-keys on
    '';
  };

  home.shellAliases = {
    ata-herdr = "herdr --remote sf@ata-ubuntu";
  };

  home.sessionVariables = {
    HERDR_CONFIG_PATH = "${config.xdg.configHome}/herdr/config.toml";
    EDITOR = "nvim";
    VISUAL = "nvim";
    NIXOS_OZONE_WL = "1";
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
    onboarding = false

    [advanced]
    scrollback_limit_bytes = 2000000

    [theme]
    name = "one-dark"

    [ui]
    mouse_capture = false
    mouse_scroll_lines = 6
    agent_panel_scope = "all"
    show_agent_labels_on_pane_borders = true

    [ui.toast]
    delivery = "off"
  '';

  xdg.configFile."kitty/kitty.conf".source = ./files/kitty/kitty.conf;
  xdg.configFile."kitty/opacity.conf".source = ./files/kitty/opacity.conf;

  xdg.configFile."hypr/hyprland.conf".source = ./files/hypr/hyprland.conf;
  xdg.configFile."hypr/hyprpaper.conf".source = ./files/hypr/hyprpaper.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ./files/hypr/hyprlock.conf;
  xdg.configFile."hypr/hypridle.conf".source = ./files/hypr/hypridle.conf;
  xdg.configFile."hypr/wallpaper.jpg".source = ./files/hypr/wallpaper.jpg;

  xdg.configFile."fuzzel/fuzzel.ini".source = ./files/hypr/fuzzel.ini;
  xdg.configFile."mako/config".source = ./files/hypr/mako.conf;
  xdg.configFile."waybar/config".source = ./files/waybar/config;
  xdg.configFile."waybar/style.css".source = ./files/waybar/style.css;
}
