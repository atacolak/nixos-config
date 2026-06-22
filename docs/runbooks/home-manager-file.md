# runbook: home-manager managed file

use this when adding or changing a user config file under `~/.config`.

## existing managed files

source files usually live under:

```text
home/files/
```

wiring lives in:

```text
home/sf.nix
```

## add a config file

1. add the source file under `home/files/<app>/...`.
2. add an `xdg.configFile` entry in `home/sf.nix`.
3. `git add` the new file before nix eval.
4. eval and switch.
5. verify the runtime symlink with `readlink`.

example verification:

```bash
readlink ~/.config/<app>/<file>
```

## add a helper script

1. put the script under `home/scripts/`.
2. wrap it in `home/sf.nix` with `pkgs.writeShellApplication` when possible.
3. add runtime dependencies in `runtimeInputs`.
4. add the wrapped package to `home.packages`.
5. `git add` the script before nix eval.
6. verify with `command -v <script-name>` after switch.

avoid relying on ambient `$PATH` inside scripts. declare runtime inputs.
