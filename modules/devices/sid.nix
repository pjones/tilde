{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
let
  host = "sid";
  system = "x86_64-linux";
in
{
  flake.nixosModules.${host} = moduleWithSystem (
    { pkgs, ... }:
    { lib, ... }:
    {
      imports =
        with self.nixosModules;
        [
          basic
          prometheus-node
          single-disk
          smartd
          tilde
        ]
        ++ [
          inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
        ];

      config = {
        # Host name:
        networking.hostName = host;

        # Hardware configuration:
        services.fwupd.enable = true;
        hardware.cpu.intel.updateMicrocode = true;

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        boot.initrd.kernelModules = [ "dm-snapshot" ];
        boot.kernelModules = [ "kvm-intel" ];
        boot.extraModulePackages = [ ];
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
          device = "/dev/disk/by-id/nvme-eui.0025385b1190134c";
          swap.enable = true;
          swap.size = 72;
        };

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

        # Ignore all lid switch events:
        services.logind.settings.Login =
          let
            ignore = lib.mkForce "ignore";
            keys = [
              "HandleLidSwitch"
              "HandleLidSwitchDocked"
              "HandleLidSwitchExternalPower"
            ];
          in
          builtins.listToAttrs (
            map (key: {
              name = key;
              value = ignore;
            }) keys
          );

        tilde = {
          crontab = {
            image-import = {
              user = "pjones";
              schedule = "*-*-* 00/4:15:00";
              path = [ pkgs.pjones.image-scripts ];
              script = "image-import";
            };
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

  flake.checks.${system} = self.lib.nixos.mkCheck { inherit host; };
}
