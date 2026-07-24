{ config, pkgs, lib, ... }:

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

  audioInputToggle = pkgs.writeScriptBin "audio-input-toggle" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./scripts/audio-input-toggle}
  '';

  modernMinimalUiSounds = pkgs.callPackage ../pkgs/modern-minimal-ui-sounds.nix { };

  handy = pkgs.callPackage ../pkgs/handy.nix { };

  swayKillClean = pkgs.writeScriptBin "sway-kill-clean" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./scripts/sway-kill-clean}
  '';

  handySwayStart = pkgs.writeShellApplication {
    name = "handy-sway-start";
    runtimeInputs = [ pkgs.jq handy ];
    text = builtins.readFile ./scripts/handy-sway-start;
  };

  swayWmutil = pkgs.writeScriptBin "wmutil" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./scripts/wmutil}
  '';

  swayI3Msg = pkgs.writeShellApplication {
    name = "i3-msg";
    runtimeInputs = with pkgs; [ sway ];
    text = builtins.readFile ./scripts/i3-msg;
  };

  swayI3Lock = pkgs.writeShellApplication {
    name = "i3-lock";
    runtimeInputs = with pkgs; [ swaylock ];
    text = builtins.readFile ./scripts/i3-lock;
  };

  firefoxSession = pkgs.writeShellApplication {
    name = "firefox-session";
    runtimeInputs = with pkgs; [ firefox ];
    text = builtins.readFile ./scripts/firefox-session;
  };

  i3CycleTabSibling = pkgs.writeScriptBin "i3-cycle-tab-sibling" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./scripts/i3-cycle-tab-sibling}
  '';

  i3SpawnHere = pkgs.writeScriptBin "i3-spawn-here" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./scripts/i3-spawn-here}
  '';

  i3TreePath = pkgs.writeScriptBin "i3-tree-path" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./scripts/i3-tree-path}
  '';

  i3PruneFirefoxPrograms = pkgs.writeScriptBin "i3-resurrect-prune-firefox-programs" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./scripts/i3-resurrect-prune-firefox-programs}
  '';

  i3SaveDefaultWorkspaces = pkgs.writeShellApplication {
    name = "i3-save-default-workspaces";
    runtimeInputs = [ pkgs.i3-resurrect i3PruneFirefoxPrograms ];
    text = builtins.readFile ./scripts/i3-save-default-workspaces;
  };

  i3RestoreDefaultWorkspaces = pkgs.writeShellApplication {
    name = "i3-restore-default-workspaces";
    runtimeInputs = [ pkgs.i3-resurrect i3PruneFirefoxPrograms ];
    text = builtins.readFile ./scripts/i3-restore-default-workspaces;
  };

  i3ResurrectSaveWorkspace = pkgs.writeShellApplication {
    name = "i3-resurrect-save-workspace-confirm";
    runtimeInputs = with pkgs; [ i3-resurrect i3PruneFirefoxPrograms libnotify libcanberra-gtk3 pulseaudio alsa-utils ];
    text = builtins.readFile ./scripts/i3-resurrect-save-workspace-confirm;
  };

  i3ResurrectRestoreWorkspace = pkgs.writeShellApplication {
    name = "i3-resurrect-restore-workspace-confirm";
    runtimeInputs = with pkgs; [ i3-resurrect i3PruneFirefoxPrograms libnotify libcanberra-gtk3 pulseaudio alsa-utils ];
    text = builtins.readFile ./scripts/i3-resurrect-restore-workspace-confirm;
  };

  hibernateConfirm = pkgs.writeShellApplication {
    name = "hibernate-confirm";
    runtimeInputs = with pkgs; [ libnotify libcanberra-gtk3 ];
    text = builtins.readFile ./scripts/hibernate-confirm;
  };

  # serve a remote html file over tailscale — starts an ephemeral http server on the remote host
  rhtml = pkgs.writeShellApplication {
    name = "rhtml";
    runtimeInputs = with pkgs; [ openssh curl xdg-utils python3 ];
    text = builtins.readFile ./scripts/rhtml;
  };
  # launch mullvad-browser through Singapore WireGuard tunnel (netns isolation)
  mullvadSg = pkgs.writeShellApplication {
    name = "mullvad-sg";
    runtimeInputs = with pkgs; [ iproute2 ];
    text = builtins.readFile ./scripts/mullvad-sg;
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
    ffmpeg
    yt-dlp
    mpv
    cava
    unzip
    zip
    _7zz

    kitty
    fuzzel
    swaynotificationcenter
    xdg-utils
    i3status-rust
    swayidle
    swaylock
    sway-contrib.grimshot
    bibata-cursors
    papirus-icon-theme
    gnome-themes-extra
    modernMinimalUiSounds
    libcanberra-gtk3
    sound-theme-freedesktop
    handy
    handySwayStart
    brightnessctl
    playerctl
    networkmanagerapplet
    pavucontrol
    pulseaudio
    libnotify
    wl-clipboard
    wtype
    wlsunset
    grim
    slurp
    thunar
    blueman
    bluetui
    vscode
    obsidian

    jetbrains-mono
    fira-code

    kittyShade
    taskTerminal
    audioToggle
    audioInputToggle
    swayKillClean

    swayWmutil
    swayI3Msg
    swayI3Lock
    firefoxSession
    ungoogled-chromium
    wireguard-tools
    mullvad-browser
    i3CycleTabSibling
    i3SpawnHere
    i3TreePath
    i3PruneFirefoxPrograms
    i3SaveDefaultWorkspaces
    i3RestoreDefaultWorkspaces
    i3ResurrectSaveWorkspace
    i3ResurrectRestoreWorkspace
    hibernateConfirm
    rhtml
    mullvadSg
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
    ata-herdr = "herdr --remote sf@ata-ubuntu --remote-keybindings server";
    # clipboard sync over tailscale — push/pull between sfnix and ata-ubuntu
    clip-push = "wl-paste | ssh ata-ubuntu \"DISPLAY=:1 xclip -i -selection clipboard\"";
    clip-pull = "ssh ata-ubuntu \"DISPLAY=:1 xclip -o -selection clipboard 2>/dev/null\" | wl-copy";
  };

  home.sessionVariables = {
    HERDR_CONFIG_PATH = "${config.xdg.configHome}/herdr/config.toml";
    EDITOR = "nvim";
    VISUAL = "nvim";
    NIXOS_OZONE_WL = "1";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    BROWSER = "firefox";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_DESKTOP = "sway";
    GTK_THEME = "Adwaita:dark";
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

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];

      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
      "x-scheme-handler/terminal" = [ "kitty.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "text/xml" = [ "firefox.desktop" ];
      "application/xhtml+xml" = [ "firefox.desktop" ];
      "application/xml" = [ "firefox.desktop" ];
      "application/pdf" = [ "firefox.desktop" ];
    };
    associations.added = {
      "inode/directory" = [ "thunar.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
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

  xdg.configFile."fuzzel/fuzzel.ini".source = ./files/fuzzel/fuzzel.ini;
  xdg.configFile."swaync/config.json".source = ./files/swaync/config.json;
  xdg.configFile."swaync/style.css".source = ./files/swaync/style.css;

  xdg.configFile."icons/default/index.theme".text = ''
    [Icon Theme]
    Inherits=Bibata-Modern-Ice
  '';

  xdg.configFile."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Adwaita-dark
    gtk-application-prefer-dark-theme=1
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=Bibata-Modern-Ice
    gtk-cursor-theme-size=24
    gtk-sound-theme-name=modern-minimal-ui-sounds
    gtk-enable-event-sounds=1
    gtk-enable-input-feedback-sounds=1
  '';

  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Adwaita-dark
    gtk-application-prefer-dark-theme=1
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=Bibata-Modern-Ice
    gtk-cursor-theme-size=24
    gtk-sound-theme-name=modern-minimal-ui-sounds
    gtk-enable-event-sounds=1
    gtk-enable-input-feedback-sounds=1
  '';

  xdg.configFile."sway/config".source = ./files/sway/config;
  xdg.configFile."sway/wallpaper.jpg".source = ./files/sway/wallpaper.jpg;
  xdg.configFile."i3status-rust/config.toml".source = ./files/i3status-rust/config.toml;

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;


    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
      ms-python.python
      ms-python.vscode-pylance
      ms-python.debugpy
      ms-python.vscode-python-envs
      ms-vscode.makefile-tools
      ziglang.vscode-zig
      mechatroner.rainbow-csv
      zhuangtongfa.material-theme
      ms-azuretools.vscode-containers
      ms-vscode-remote.remote-ssh
    ];

    };
  };
  # Place VS Code settings/keybindings as one-time templates.
  # They're only written if the target file doesn't exist yet,
  # so user changes survive rebuilds.
  home.activation.placeVscodeTemplates = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    "${pkgs.bash}/bin/bash ${../files/vscode/place-templates.sh} ${../files/vscode/vscode_settings.json} ${../files/vscode/vscode_keybindings.json}"
  );

  # custom atacol theme (flexoki dark blue + vscode dark+ syntax)
  home.file = {
    ".vscode/extensions/local.atacol-0.0.1/package.json".source = ./extensions/atacol/package.json;
    ".vscode/extensions/local.atacol-0.0.1/themes/flexoki-dark-blue-dark-plus-color-theme.json".source = ./extensions/atacol/themes/flexoki-dark-blue-dark-plus-color-theme.json;
  };

  dconf.settings = {
    "desktop/ibus/general/hotkey" = {
      triggers = "@as []";
    };
  };
}
