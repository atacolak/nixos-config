# runbook: add package

first decide who needs the package.

## user package for sf

edit:

```text
home/sf.nix
```

add to `home.packages`.

use this for cli/gui tools used by `sf`, including desktop tools and helper-script runtime dependencies when the helper is user-facing.

## system package

edit:

```text
modules/packages.nix
```

use this for tools needed system-wide, by root, or during system administration.

do not dump user apps here by default.

## local package not in nixpkgs

create or edit:

```text
pkgs/<name>.nix
```

then consume it from a module or `home/sf.nix`.

## verify

```bash
nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#laptop
command -v <package-or-command>
```
