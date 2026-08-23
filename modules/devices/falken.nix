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
          { ... }:
          {
            imports = with self.homeModules; [
              mail
              mbsync
              monitors
              msmtp
              mu
            ];

            config =
              let
                # niri msg outputs|grep Output
                monitors = {
                  internal = {
                    connector = "eDP-1";
                    width = 2256;
                    height = 1504;
                    scale = 1.4;
                  };

                  home = {
                    connector.serial = "17ZP7HA000040";
                    width = 2560;
                    height = 1440;
                  };

                  work = {
                    connector.serial = "S8LMQS000351";
                    width = 2560;
                    height = 1440;
                  };

                  conference = {
                    connector.model = "V864Q";
                    width = 1920;
                    height = 1200;
                    rate = 59.95;
                  };
                };

                layouts = [
                  {
                    name = "home";
                    args = "-n -p ${monitors.internal.connector}";
                    outputs = [
                      "home"
                      "internal"
                    ];
                  }
                  {
                    name = "work";
                    args = "-dn -p ${monitors.internal.connector}";
                    outputs = [
                      "work"
                      "internal"
                    ];
                  }
                  {
                    name = "conference";
                    args = "-P -p ${monitors.internal.connector}";
                    outputs = [
                      "internal"
                      "conference"
                    ];
                  }
                  {
                    name = "others";
                    args = "-P -p ${monitors.internal.connector}";
                    outputs = [
                      "internal"
                      "*"
                    ];
                  }
                  {
                    name = "internal";
                    args = "-p ${monitors.internal.connector}";
                    outputs = [ "internal" ];
                  }
                ];
              in
              {
                tilde.programs.ssh.keysDir = "~/keys/ssh";
                tilde.wayland.primaryOutput = monitors.internal.connector;
                tilde.monitors = monitors;
                tilde.layouts = layouts;

                wayland.windowManager.niri.settings = {
                  output = [
                    {
                      _args = [ monitors.internal.connector ];
                      mode = with monitors.internal; "${toString width}x${toString height}";
                      scale = monitors.internal.scale;

                      layout = {
                        # Smaller windows are hard to use:
                        default-column-width.proportion = 0.5;
                      };
                    }

                  ];
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
