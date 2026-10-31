{ pkgs, ... }:

let
  wgConf = "/home/sf/.config/wireguard/sg.conf";
  ns = "vpn-sg";

  ctl = pkgs.writeShellScript "bmullvad-ctl" ''
    set -euo pipefail
    case "''${1-}" in
      connect|up)
        ${pkgs.systemd}/bin/systemctl start vpn-netns
        ;;
      disconnect|down)
        ${pkgs.systemd}/bin/systemctl stop vpn-netns
        ;;
      reconnect)
        ${pkgs.systemd}/bin/systemctl stop vpn-netns || true
        ${pkgs.systemd}/bin/systemctl start vpn-netns
        ;;
      *)
        echo "bmullvad-ctl: usage: connect|disconnect|reconnect" >&2
        exit 2
        ;;
    esac
  '';

  nsExec = pkgs.writeShellScript "bmullvad-nsexec" ''
    set -euo pipefail
    exec ${pkgs.iproute2}/bin/ip netns exec ${ns} "$@"
  '';

  cdpConnect = pkgs.writeShellScript "bmullvad-cdp-connect" ''
    exec ${pkgs.iproute2}/bin/ip netns exec ${ns} ${pkgs.socat}/bin/socat STDIO TCP:127.0.0.1:9222,connect-timeout=1
  '';

  cdpForward = pkgs.writeShellScript "bmullvad-cdp-forward" ''
    exec ${pkgs.socat}/bin/socat TCP-LISTEN:9222,bind=127.0.0.1,reuseaddr,fork EXEC:${cdpConnect}
  '';
in
{
  # Browser-only Mullvad WireGuard. Does not touch host routing, Tailscale,
  # or system mullvad. Drive with `bmullvad connect` / `disconnect` / `relay`.
  systemd.services.vpn-netns = {
    description = "Browser-only Mullvad netns";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ iproute2 wireguard-tools gawk coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      NS="${ns}"
      CONF="${wgConf}"
      PEER="/home/sf/.config/bmullvad/peer"

      if [[ ! -f "$CONF" ]]; then
        echo "vpn-netns: missing $CONF" >&2
        exit 1
      fi

      PRIVKEY=$(awk '/^PrivateKey/ {sub(/^PrivateKey *= */, ""); print}' "$CONF")
      PUBKEY=$(awk '/^PublicKey/ {sub(/^PublicKey *= */, ""); print}' "$CONF")
      ENDPOINT=$(awk '/^Endpoint/ {sub(/^Endpoint *= */, ""); print}' "$CONF")
      ADDRS=$(awk '/^Address/ {sub(/^Address *= */, ""); print}' "$CONF")

      if [[ -f "$PEER" ]]; then
        PKEY=$(awk '/^PublicKey/ {sub(/^PublicKey *= */, ""); print}' "$PEER")
        PEND=$(awk '/^Endpoint/ {sub(/^Endpoint *= */, ""); print}' "$PEER")
        if [[ -n "$PKEY" && -n "$PEND" ]]; then
          PUBKEY="$PKEY"
          ENDPOINT="$PEND"
        fi
      fi
      ip netns del "$NS" 2>/dev/null || true
      ip netns add "$NS"

      ip link add wg-sg type wireguard
      ip link set wg-sg netns "$NS"

      printf '%s' "$PRIVKEY" | ip netns exec "$NS" wg set wg-sg private-key /dev/stdin
      ip netns exec "$NS" wg set wg-sg peer "$PUBKEY" \
        endpoint "$ENDPOINT" \
        allowed-ips 0.0.0.0/0,::0/0

      for addr in ''${ADDRS//,/ }; do
        ip -n "$NS" addr add "$addr" dev wg-sg
      done

      ip -n "$NS" link set wg-sg up
      ip -n "$NS" route add default dev wg-sg
      ip -n "$NS" link set lo up

      mkdir -p /etc/netns/"$NS"
      echo 'nameserver 10.64.0.1' > /etc/netns/"$NS"/resolv.conf
    '';
    preStop = ''
      ip netns del ${ns} 2>/dev/null || true
    '';
  };

  # Cloak CDP stays on the host loopback even when chrome is in vpn-sg.
  # bind 127.0.0.1 only — do not Funnel 9222.
  systemd.services.vpn-netns-cdp = {
    description = "Forward host 127.0.0.1:9222 into vpn-sg (Cloak CDP)";
    after = [ "vpn-netns.service" ];
    bindsTo = [ "vpn-netns.service" ];
    partOf = [ "vpn-netns.service" ];
    wantedBy = [ "vpn-netns.service" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "1s";
      ExecStart = cdpForward;
    };
  };

  environment.etc."bmullvad/ctl" = {
    source = ctl;
    mode = "0755";
  };
  environment.etc."bmullvad/nsexec" = {
    source = nsExec;
    mode = "0755";
  };

  security.sudo.extraRules = [
    {
      users = [ "sf" ];
      commands = [
        { command = "${ctl}"; options = [ "NOPASSWD" ]; }
        { command = "${nsExec}"; options = [ "NOPASSWD" ]; }
        { command = "/etc/bmullvad/ctl"; options = [ "NOPASSWD" ]; }
        { command = "/etc/bmullvad/nsexec"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
