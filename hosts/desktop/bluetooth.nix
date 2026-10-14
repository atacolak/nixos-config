{ ... }:

{
  # desktop bluetooth is not the laptop CSR/Realtek airpods policy.
  # live adapters: IMC onboard + TP-Link UB500. Keychron K8 Pro is on hci0.
  # do not import hosts/laptop/bluetooth.nix.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
