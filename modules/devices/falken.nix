{
  inputs,
  self,
  moduleWithSystem,
  ...
}:
let
  host = "falken";
  system = "x86_64-linux";
in
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

        home-manager.users.pjones =
          { config, ... }:
          {
            imports = with self.homeModules; [
              mail
              mbsync
              msmtp
              mu
            ];

            config =
              let
                # wayland-info | grep wl_output -A2
                # niri msg outputs|grep Output
                monitors = {
                  builtin = "eDP-1";
                  external = "DP-3"; # Left side of laptop.
                  home = "PNP(AOC) Q27B3MA 17ZP7HA000040";
                  work.desk = "S8LMQS000351";
                  work.conference_room = "NEC Corporation V864Q 89000404NB";
                };
              in
              {
                tilde.programs.ssh.keysDir = "~/keys/ssh";
                tilde.wayland.primaryOutput = monitors.builtin;

                wayland.windowManager.niri.settings = {
                  output = [
                    {
                      _args = [ monitors.builtin ];
                      mode = "2256x1504";
                      scale = 1.4;
                      position._props.x = 2560;
                      position._props.y = 489;

                      layout = {
                        # Smaller windows are hard to use:
                        default-column-width.proportion = 0.5;
                      };
                    }

                    {
                      _args = [ monitors.work.desk ];
                      mode = "2560x1440";
                      scale = 1.0;
                      position._props.x = 0;
                      position._props.y = 123;
                    }

                    {
                      _args = [ monitors.work.conference_room ];
                      mode = "1920x1200@59.95";
                      scale = 1.0;
                      position._props.x = 4171;
                      position._props.y = 363;
                    }

                    {
                      _args = [ monitors.home ];
                      mode = "2560x1440";
                      scale = 1.0;
                      position._props.x = 0;
                      position._props.y = 123;
                    }
                  ];
                };

                programs.waybar.settings.main = {
                  output = [ monitors.external ];
                };

                services.wpaperd.settings = {
                  ${monitors.external}.path = config.tilde.programs.wpaperd.primaryWallpaperDirectory;
                };
              };
          };
      };
    }
  );

  flake.nixosConfigurations.${host} = inputs.nixpkgs.lib.nixosSystem {
    modules = self.lib.nixos.hostModules host system;
  };

  flake.checks.${system} = self.lib.nixos.mkCheck { inherit host; };
}
