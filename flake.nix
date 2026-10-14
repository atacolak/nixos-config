{
  description = "ata nixos configs: sfnix laptop, sfub desktop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";

    # Upstream's own release tarball. It is a release *asset* behind
    # releases/latest/download/, so it always resolves to the newest stable
    # release, and it is not a flake. nixrebuild re-resolves this input before
    # every eval: that is how yt-dlp stays current without a nixpkgs bump and
    # without a hand-written version/hash in home/sf.nix.
    yt-dlp = {
      url = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.tar.gz";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, home-manager, nix-flatpak, ... }@inputs:
    let
      system = "x86_64-linux";

      mkNixos = host: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${host}/configuration.nix
          nix-flatpak.nixosModules.nix-flatpak
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.sf = import ./home/sf.nix;
          }
        ];
      };
    in
    {
      nixosConfigurations.laptop = mkNixos "laptop";
      nixosConfigurations.desktop = mkNixos "desktop";
    };
}
