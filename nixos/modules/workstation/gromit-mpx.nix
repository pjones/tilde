{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.pjones;

  # Easy pen definition:
  mkTool = attrs: { device="default"; size=3; } // attrs;

in
{
  config = mkIf cfg.isWorkstation {
    home-manager.users.pjones = { ... }: {
      services.gromit-mpx = {
        enable = true;

        tools = [
          (mkTool { color="#ff00ff"; })
          (mkTool { color="#00c0ff"; modifiers = [ "SHIFT" ]; })
          (mkTool { color="#00ff00"; modifiers = [ "CONTROL" ]; })
          (mkTool { color="#eded02"; modifiers = [ "ALT" ]; })
          (mkTool { color="#ed0202"; modifiers = [ "SHIFT" "CONTROL" ]; })
          (mkTool { color="#3131be"; modifiers = [ "SHIFT" "ALT" ]; })
          (mkTool { type="eraser"; size=75; modifiers = [ "ALT" "CONTROL" ]; })

          { device = "Wacom Bamboo One M Pen";
            modifiers = [ "1" "2" ];
            type = "eraser";
            size = 75;
          }

          { device = "Wacom Bamboo One M Pen";
            modifiers = [ "1" "3" ];
            size = 10;
            color = "#00c0ff";
          }
        ];
      };
    };
  };
}
