{ config, pkgs, lib, inputs, osConfig, ... }:

let
  # yt-dlp breaks whenever a site changes, so its version must not be frozen by
  # the nixpkgs rev in flake.lock. The flake input "yt-dlp" points at upstream's
  # release asset URL (releases/latest/download/yt-dlp.tar.gz), which always
  # resolves to the newest stable release, and nixrebuild runs
  # `nix flake update yt-dlp` before every eval. So every rebuild re-resolves the
  # latest release: unchanged release => same narHash => lock untouched => no
  # rebuild; new release => new src => only this package rebuilds. No version and
  # no hash are written here, so an upstream release needs no edit.
  ytDlpVersion =
    let
      line = lib.findFirst (l: lib.hasPrefix "__version__ = " l) ""
        (lib.splitString "\n" (builtins.readFile "${inputs.yt-dlp}/yt_dlp/version.py"));
    in
    builtins.head (builtins.match "['\"]([^'\"]+)['\"]" (lib.removePrefix "__version__ = " line));

  # Since 2026.08 upstream's pyproject installs the completions, the manpage and
  # the docs *into the wheel* via [tool.hatch.build.targets.wheel.shared-data].
  # nixpkgs already generates and installs all of those itself, so the duplicate
  # copy makes fixupPhase's moveToOutput fail:
  #   mv: cannot overwrite '...-doc/share/doc/yt_dlp': Directory not empty
  # Neutralise that section so only nixpkgs' copies exist. Guarded, so it stays a
  # no-op if upstream ever drops shared-data again.
  ytDlp = pkgs.yt-dlp.overrideAttrs (old: {
    version = ytDlpVersion;
    src = inputs.yt-dlp;
    postPatch =
      (old.postPatch or "")
      + ''
        if grep -q 'tool.hatch.build.targets.wheel.shared-data' pyproject.toml; then
          substituteInPlace pyproject.toml --replace-fail "[tool.hatch.build.targets.wheel.shared-data]" "[tool.hatch.build.targets.wheel.no-shared-data]"
        fi
      '';
  });

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

  # handy: pkgs.handy from nixpkgs (drops AppImage requireFile)

  swayKillClean = pkgs.writeScriptBin "sway-kill-clean" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./scripts/sway-kill-clean}
  '';

  handySwayStart = pkgs.writeShellApplication {
    name = "handy-sway-start";
    runtimeInputs = [ pkgs.jq pkgs.handy ];
    text = builtins.readFile ./scripts/handy-sway-start;
  };

  shotToClipboard = pkgs.writeShellApplication {
    name = "shot-to-clipboard";
    runtimeInputs = with pkgs; [ cosmic-screenshot wl-clipboard coreutils findutils libnotify ];
    text = builtins.readFile ./scripts/shot-to-clipboard;
  };

  cosmicSnapshot = pkgs.writeShellApplication {
    name = "cosmic-snapshot";
    runtimeInputs = with pkgs; [ rsync git coreutils ];
    text = builtins.readFile ./scripts/cosmic-snapshot;
  };

  cosmicRestore = pkgs.writeShellApplication {
    name = "cosmic-restore";
    runtimeInputs = with pkgs; [ rsync coreutils ];
    text = builtins.readFile ./scripts/cosmic-restore;
  };

  screenCapture = pkgs.writeShellApplication {
    name = "screen-capture";
    runtimeInputs = with pkgs; [ cosmic-screenshot coreutils findutils systemd gnused ];
    text = builtins.readFile ./scripts/screen-capture;
  };

  snip = pkgs.writeShellApplication {
    name = "snip";
    runtimeInputs = with pkgs; [ sway-contrib.grimshot grim slurp wl-clipboard libnotify ];
    text = builtins.readFile ./scripts/snip;
  };

  shotSaveArea = pkgs.writeShellApplication {
    name = "shot-save-area";
    runtimeInputs = with pkgs; [ grim slurp zenity libnotify coreutils glib ];
    text = builtins.readFile ./scripts/shot-save-area;
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

  viture120hz = pkgs.writeShellApplication {
    name = "viture-120hz";
    runtimeInputs = with pkgs; [ jq sway ];
    text = builtins.readFile ./scripts/viture-120hz;
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

  nixRebuild = pkgs.writeShellApplication {
    name = "nixrebuild";
    runtimeInputs = with pkgs; [ git nix nixos-rebuild systemd hostname coreutils ];
    text = builtins.readFile ./scripts/nixrebuild;
  };

  nixRollback = pkgs.writeShellApplication {
    name = "nixrollback";
    runtimeInputs = with pkgs; [ nix nixos-rebuild systemd coreutils ];
    text = builtins.readFile ./scripts/nixrollback;
  };

  bmullvadJoin = pkgs.writeShellApplication {
    name = "bmullvad-join";
    runtimeInputs = with pkgs; [ coreutils ];
    text = builtins.readFile ./scripts/bmullvad-join;
  };

  bmullvad = pkgs.writeShellApplication {
    name = "bmullvad";
    excludeShellChecks = [ "SC2016" ];
    runtimeInputs = with pkgs; [ coreutils wireguard-tools curl jq ];
    text = ''
      WG=${pkgs.wireguard-tools}/bin/wg
      CURL=${lib.getExe pkgs.curl}
      JQ=${lib.getExe pkgs.jq}
    '' + builtins.readFile ./scripts/bmullvad;
  };

  cloakJanitor = pkgs.writeShellApplication {
    name = "cloak-janitor";
    # SC2016: the jq program is deliberately single-quoted; $pat is jq's.
    excludeShellChecks = [ "SC2016" ];
    runtimeInputs = with pkgs; [ curl jq coreutils ];
    text = builtins.readFile ./scripts/cloak-janitor;
  };

  cloak = pkgs.writeShellApplication {
    name = "cloak";
    runtimeInputs = [ bmullvadJoin cloakJanitor pkgs.findutils pkgs.coreutils pkgs.util-linux ];
    text = builtins.readFile ./scripts/cloak;
  };

  # The extension's toolbar icon is the exit country's flag. Chromium refuses
  # SVG in createImageBitmap, so the flags have to arrive as PNGs. Rasterise
  # them here rather than committing 200 binaries: flags/ holds 50 small SVGs
  # and this turns them into the 200 files background.js fetches.
  bmullvadRegionFlags = pkgs.runCommand "bmullvad-region-flags" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p $out
    for svg in ${./files/cloak-extensions/bmullvad-region/flags}/*.svg; do
      cc=$(basename "$svg" .svg)
      for size in 16 32 48 128; do
        # -resize WxH^ then -extent = cover: fill the square and crop the
        # overflow. Without the ^ this letterboxes the 4:3 flag inside a
        # square and the icon ends up with transparent bars.
        magick -background none -density 384 "$svg" \
          -resize "''${size}x''${size}^" \
          -gravity center -extent "''${size}x''${size}" \
          "$out/$cc-$size.png"
      done
    done
  '';

  cloakExocortex = pkgs.writeShellApplication {
    name = "cloak-exocortex";
    runtimeInputs = with pkgs; [ coreutils util-linux inetutils ];
    text = builtins.readFile ./scripts/cloak-exocortex;
  };

  cloakExocortexLogin = pkgs.writeShellApplication {
    name = "cloak-exocortex-login";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      export LD_LIBRARY_PATH="${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    '' + builtins.readFile ./scripts/cloak-exocortex-login;
  };

  # Tern is an imperative binary at ~/.local/opt/tern that runs through the
  # nix-ld shim. COSMIC's app launcher sanitizes the environment it hands to
  # desktop entries and drops NIX_LD_LIBRARY_PATH, which sends tern's renderer
  # to a bundled software path that draws its backdrop blur as a solid frost.
  # The wrapper re-exports the nix-ld library set plus the system Vulkan
  # loader so launcher-spawned and terminal-spawned tern behave identically.
  tern = pkgs.writeShellApplication {
    name = "tern";
    text = builtins.readFile ./scripts/tern;
  };

  # Chrome native messaging host for the Mullvad-region extension.
  # The extension cannot exec anything, so this is its only way out.
  bmullvadNativeHost = pkgs.writeScriptBin "bmullvad-native-host" (
    ''
      #!${pkgs.python3}/bin/python3
      import os
      os.environ.setdefault("BMULLVAD", "${bmullvad}/bin/bmullvad")
    '' + builtins.readFile ./scripts/bmullvad-native-host
  );

  # Extension id is pinned by the `key` in the extension's manifest.json, so
  # this origin stays valid across rebuilds.
  nativeHostManifest = builtins.toJSON {
    name = "net.colak.bmullvad";
    description = "Mullvad region control for the browser-only tunnel";
    path = "${bmullvadNativeHost}/bin/bmullvad-native-host";
    type = "stdio";
    allowed_origins = [ "chrome-extension://phkfkngoigbagfncjaaocnkmnhcilkne/" ];
  };

  mullvadBrowser = pkgs.writeShellApplication {
    name = "mullvad-browser";
    runtimeInputs = [ bmullvadJoin ];
    text = ''
      exec bmullvad-join -- ${lib.getExe pkgs.mullvad-browser} "$@"
    '';
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

  # recover AirPods A2DP on CSR without thrashing (see docs/runbooks/bluetooth.md)
  airpodsFix = pkgs.writeShellApplication {
    name = "airpods-fix";
    runtimeInputs = with pkgs; [ bluez bluez-tools wireplumber pulseaudio dbus systemd coreutils gnugrep gnused gawk ];
    text = builtins.readFile ./scripts/airpods-fix;
  };

  # Roblox player via Sober (android APK runtime). not wine.
  launchRoblox = pkgs.writeShellApplication {
    name = "launch-roblox";
    runtimeInputs = with pkgs; [ flatpak coreutils ];
    text = builtins.readFile ./scripts/launch-roblox;
  };

  # Cloak loads extensions from ~/.cloakbrowser/extensions at launch, so it
  # wants a plain directory. The source tree ships the flag SVGs; the PNGs the
  # worker actually fetches are generated above, so the two are composed here
  # into one store path.
  bmullvadRegionExt = pkgs.runCommand "bmullvad-region" { } ''
    cp -r ${./files/cloak-extensions/bmullvad-region} $out
    chmod -R u+w $out
    rm -rf $out/flags
    cp -r ${bmullvadRegionFlags} $out/flags
  '';

  soberUpdate = pkgs.writeShellApplication {
    name = "sober-update";
    runtimeInputs = with pkgs; [ flatpak coreutils gnugrep gawk libnotify ];
    text = builtins.readFile ./scripts/sober-update;
  };
in
{
  imports = [ ./observeos-kwin-tree.nix ];

  home.username = "sf";
  home.homeDirectory = "/home/sf";
  home.sessionPath = lib.optionals (osConfig.networking.hostName == "sfnix") [ "/home/sf/.local/bin" ];
  home.stateVersion = "26.05";

  systemd.user.services.viture-120hz = {
    Unit = {
      Description = "Force 1920x1200@120Hz on VITURE glasses outputs";
      PartOf = [ "sway-session.target" ];
      After = [ "sway-session.target" ];
      StartLimitIntervalSec = 0;
    };
    Service = {
      ExecStart = "${viture120hz}/bin/viture-120hz";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = { WantedBy = [ "sway-session.target" ]; };
  };

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
    ytDlp
    mpv
    cava
    unzip
    zip
    _7zz
    gh

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
    pkgs.handy
    handySwayStart
    shotToClipboard
    screenCapture
    cosmicSnapshot
    cosmicRestore
    snip
    shotSaveArea
    satty
    loupe
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
    obs-studio

    nerd-fonts.jetbrains-mono
    fira-code

    kittyShade
    taskTerminal
    audioToggle
    audioInputToggle
    swayKillClean
    viture120hz
    nixRebuild
    nixRollback

    swayWmutil
    swayI3Msg
    swayI3Lock
    firefoxSession
    cloak
    steam-run
    ungoogled-chromium
    wireguard-tools
    nwg-displays
    calibre
    mullvadBrowser
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
    bmullvad
    bmullvadNativeHost
  ] ++ lib.optionals (osConfig.networking.hostName == "sfnix") [ airpodsFix cloakExocortex cloakExocortexLogin tern ] ++ [
    launchRoblox
    soberUpdate
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
    ata-herdr = "herdr --remote sf@sfub --remote-keybindings server";
    # clipboard sync over tailscale — push/pull between sfnix and ata-ubuntu
    clip-push = "wl-paste | ssh sfub \"DISPLAY=:1 xclip -i -selection clipboard\"";
    clip-pull = "ssh sfub \"DISPLAY=:1 xclip -o -selection clipboard 2>/dev/null\" | wl-copy";
  };

  home.sessionVariables = {
    HERDR_CONFIG_PATH = "${config.xdg.configHome}/herdr/config.toml";
    EDITOR = "nvim";
    VISUAL = "nvim";
    NIXOS_OZONE_WL = "1";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    BROWSER = "firefox";
    PI_OFFLINE = "1";
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

      "sfub ata-ubuntu" = {
        User = "sf";
        HostName = "sfub";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      "sfpix pixel-8-pro" = {
        User = "root";
        HostName = "pixel-8-pro";
        Port = 2222;
        IdentityFile = "~/.ssh/sfpix_agent";
        IdentitiesOnly = true;
        PreferredAuthentications = "publickey";
        ServerAliveInterval = 20;
        ServerAliveCountMax = 3;
        ConnectTimeout = 10;
      };

      "sfiph iphone-14" = {
        User = "sf";
        HostName = "iphone-14";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ConnectTimeout = 8;
      };
    };
  };

  xdg.desktopEntries.cloak = {
    name = "Cloak";
    genericName = "Web Browser";
    comment = "Stealth Chromium with localhost CDP for agents";
    exec = "${cloak}/bin/cloak %U";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
    settings = {
      Keywords = "cloak;chromium;cdp;";
    };
  };

  xdg.desktopEntries.cloak-exocortex = lib.mkIf (osConfig.networking.hostName == "sfnix") {
    name = "Exocortex in Cloak";
    genericName = "Isolated Workspace Browser";
    comment = "Dedicated persistent Exocortex profile with sandbox and native rendering";
    exec = "${cloakExocortex}/bin/cloak-exocortex %U";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    settings = {
      Keywords = "exocortex;cloak;workspace;";
    };
  };

  # These deliberately share desktop-file ids with the entries tern installs
  # into ~/.local/share/applications so the nix-ld-carrying wrapper wins.
  # A tern self-update rewrites its copies; the next rebuild heals ours.
  xdg.desktopEntries."so.stencil.tern" = lib.mkIf (osConfig.networking.hostName == "sfnix") {
    name = "Tern";
    exec = "${tern}/bin/tern";
    terminal = false;
    categories = [ "System" "TerminalEmulator" ];
    icon = "so.stencil.tern";
    settings = {
      StartupWMClass = "so.stencil.tern";
    };
  };

  xdg.desktopEntries."so.stencil.tern.open" = lib.mkIf (osConfig.networking.hostName == "sfnix") {
    name = "Tern";
    exec = "${tern}/bin/tern --open-file %f";
    terminal = false;
    noDisplay = true;
    mimeType = [
      "text/plain"
      "text/markdown"
      "text/x-source"
      "image/png"
      "image/jpeg"
      "image/gif"
      "image/webp"
      "image/svg+xml"
      "application/x-sqbpro"
      "application/x-ipynb+json"
      "application/vnd.sqlite3"
      "application/x-sqlite3"
      "application/vnd.apache.parquet"
      "text/csv"
      "text/tab-separated-values"
      "inode/directory"
    ];
    settings = {
      StartupWMClass = "so.stencil.tern";
    };
  };

  xdg.desktopEntries."so.stencil.tern.url" = lib.mkIf (osConfig.networking.hostName == "sfnix") {
    name = "Tern";
    exec = "${tern}/bin/tern --open-url %u";
    terminal = false;
    noDisplay = true;
    mimeType = [ "x-scheme-handler/tern" ];
    settings = {
      StartupWMClass = "so.stencil.tern";
    };
  };

  xdg.desktopEntries.mullvad-browser = {
    name = "Mullvad Browser";
    genericName = "Web Browser";
    comment = "Mullvad Browser (joins bmullvad when up)";
    exec = "${mullvadBrowser}/bin/mullvad-browser %U";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
    settings = {
      Keywords = "mullvad;browser;vpn;";
    };
  };

  xdg.desktopEntries.sober-update = {
    name = "Update Sober";
    genericName = "Roblox updater";
    comment = "Update Sober (Roblox) from Flathub";
    exec = "${soberUpdate}/bin/sober-update";
    terminal = true;
    categories = [ "Game" ];
    settings = {
      Keywords = "sober;roblox;update;flatpak;";
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


      "image/png" = [ "org.gnome.loupe.desktop" ];
      "image/jpeg" = [ "org.gnome.loupe.desktop" ];
      "image/gif" = [ "org.gnome.loupe.desktop" ];
      "image/webp" = [ "org.gnome.loupe.desktop" ];
      "image/svg+xml" = [ "org.gnome.loupe.desktop" ];
      "text/plain" = [ "vim.desktop" ];
      "text/x-markdown" = [ "vim.desktop" ];
      "text/x-csrc" = [ "vim.desktop" ];
      "text/x-c++src" = [ "vim.desktop" ];
      "text/x-python" = [ "vim.desktop" ];
      "text/x-sh" = [ "vim.desktop" ];
      "application/x-shellscript" = [ "vim.desktop" ];
      "application/json" = [ "vim.desktop" ];

      "x-scheme-handler/roblox" = [ "org.vinegarhq.Sober.desktop" ];
      "x-scheme-handler/roblox-player" = [ "org.vinegarhq.Sober.desktop" ];
    };
    associations.added = {
      "inode/directory" = [ "thunar.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];

      "text/plain" = [ "vim.desktop" ];
      "text/x-markdown" = [ "vim.desktop" ];
      "text/x-csrc" = [ "vim.desktop" ];
      "text/x-c++src" = [ "vim.desktop" ];
      "application/x-shellscript" = [ "vim.desktop" ];

      "x-scheme-handler/roblox" = [ "org.vinegarhq.Sober.desktop" ];
      "x-scheme-handler/roblox-player" = [ "org.vinegarhq.Sober.desktop" ];
    };
  };
  xdg.configFile."xfce4/helpers.rc".text = "TerminalEmulator=kitty
";

  xdg.configFile."herdr/config.toml".source = ./files/herdr/config.toml;

  xdg.configFile."autostart/Handy.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Handy
    Exec=/etc/profiles/per-user/sf/bin/handy --start-hidden
    OnlyShowIn=COSMIC;
  '';

  # COSMIC GUI settings live in ~/.config/cosmic and are owned by the GUI.
  # `cosmic-snapshot` commits them into home/files/cosmic-live on demand;
  # `cosmic-restore` reapplies the committed state. Do not xdg.configFile them.

  xdg.configFile."autostart/blueman.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Blueman Applet
    Icon=blueman
    Exec=blueman-applet
    Terminal=false
    NotShowIn=COSMIC;
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
  xdg.configFile."sway/config-fx".source = ./files/sway/config-fx;
  xdg.configFile."sway/wallpaper.jpg".source = ./files/sway/wallpaper.jpg;
  xdg.configFile."i3status-rust/config.toml".source = ./files/i3status-rust/config.toml;

  home.file.".cloakbrowser/extensions/bmullvad-region".source = bmullvadRegionExt;

  # Cloak runs with --user-data-dir=~/.cloakbrowser/profile, and Chromium
  # resolves native messaging hosts against that dir before the XDG location.
  # Both are written so the extension resolves the host either way.
  home.file.".cloakbrowser/profile/NativeMessagingHosts/net.colak.bmullvad.json".text = nativeHostManifest;
  home.file.".config/chromium/NativeMessagingHosts/net.colak.bmullvad.json".text = nativeHostManifest;

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
