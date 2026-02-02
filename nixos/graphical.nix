{
  config,
  lib,
  pkgs,
  ...
}:

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
      # Graphics implies workstation:
      tilde.workstation.enable = true;

      # Block application network access by default:
      services.opensnitch = {
        enable = true;
        rules = {
          systemd-timesyncd = {
            created = "2026-02-02T15:41:27.730107923+01:00";
            name = "systemd-timesyncd";
            enabled = true;
            action = "allow";
            duration = "always";
            operator = {
              type = "simple";
              sensitive = false;
              operand = "process.path";
              data = "${lib.getBin pkgs.systemd}/lib/systemd/systemd-timesyncd";
            };
          };
          systemd-resolved = {
            created = "2026-02-02T15:41:27.730107923+01:00";
            name = "systemd-resolved";
            enabled = true;
            action = "allow";
            duration = "always";
            operator = {
              type = "simple";
              sensitive = false;
              operand = "process.path";
              data = "${lib.getBin pkgs.systemd}/lib/systemd/systemd-resolved";
            };
          };
        };
      };

      # Propagate some settings into home-manager:
      home-manager.users.${cfg.username} =
        { ... }:
        {
          tilde.graphical.enable = true;
        };
    })

    ############################################################################
    # Wayland:
    (lib.mkIf (cfg.graphical.enable && cfg.graphical.flavor == "wayland") {
      superkey.enable = true;

      # Propagate some settings into home-manager:
      home-manager.users.${cfg.username} =
        { ... }:
        {
          superkey.enable = true;
        };
    })
  ];
}
