{
  inputs,
  self,
  moduleWithSystem,
  ...
}:
{
  flake.nixosModules.falken = moduleWithSystem (
    { ... }:
    { ... }:
    {
      imports =
        with self.nixosModules;
        [
          android
          laptop
          qmk
          single-disk
          smartd
          tilde
          workstation
          yubikey
        ]
        ++ [
          inputs.nixos-hardware.nixosModules.framework-13-7040-amd
          inputs.superkey.nixosModules.falken
        ];

      config = {
        # Host name:
        networking.hostName = "falken";

        # Hardware configuration:
        services.fwupd.enable = true;
        hardware.cpu.amd.updateMicrocode = true;

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        boot.kernelModules = [ "kvm-amd" ];
        boot.extraModulePackages = [ ];
        boot.initrd.kernelModules = [ "dm-snapshot" ];
        boot.initrd.availableKernelModules = [
          "xhci_pci"
          "thunderbolt"
          "nvme"
          "usb_storage"
          "sd_mod"
        ];

        # Disk configuration:
        tilde.hardware.disks.single = {
          enable = true;
          device = "/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b4a5375fd";
          swap.enable = true;
          swap.size = 72;
        };

        # Keyboard:
        services.kmonad = {
          enable = true;

          keyboards.internal = {
            device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
            config = builtins.readFile ../../support/keyboard/us_60.kbd;

            defcfg = {
              enable = true;
              fallthrough = true;
              compose.key = "compose";
            };
          };
        };

        home-manager.users.pjones = {
          imports = with self.homeModules; [
            mail
            mbsync
            msmtp
            mu
          ];

          config = {
            tilde.programs.ssh.keysDir = "~/keys/ssh";
          };
        };
      };
    }
  );

  # flake.nixosConfigurations.falken = inputs.nixpkgs.lib.nixosSystem {
  #   modules = self.lib.nixos.modulesForHost "falken" "x86_64-linux";
  # };

  perSystem = self.lib.nixos.checkHost "falken";

  # TODO: Bring in NixOS hardware
  # What else from Cassini can be brought into here?
}
