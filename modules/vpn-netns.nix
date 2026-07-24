{ config, pkgs, ... }:

let
  wgConf = "/home/sf/.config/wireguard/sg.conf";
in
{
  # Create the VPN network namespace at boot
  systemd.services.vpn-netns = {
    description = "VPN network namespace (Singapore)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ iproute2 wireguard-tools gawk ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      NS="vpn-sg"
      CONF="${wgConf}"

      # Parse WireGuard config (handle both = and = with leading space)
      PRIVKEY=$(awk -F' *= *' '/^PrivateKey/ {print $2}' "$CONF")
      PUBKEY=$(awk -F' *= *' '/^PublicKey/ {print $2}' "$CONF")
      ENDPOINT=$(awk -F' *= *' '/^Endpoint/ {print $2}' "$CONF")
      ADDRS=$(awk -F' *= *' '/^Address/ {print $2}' "$CONF")

      ip netns del "$NS" 2>/dev/null || true
      ip netns add "$NS"

      ip link add wg-sg type wireguard
      ip link set wg-sg netns "$NS"

      # Configure WireGuard (low-level wg, not wg-quick)
      echo "$PRIVKEY" | ip netns exec "$NS" wg set wg-sg private-key /dev/stdin
      ip netns exec "$NS" wg set wg-sg peer "$PUBKEY" \
        endpoint "$ENDPOINT" \
        allowed-ips 0.0.0.0/0,::0/0

      # Add addresses and bring up
      for addr in ''${ADDRS//,/ }; do
        ip -n "$NS" addr add "$addr" dev wg-sg
      done

      ip -n "$NS" link set wg-sg up
      ip -n "$NS" route add default dev wg-sg
      ip -n "$NS" link set lo up

      # Per-namespace DNS (Mullvad internal resolver)
      mkdir -p /etc/netns/"$NS"
      echo 'nameserver 10.64.0.1' > /etc/netns/"$NS"/resolv.conf
    '';
    preStop = ''
      ip netns del vpn-sg 2>/dev/null || true
    '';
  };

  # Allow sf to exec into the VPN namespace without a password
  security.sudo.extraRules = [
    {
      users = [ "sf" ];
      commands = [
        {
          command = "${pkgs.iproute2}/bin/ip netns exec vpn-sg";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
