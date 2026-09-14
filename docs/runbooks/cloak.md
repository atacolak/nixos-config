# cloak (sfnix daily browser + CDP)

Cloak is a **shared headed Chromium** on sfnix. You click around; agents attach to the same process over localhost CDP. This is **not** the browser-ops lease plane.

## vs `kind: scratch`

`scratch` is a **browser-ops profile kind**: a throwaway/stable *anonymous Cloak worker* with its own user-data-dir, CDP port in 9300–9399, tab leases, one writer per tab. Registering `scratch` does **not** mean "laptop daily driver."

This setup:

| | |
|---|---|
| process | one Cloak window you launch from fuzzel ("Cloak") |
| profile | `~/.cloakbrowser/profile` (cookies, logins, yours) |
| CDP | `127.0.0.1:9222` every launch |
| agents | attach, scrape the tab you're on, click — same cookies |
| firefox | stays human-only (`firefox-session`) |

Do not `--remote-debugging-port` on Firefox. Do not Funnel 9222.

## launch

fuzzel → **Cloak**, or `cloak-session`. Binary: `~/.cloakbrowser/chromium-146.0.7680.177.5/chrome` (generic ELF via `programs.nix-ld`). Do **not** wrap with `steam-run` (missing nss/nspr). SwiftShader (`--use-angle=swiftshader`) because Mesa `libEGL.so.1` is not on nix-ld.

Prove CDP:

```bash
curl -sS http://127.0.0.1:9222/json/version
curl -sS http://127.0.0.1:9222/json/list
```

Window title is `Chromium` (`app_id` `chromium-browser`).

## control from sfUB

CDP stays on sfnix loopback. From sfUB:

```bash
ssh -N -o ExitOnForwardFailure=yes -L 127.0.0.1:9222:127.0.0.1:9222 sfnix
```

Then attach (unmanaged — no tab leases):

```bash
cd ~/workspace/browser-ops
python3 -m daemon.main --worker sfnix-daily --cdp-url http://127.0.0.1:9222 --unmanaged --no-events
```

`unmanaged` skips lease checks so the daemon will drive whichever page you have focused. Two clients on one chrome **will** race. That's the point of this surface.

## rebuild

`sudo nixos-rebuild switch --flake ~/nixos-config#laptop`
then a **new** shell so `cloak-session` is the store copy without `steam-run`.
