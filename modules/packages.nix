{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    tailscale
    mosh
    tmux
    pciutils
    usbutils
    mullvad
  ];

  # HTTP/3 (QUIC) never completes on this laptop (UDP/443 timeout to
  # GitHub/Cloudflare/Google). github.githubassets.com advertises h3 via
  # alt-svc, so Firefox waits ~5s then falls back — unstyled GitHub chrome.
  # No global IPv6 route; AAAA lookups still stall Happy Eyeballs.
  # Prefetch was user-toggled off; GitHub's many asset hosts then serialize DNS.
  # Locked via enterprise policy (survives profile recreation). Rebuild to apply.
  programs.firefox = {
    enable = true;
    preferences = {
      "network.http.http3.enable" = false;
      "network.dns.disableIPv6" = true;
      "network.dns.disablePrefetch" = false;
      "network.protocol-handler.expose.roblox-player" = true;
      "network.protocol-handler.expose.roblox" = true;
      "network.protocol-handler.external.roblox-player" = true;
      "network.protocol-handler.external.roblox" = true;
    };
    policies = {
      # Play on roblox.com -> xdg-open -> Sober. not the windows installer.
      Handlers = {
        schemes = {
          roblox-player = {
            action = "useSystemDefault";
          };
          roblox = {
            action = "useSystemDefault";
          };
        };
      };
    };
  };
}
