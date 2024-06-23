{ config, lib, ... }:

let
  cfg = config.tilde;
in
{
  options.tilde.graphical = {
    enable = lib.mkEnableOption "Graphical environment";

    flavor = lib.mkOption {
      type = lib.types.enum [ "wayland" ];
      default = "wayland";
      description = "The type of graphical environment to use";
    };
  };

  config = lib.mkMerge [

    ############################################################################
    # All graphical types:
    (lib.mkIf cfg.graphical.enable {
      tilde.workstation.enable = true;

      # Propagate some settings into home-manager:
      home-manager.users.${cfg.username} = { ... }: {
        tilde.graphical.enable = true;
      };
    })

    ############################################################################
    # Wayland:
    (lib.mkIf (cfg.graphical.enable && cfg.graphical.flavor == "wayland") {
      superkey.enable = true;

      # Propagate some settings into home-manager:
      home-manager.users.${cfg.username} = { ... }: {
        superkey.enable = true;
      };
    })
  ];
}
