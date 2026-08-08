# runbook: bluetooth / AirPods

read `docs/known-constraints.md` first.

This laptop's AirPods path is load-bearing and easy to break by "cleanup".

## current intended state

| Piece | Value |
|---|---|
| AirPods MAC | `2C:32:6A:C1:8D:00` |
| Audio adapter | **USB CSR** `00:1A:7D:DA:71:13` (keep up) |
| Disabled adapter | **internal Realtek/Lite-On** `F4:6A:DD:26:38:42` (keep down) |
| bluetoothd | `-P headset` (HFP plugin **off**) |
| User helper | `airpods-fix` |

Owned by:

```text
modules/bluetooth.nix
home/scripts/airpods-fix
home/sf.nix   # wraps airpods-fix into home.packages
```

Bonds are **per controller**. AirPods must be paired on the CSR. A bond only on Realtek is the wrong place.

## why it breaks (short)

Layers stack. `bluetoothctl Connected: yes` is not success.

| Failure | What you see | Real cause |
|---|---|---|
| Wrong adapter | flaky connect, deaf scan | Realtek up / CSR down or default wrong |
| HFP race | `avdtp … Permission denied (13)` | headset plugin still loaded |
| Bad bond | ACL up, no sink; `LinkKey Type=0` | encryption never completes |
| No encryption | hci con shows `AUTH` without `ENCRYPT` | same as bad bond / desynced key |
| No endpoints | 0 `MediaEndpoint` in bluez | wireplumber down / not registered |
| No transport | 0 `MediaTransport1` | A2DP never negotiated |
| Ghost ACL | `ACL Connection Already Exists` | controller thinks link still up |
| Phone/iCloud | `AuthenticationCanceled` | buds still owned by phone |

**Success criteria (all of them):**

1. Paired + Trusted + Connected on **CSR**
2. `hcitool con` shows `AUTH ENCRYPT` (not AUTH alone)
3. Bond file `LinkKey Type=` is `4` or `7` (not `0`)
4. `MediaTransport1` count ≥ 1
5. `wpctl status` shows AirPods sink; preferably default

## safe inspection

```bash
airpods-fix --status

bluetoothctl list
bluetoothctl info 2C:32:6A:C1:8D:00
hciconfig -a
hcitool con
wpctl status
systemctl --no-pager status bluetooth
systemctl --user status pipewire wireplumber pipewire-pulse
tr '\0' ' ' < /proc/$(pgrep -n bluetoothd)/cmdline; echo
journalctl -b -u bluetooth --since '15 min ago' --no-pager
```

Bond file (sudo):

```bash
sudo cat /var/lib/bluetooth/00:1A:7D:DA:71:13/2C:32:6A:C1:8D:00/info
# Type=4 or 7 is good. Type=0 means re-pair.
```

## recovery order (do not thrash)

### 1) Soft reconnect (first try)

Buds in ears:

```bash
airpods-fix
```

### 2) Reset stack

```bash
airpods-fix --reset-bt
```

### 3) Full re-pair (only if bond is bad / encryption fails)

On the AirPods:

1. Both buds in case, lid open
2. Hold back button ~15s until **amber then white flashing** (factory reset if they keep cancelling)
3. On phone: forget device if iCloud keeps stealing them
4. Leave lid open, white flashing
5. Run:

```bash
airpods-fix --pair
```

6. When script says **in ears now**, put buds in
7. Confirm sink with `wpctl status` / sound

### 4) Manual one-shot pair (if script unavailable)

```bash
# ensure CSR up, Realtek down (module should do this)
bluetoothctl
# then in one session:
power on
agent NoInputNoOutput
default-agent
pairable on
scan on
# wait until AirPods Pro appears
pair 2C:32:6A:C1:8D:00
trust 2C:32:6A:C1:8D:00
scan off
# user: buds in ears
connect 2C:32:6A:C1:8D:00
```

Short-lived `bluetoothctl scan` clients get inquiry cancelled (~17ms) on this host. Hold scan open in one session.

### 5) USB reset of a deaf adapter (last resort)

Only if scan sees zero devices for a long inquiry:

```bash
# CSR is usually on bus1; Realtek internal on 3-2 — verify with lsusb/sysfs first
lsusb | grep -iE '0a12:0001|04ca:4000'
# authorized 0/1 on the correct usb device, then:
sudo systemctl restart bluetooth
systemctl --user restart wireplumber
```

## before changing bluetooth config

Confirm whether the user wants:

- normal maintenance of the **CSR AirPods path**
- retesting the internal Realtek controller
- DJI Mic Mini / HFP experiments
- a different USB dongle

These are different tasks. Do not conflate them.

### Do not

- Remove `-P headset` to "fix" a mic without an explicit dual-device plan
- Leave Realtek as default "because it's internal"
- Treat `Connected: yes` as audio working
- Loop connect/disconnect without checking encryption + transport
- Wipe the bond every attempt (only when Type=0 or encryption stuck)
- Make CSR and Realtek both fight as default

### DJI Mic Mini note

DJI advertises Handsfree (`0000111e`). With `-P headset`, profile connect may fail. Re-enabling HFP can kill AirPods A2DP. Prefer:

- separate good USB adapter for DJI, or
- on-demand experiment with explicit rollback to `-P headset`

## after changing bluetooth config

```bash
cd /home/sf/nixos-config
git add modules/bluetooth.nix home/scripts/airpods-fix home/sf.nix docs/runbooks/bluetooth.md docs/known-constraints.md
nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#laptop

bluetoothctl list
hciconfig -a
tr '\0' ' ' < /proc/$(pgrep -n bluetoothd)/cmdline; echo
# expect: bluetoothd ... -P headset
# expect: CSR powered, Realtek down

airpods-fix --status
wpctl status
```

If AirPods connect but no sink appears, fix transport/endpoints before touching volume or default-sink UI.
