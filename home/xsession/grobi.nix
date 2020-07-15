{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.xsession.grobi;

  rules = {
    medusa = [
      rec {
        name = "Medusa";
        outputs_connected = [ "DisplayPort-0" "HDMI-0" ];
        configure_row = outputs_connected;
        primary = builtins.head outputs_connected;
      }
    ];
  };
in
{
  options.pjones.xsession.grobi = {
    enable = lib.mkEnableOption "Configure monitor layout with Grobi";

    name = lib.mkOption {
      type = with lib; types.enum (attrNames rules);
      default = "medusa";
      description = "The name of the ruleset to use";
    };
  };

  config = lib.mkIf cfg.enable {
    services.grobi = {
      enable = true;
      rules = rules.${cfg.name};
    };
  };
}
