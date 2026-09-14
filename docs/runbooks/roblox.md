# runbook: roblox / sober

sfnix does not run the windows Roblox client. Hyperion killed
grapejuice / vinegar / proton in 2024. the live path is **Sober**
(`org.vinegarhq.Sober`) from Flathub: android APK runtime.

## ownership

- machine: `modules/flatpak.nix` enables the flatpak service and
  declares Sober via nix-flatpak.
- flake input: `nix-flatpak` in `flake.nix`.
- user launcher: `home/scripts/launch-roblox`, wrapped in `home/sf.nix`.
- mime: `x-scheme-handler/roblox-player` → `org.vinegarhq.Sober.desktop`
  so website Play buttons skip in-app captcha.
- input devices: `services.flatpak.overrides."org.vinegarhq.Sober".Context.devices = [ "input" ]`
  (also applied live as a user override). without this Sober pops
  "Permission Update Required".

do not add a wine prefix under `~/Games/roblox`. logs only.

## launch

```bash
launch-roblox
# or
flatpak run org.vinegarhq.Sober
```

fuzzel: type **Sober** or **Roblox**. `$mod+space` is rebound to
`launch-fuzzel` so the frozen sway login env still sees the
flatpak share dir.

first launch downloads the official APK + x86_64 split inside the
sandbox. that is expected and needs network.

## login

in-app login hits Roblox FunCaptcha. Sober's webview shows
"verifying you're not a bot" and never finishes. known sober bug,
not a local freeze. do **not** sit on that spinner.

workaround: log in on roblox.com in firefox, then click Play on a
game. that opens `roblox-player://` into Sober.

## do not

- wine / proton / grapejuice / vinegar for player
- treat this as `~/Games/<name>/prefix`
- nvidia-specific launcher env (this laptop is AMD Barcelo)
- copy sfub's `DISPLAY=:1` remap; sfnix is sway/wayland

## verify

```bash
command -v flatpak
command -v launch-roblox
flatpak info org.vinegarhq.Sober
xdg-mime query default x-scheme-handler/roblox-player
flatpak override --show --user org.vinegarhq.Sober
# expected: devices=input;
```
