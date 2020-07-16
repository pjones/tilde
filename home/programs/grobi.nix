{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.programs.grobi;

  useAll = name: outputs: {
    inherit name;
    outputs_connected = outputs;
    configure_row = outputs;
    primary = builtins.head outputs;
  };

  rules = {
    medusa = [
      (useAll "Medusa Primary" [ "DisplayPort-0" "HDMI-0" ])
      (useAll "Fallback to DisplayPort" [ "DisplayPort-0" ])
      (useAll "Fallback to HDMI" [ "HDMI-0" ])
    ];

    elphaba = [
      {
        name = "Elphaba Primary";
        outputs_connected = [ "eDP-1" ];
        primary = "eDP-1";
      }
    ];
  };
in
{
  options.pjones.programs.grobi = {
    enable = lib.mkEnableOption "Configure monitor layout with Grobi";

    name = lib.mkOption {
      type = with lib; types.nullOr (types.enum (attrNames rules));
      default = null;
      description = "The name of the ruleset to use";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.name != null) {
    services.grobi = {
      enable = true;
      rules = rules.${cfg.name};
    };
  };
}
