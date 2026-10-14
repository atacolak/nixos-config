{ ... }:

{
  users.users.sf = {
    isNormalUser = true;
    description = "sf";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXVjzykqW+f0NLTsjpA1r3Ha9wlrsJXofG//MXRmnvq dotfiles@sfUB"
    ];
  };
}
