## 2026-07-03: VS Code — hybrid declarative/manual management

**Extensions**: nix-managed exclusively. `mutableExtensionsDir` is NOT set.

**Settings and keybindings**: one-time templates placed by home-manager activation. after initial placement, vscode owns the files — user changes survive rebuilds. to reset to defaults, delete the file and rebuild.

**Why this split**: `mutableExtensionsDir = true` causes VS Code to take ownership of `~/.vscode/extensions/`, ignoring `.extensions-immutable.json` and marking all nix-managed extension symlinks as "removed" on every launch. extensions must be one system or the other — we chose nix.

Settings/keybindings managed as nix symlinks (`userSettings` / `keybindings` in home-manager) are read-only at runtime, so every "don't warn me again" click or config tweak fails silently. templates fix this: write once, then the user owns them.

**How to add an extension**:
1. Check if it's in nixpkgs: `nix eval nixpkgs#vscode-extensions.<publisher>.<name>.name`
2. Add to `programs.vscode.profiles.default.extensions` in `home/sf.nix`
3. `sudo nixos-rebuild switch --flake .#laptop`
4. Restart VS Code

**How to add a non-nixpkgs extension**: use `pkgs.vscode-utils.buildVscodeMarketplaceExtension` in a let block, or place files via `home.file`.

**How to reset settings/keybindings to defaults**: delete `~/.config/Code/User/settings.json` and/or `~/.config/Code/User/keybindings.json`, then rebuild. the activation script places fresh templates if the files don't exist.

**Where templates live**: `files/vscode/vscode_settings.json`, `files/vscode/vscode_keybindings.json`, `files/vscode/place-templates.sh`. the activation script runs after `writeBoundary` in home-manager activation ordering.

**Rebuild command** (unchanged): `sudo nixos-rebuild switch --flake /home/sf/nixos-config#laptop`
