{ ... }:
{
  flake.nixosModules.single-disk =
    { config, lib, ... }:
    let
      cfg = config.tilde.hardware.disks.single;
    in
    {
      options.tilde.hardware.disks.single = {
        enable = lib.mkEnableOption ''
          Automatically configure a single-disk system with LUKS
          encryption and an optional swap partition.
        '';

        device = lib.mkOption {
          type = lib.types.str;
          description = "Path to the device file for this disk.";
        };

        swap = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Configure a swap partition.";
          };

          size = lib.mkOption {
            type = lib.types.ints.unsigned;
            default = 72;
            description = "Size in GB";
          };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          disko.devices = {
            disk.main = {
              device = cfg.device;
              type = "disk";
              content = {
                type = "gpt";
                partitions = {
                  boot = {
                    name = "ESP";
                    size = "512M";
                    type = "EF00";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                    };
                  };
                  luks = {
                    size = "100%";
                    content = {
                      type = "luks";
                      name = "encrypted";
                      passwordFile = "/tmp/luks.key";
                      settings.allowDiscards = true;
                      content = {
                        type = "lvm_pv";
                        vg = "pool";
                      };
                    };
                  };
                };
              };
            };

            lvm_vg = {
              pool = {
                type = "lvm_vg";
                lvs = {
                  root = {
                    size = "100%FREE";
                    content = {
                      type = "filesystem";
                      format = "ext4";
                      mountpoint = "/";
                      mountOptions = [
                        "defaults"
                        "x-systemd.device-timeout=infinity"
                      ];
                    };
                  };
                };
              };
            };
          };
        })

        (lib.mkIf (cfg.enable && cfg.swap.enable) {
          disko.devices.lvm_vg.pool.lvs.swap = {
            size = "${toString cfg.swap.size}G";
            content = {
              type = "swap";
              discardPolicy = "both";
              resumeDevice = true;
            };
          };
        })
      ];
    };
}
