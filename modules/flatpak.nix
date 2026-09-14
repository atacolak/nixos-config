{ ... }:

{
  # Sober (Roblox player) from Flathub. not wine.
  # Hyperion killed grapejuice/vinegar/proton in 2024.
  # see docs/runbooks/roblox.md.
  services.flatpak.enable = true;
  services.flatpak.packages = [
    "org.vinegarhq.Sober"
  ];

  # Sober prompts "Permission Update Required" for gamepad/input
  # unless devices=input is granted. live copy is also applied as a
  # user override at ~/.local/share/flatpak/overrides/org.vinegarhq.Sober
  services.flatpak.overrides."org.vinegarhq.Sober".Context.devices = [
    "input"
  ];
}
