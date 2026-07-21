{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
let
  host = "kilgrave";
  system = "x86_64-linux";
in
{
  flake.nixosModules.${host} = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      imports =
        with self.nixosModules;
        [
          basic
          prometheus-node
          tilde
        ]
        ++ [
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.nixos-hardware.nixosModules.common-pc
        ];

      config = {
        networking.hostName = host;

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

        swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

        fileSystems = {
          # Root disk: /dev/nvme0n1p2
          "/" = {
            device = "/dev/disk/by-label/root";
            fsType = "ext4";
          };

          # /var/lib RAID:
          "/var/lib" = {
            device = "/dev/md/var-lib";
            fsType = "ext4";
          };

          # Home RAID:
          "/home" = {
            device = "/dev/md/home";
            fsType = "ext4";
          };
        };

        home-manager.users.pjones = {
          imports = with self.homeModules; [
            basic
            syncthing
          ];
        };
      };
    }
  );

  flake.nixosConfigurations.${host} = inputs.nixpkgs.lib.nixosSystem {
    modules = self.lib.nixos.hostModules host system;
  };

  flake.checks.${system} = self.lib.nixos.mkCheck {
    inherit host;
    withDisko = false;
  };
}
