{ ... }:

{
  # daemon + cli. account login is runtime (`mullvad account login`), never nix.
  services.mullvad-vpn.enable = true;
}
