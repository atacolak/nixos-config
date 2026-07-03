# runbook: vs code

## add a nixpkgs extension

1. check availability:
```bash
nix eval nixpkgs#vscode-extensions.<publisher>.<name>.name
```

2. add to `home/sf.nix` under `programs.vscode.profiles.default.extensions`:
```nix
<publisher>.<name>
```

3. rebuild:
```bash
git add home/sf.nix  # if not already tracked
sudo nixos-rebuild switch --flake .#laptop
```

4. restart vs code

## add a non-nixpkgs extension (marketplace)

add a let binding in `home/sf.nix`:
```nix
let
  myExtension = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    name = "my-extension";
    publisher = "some-publisher";
    version = "1.2.3";
    sha256 = pkgs.lib.fakeSha256;
  };
in
```

first build will fail with the real sha256. replace `fakeSha256` with it, rebuild.

## reset settings or keybindings to defaults

```bash
rm ~/.config/Code/User/settings.json   # and/or
rm ~/.config/Code/User/keybindings.json
sudo nixos-rebuild switch --flake .#laptop
```

the activation script places fresh templates if the files don't exist.

## verify state

```bash
ls ~/.vscode/extensions/ | wc -l          # should be 10+ (extensions + atacol + json files)
ls -la ~/.config/Code/User/settings.json  # should be -rw-r--r--, NOT a symlink
[ ! -f ~/.vscode/extensions/.obsolete ] && echo 'clean'
```

## debugging: extensions not loading

1. check `~/.vscode/extensions/.extensions-immutable.json` exists and lists all extensions
2. check `mutableExtensionsDir` is NOT set in `home/sf.nix`
3. check `~/.vscode/extensions/.obsolete` does NOT exist (if it does, rm it and restart)
4. check vs code logs: `~/.config/Code/logs/<latest>/sharedprocess.log`
5. if all else fails, `rm -rf ~/.vscode/extensions/ && sudo nixos-rebuild switch --flake .#laptop`
