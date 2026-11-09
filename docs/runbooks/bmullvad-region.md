# mullvad region (Cloak extension)

click the Mullvad toolbar icon to change where the browser-only tunnel exits,
or to drop it. searchable by country name or code (`nl`, `+se`), then a city.

this is **not** system `mullvad`. the host, firefox, tailscale and system
mullvad stay where they are. only processes inside `vpn-browser` move.

## what you see

- **icon**: the exit country's flag, cropped to fill the square. when the
  tunnel is down the icon is the desaturated Mullvad mark instead — no badge,
  no slash, the whole icon changes.
- **header**: `connected` (green) / `stale` (amber) / `disconnected` (red).
- **power button** left of the relay text: disconnects the browser tunnel.
  disabled when there is nothing to disconnect.

## what the switch actually does

`bmullvad relay set location` used to stop and start the `vpn-netns` unit. that
deletes the namespace, which kills every process inside it — including the
browser.

now the switch replaces the WireGuard peer **in place**:

- same `vpn-browser` namespace, same inode, same PIDs
- one `wg set ... peer <old> remove` then `wg set ... peer <new>`
- the browser never restarts and never loses its sockets

## why it feels instant

opening the popup paints from `chrome.storage.local` first and only then asks
the host. measured: ~70 ms warm vs ~260 ms when boot awaited the host.
the relay list is cached for 6 h, the last status is cached on every refresh.

## files

```text
home/files/cloak-extensions/bmullvad-region/   manifest, popup, background, icons
home/files/cloak-extensions/bmullvad-region/flags/   50 country SVGs (MIT)
home/scripts/bmullvad-native-host              chrome native messaging host
home/scripts/bmullvad                          `bmullvad ext` JSON protocol
home/sf.nix                                    rasterises flags, installs both, writes the manifest
```

the icons are generated, not committed. `flags/` holds one 4:3 SVG per exit
country; `sf.nix` rasterises each to 16/32/48/128 with ImageMagick and
overlays the result onto the extension directory. chromium will not decode SVG
in `createImageBitmap`, so the PNGs have to exist before the browser starts.

rasterising uses `-resize WxH^` (cover) and then `-extent`. without the `^`
the 4:3 flag is letterboxed inside a square and the icon gets transparent
bars. the worker also crops to the centre square when drawing, for the same
reason: a squashed flag is a wrong flag.

adding a country means dropping `<cc>.svg` into `flags/`. a missing flag is not
fatal — `flagIcon()` throws, `paint()` catches, the icon falls back to the mark.

the native messaging manifest must sit next to cloak's user-data-dir:

```text
~/.cloakbrowser/profile/NativeMessagingHosts/net.colak.bmullvad.json
```

chromium resolves hosts against `--user-data-dir` **before** the
XDG location, so that file is the one that matters.

the extension id `phkfkngoigbagfncjaaocnkmnhcilkne` is pinned by the `key`
in `manifest.json`, not by path, so it survives rebuilds.

## why it needs a native host

an extension cannot run a shell command. it sends one JSON line over chrome's
native messaging pipe, the host runs `bmullvad ext`, the answer comes back as
one JSON line. ops:

```text
list    -> { relays: [{cc, cn, cityCode, city}, ...] }
status  -> { state, relay, ip, city, country, cc }
set     -> { relay, state }        args: {cc} or {cc, city}
down    -> { state }
```

`state` is local-only (handshake age), so opening the popup never waits on the
network.

## verify

```bash
readlink ~/.cloakbrowser/extensions/bmullvad-region || ls -l ~/.cloakbrowser/extensions/bmullvad-region
jq -c . ~/.cloakbrowser/profile/NativeMessagingHosts/net.colak.bmullvad.json
echo '{"op":"status"}' | bmullvad ext
```

real proof needs cloak relaunched (extensions load at launch only). then click
the icon, pick a city, and confirm the exit moved:

```bash
sudo /etc/bmullvad/nsexec curl -fsS https://am.i.mullvad.net/json | jq -r '.ip+" "+.city'
```

## gotchas

- a browser launched on clearnet does not move when you switch. relaunch it.
- cloak must not see the extension as a bare store *directory symlink*:
  `find -type d` skips those. `sf.nix` installs the files individually, and
  `cloak` uses `find -L`.
- if `bmullvad status` says `stale`, the key may not be on the account:
  `bmullvad device check`, then `bmullvad device register`.
- do not `bmullvad reconnect` while a browser is in `vpn-browser`; reconnect
  recreates the namespace. use the extension.
