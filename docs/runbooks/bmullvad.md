# bmullvad (browser-only Mullvad)

same verbs as `mullvad`, scoped to `cloak` and `mullvad-browser`. not the host, not firefox, not system `mullvad`.

## commands

```bash
bmullvad connect [-w]
bmullvad disconnect
bmullvad reconnect
bmullvad status [-v] [-j]
bmullvad relay get
bmullvad relay list
bmullvad relay update
bmullvad relay set location nl ams
bmullvad relay set location nl-ams-wg-004
cloak
mullvad-browser
```

`up` / `down` still work as aliases for connect / disconnect. fuzzel **Cloak** is `cloak`. there is no `mullvad-sg`.

default location if you have never set one: **Amsterdam** (`nl ams`). identity (wg private key + tunnel address) stays in `~/.config/wireguard/sg.conf`; the peer is chosen from Mullvad's public relay list.

## behavior

- `connect` starts netns `vpn-sg` with the current peer. host routes, tailscale, and system `mullvad` stay put.
- `cloak` / `mullvad-browser` join `vpn-sg` at launch if it is up. if it is down, they start on clearnet.
- already-open windows stay on the net they were born on. `connect` does not yank a clearnet Cloak; quit and launch again.
- `relay set location` writes `~/.config/bmullvad/{location,peer}` and reconnects if already up.
- CDP remains `127.0.0.1:9222` on the **host** loopback even when chrome is inside `vpn-sg`. do not Funnel 9222.

## files

```text
modules/vpn-netns.nix          # netns + host:9222 forwarder + sudo helpers
home/scripts/bmullvad          # CLI
home/scripts/bmullvad-join     # launch-time join
home/scripts/cloak
home/sf.nix
~/.config/wireguard/sg.conf    # account identity (PrivateKey, Address)
~/.config/bmullvad/location    # constraint
~/.config/bmullvad/peer        # resolved endpoint + pubkey
```

## verify

```bash
command -v bmullvad cloak mullvad-browser
command -v mullvad-sg && echo FAIL || echo 'mullvad-sg gone'
bmullvad status
bmullvad relay set location nl ams
bmullvad connect -w
bmullvad status -v
```

runtime proof needs a switch on sfnix. do not switch `#laptop` from sfub.
