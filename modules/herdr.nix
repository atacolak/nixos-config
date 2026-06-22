{ pkgs, ... }:

let
  herdr = pkgs.callPackage ../pkgs/herdr.nix { };
in
{
  environment.systemPackages = [
    herdr
  ];
}
