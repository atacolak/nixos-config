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
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      NS="vpn-sg"

      ${pkgs.iproute2}/bin/ip netns del "$NS" 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip netns add "$NS"

      ${pkgs.iproute2}/bin/ip link add wg-sg type wireguard
      ${pkgs.iproute2}/bin/ip link set wg-sg netns "$NS"

      ${pkgs.iproute2}/bin/ip netns exec "$NS" \
        ${pkgs.wireguard-tools}/bin/wg setconf wg-sg "${wgConf}"

      ${pkgs.iproute2}/bin/ip -n "$NS" addr add 10.74.234.10/32 dev wg-sg
      ${pkgs.iproute2}/bin/ip -n "$NS" addr add fc00:bbbb:bbbb:bb01::b:ea09/128 dev wg-sg
      ${pkgs.iproute2}/bin/ip -n "$NS" link set wg-sg up
      ${pkgs.iproute2}/bin/ip -n "$NS" route add default dev wg-sg
      ${pkgs.iproute2}/bin/ip -n "$NS" link set lo up

      mkdir -p /etc/netns/"$NS"
      echo 'nameserver 10.64.0.1' > /etc/netns/"$NS"/resolv.conf
    '';
    preStop = ''
      ${pkgs.iproute2}/bin/ip netns del vpn-sg 2>/dev/null || true
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
