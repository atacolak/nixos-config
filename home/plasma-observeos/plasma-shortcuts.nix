{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.observeos.plasmaShortcuts;
  generated = ./generated;
  helper = ./helpers/kde_cycle_or_run.py;
  blocked = ./generated/observeos-blocked;
in
{
  options.observeos.plasmaShortcuts.enable = lib.mkEnableOption "observeOS isolated plasma shortcut profile; default false; never enable on the live Sway user";

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "kde-cycle-or-run";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          exec ${pkgs.python3}/bin/python3 ${helper} "$@"
        '';
      })
      (pkgs.writeShellApplication {
        name = "observeos-blocked";
        text = ''
          exec ${blocked} "$@"
        '';
      })
    ];

    xdg.configFile."kglobalshortcutsrc" = {
      source = generated + "/kglobalshortcutsrc";
    };

    xdg.dataFile = lib.mapAttrs' (name: _: {
      name = "applications/${name}";
      value.source = generated + "/applications/${name}";
    }) (builtins.readDir (generated + "/applications"));
  };
}
