# cloak (sfnix daily browser + CDP)

Cloak is a **shared headed Chromium** on sfnix. You click around; agents attach to the same process over localhost CDP. This is **not** the browser-ops lease plane.

## vs `kind: scratch`

`scratch` is a **browser-ops profile kind**: a throwaway/stable *anonymous Cloak worker* with its own user-data-dir, CDP port in 9300–9399, tab leases, one writer per tab. Registering `scratch` does **not** mean "laptop daily driver."

This setup:

| | |
|---|---|
| process | one Cloak window you launch from fuzzel ("Cloak") or `cloak` |
| profile | `~/.cloakbrowser/profile` (cookies, logins, yours) |
| CDP | `127.0.0.1:9222` every launch (host loopback, even when chrome is in vpn-browser) |
| agents | attach, scrape the tab you're on, click — same cookies |
| firefox | stays human-only (`firefox-session`) |
| vpn | joins `bmullvad` at launch if that connection is up; otherwise clearnet |

Do not `--remote-debugging-port` on Firefox. Do not Funnel 9222. See `docs/runbooks/bmullvad.md`.

## launch

fuzzel → **Cloak**, or `cloak`. Binary: `~/.cloakbrowser/chromium-146.0.7680.177.5/chrome` (generic ELF via `programs.nix-ld`). Do **not** wrap with `steam-run` (missing nss/nspr). SwiftShader (`--use-angle=swiftshader`) because Mesa `libEGL.so.1` is not on nix-ld.

Extensions load from `~/.cloakbrowser/extensions/*/manifest.json` at launch.
`gemini-mcp-autoallow` clicks **Allow** on gemini.google.com MCP cards
(`.remy-confirmation-card` / "Let Gemini use"). relaunch cloak to pick up a new folder.

## session and first-run

`--restore-last-session` is passed explicitly so the previous window's tabs come
back every launch. Chromium's own `session.restore_on_startup` pref is separate
and not relied on; the flag is the contract.

`--no-first-run`, `--no-default-browser-check` and
`--disable-search-engine-choice-screen` suppress the onboarding surfaces a
fresh profile would otherwise show.

`ChromeWhatsNewUI` and `PrivacySandboxSettings4` are disabled so the browser
does not open its own promo tab on a version bump.

extensions that open their own page on `onInstalled` still do it once per
install; that is the extension's choice, not cloak's. Dark Reader's is its
release-notes page and it is one tab, once — if it becomes noise, its own
options page has the setting.

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
then a **new** shell so `cloak` is the store copy without `steam-run`.

`bmullvad connect` while Cloak is already on clearnet does not move that window. quit and `cloak` again to join.
