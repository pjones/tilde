{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.tilde.programs.gromit-mpx;
in
{
  options.tilde.programs.gromit-mpx = {
    enable = lib.mkEnableOption "Gromit-MPX";
  };

  config = mkIf cfg.enable {
    services.gromit-mpx = {
      enable = true;
      opacity = 1.0;
      hotKey = "F1";
      undoKey = "F4";

      tools =
        let
          mkTool = attrs:
            let
              withArrow =
                if attrs ? arrowSize
                then { modifiers = (attrs.modifiers or [ ]) ++ [ "2" ]; }
                else { };
            in
            {
              device = "default";
              size = 3;
            } // attrs // withArrow;

          tool1 = { color = "#FF67E7"; modifiers = [ ]; };
          tool2 = { color = "#0CECDD"; modifiers = [ "CONTROL" ]; };
          tool3 = { color = "#FFF338"; modifiers = [ "SHIFT" ]; };
          tool4 = { color = "#FF4848"; modifiers = [ "ALT" ]; };
          addArrow = attrs: attrs // { arrowSize = 2; };
        in
        [
          (mkTool tool1)
          (mkTool tool2)
          (mkTool tool3)
          (mkTool tool4)

          # With Arrows:
          (mkTool (addArrow tool1))
          (mkTool (addArrow tool2))
          (mkTool (addArrow tool3))
          (mkTool (addArrow tool4))

          # Right click to erase:
          {
            device = "default";
            type = "eraser";
            size = 75;
            modifiers = [ "3" ];
          }

          # Right clicking on a trackpad is hard:
          {
            device = "default";
            type = "eraser";
            size = 75;
            modifiers = [ "CONTROL" "ALT" ];
          }

          # Wacom Eraser:
          {
            device = "Wacom Bamboo One M Pen";
            modifiers = [ "1" "2" ];
            type = "eraser";
            size = 75;
          }
        ]
        # Wacom versions of the arrow tools:
        ++ map
          (tool:
            tool // (addArrow {
              device = "Wacom Bamboo One M Pen";
              modifiers = (tool.modifiers or [ ]) ++ [ "1" "3" ];
              size = 3;
            })) [ tool1 tool2 tool3 tool4 ];
    };

    # Don't start by default (shows up on powertop as a hungry
    # process):
    systemd.user.services.gromit-mpx.Install.WantedBy = lib.mkForce [ ];
  };
}

