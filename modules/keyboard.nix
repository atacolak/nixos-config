{ ... }:

{
  # Caps is the main modifier on this machine:
  # - hold / single press: Super/Meta
  # - quick double tap: real Caps Lock
  # This mirrors the old Ubuntu desktop kmonad setup, but targets the laptop's
  # internal keyboard directly and works under Wayland/Hyprland.
  services.kmonad = {
    enable = true;

    keyboards.internal = {
      device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";

      defcfg = {
        enable = true;
        fallthrough = true;
      };

      config = ''
        (defsrc
          caps
        )

        (defalias
          capdance (tap-next-release 300 caps lmet)
        )

        (deflayer base
          @capdance
        )
      '';
    };
  };
}
