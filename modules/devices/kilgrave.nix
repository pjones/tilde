{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
{
  flake.nixosModules.kilgrave = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      imports =
        with self.nixosModules;
        [
          basic
          tilde
        ]
        ++ [
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.nixos-hardware.nixosModules.common-pc
        ];

      config = {
        networking.hostName = "kilgrave";

        # Use the GRUB boot loader (on the root disk).
        boot.loader.grub.enable = true;
        boot.loader.grub.device = "/dev/nvme0n1";

        # Hardware.
        nix.settings.max-jobs = 8;
        hardware.cpu.intel.updateMicrocode = true;
        boot.extraModulePackages = [ pkgs.linuxPackages.gasket ];
        boot.kernelModules = [
          "kvm-intel"
          "gasket"
        ];
        boot.initrd.availableKernelModules = [
          "xhci_pci"
          "ahci"
          "nvme"
          "usb_storage"
          "usbhid"
          "sd_mod"
        ];

        home-manager.users.pjones = {
          imports = with self.homeModules; [
            basic
            syncthing
          ];
        };
      };
    }
  );

  perSystem = self.lib.nixos.checkHost "kilgrave";
}
