{ moduleWithSystem, ... }:
{
  flake.homeModules.beamerpresenter = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.beamerpresenter;

      # Tool type name and whether or not the tool is a drawing tool (as
      # opposed to a pointing tool).
      toolTypes = {
        "pen" = true;
        "fixed width pen" = true;
        "highlighter" = true;
        "eraser" = true;
        "pointer" = false;
        "magnifier" = false;
        "torch" = false;
        "text" = false;
        "click select" = false;
        "rectangle select" = false;
        "freehand select" = false;
        "none" = false;
      };

      toolAttrs = {
        width = true;
        size = false;
        fill = true;
        style = true;
        brush = true;
        shape = true;
        scale = [ "magnifier" ];
        linewidth = [ "eraser" ];
        font = [ "text" ];
        "font size" = [ "text" ];
      };

      toolOptions =
        { ... }:
        {
          options = {
            type = lib.mkOption {
              type = lib.types.enum (builtins.attrNames toolTypes);

              default = "pen";
              description = "Tool type";
            };

            device = lib.mkOption {
              type = lib.types.listOf (
                lib.types.enum [
                  "left button"
                  "right button"
                  "middle button"
                  "no button"
                  "touch"
                  "tablet pen"
                  "tablet"
                  "tablet eraser"
                  "tablet hover"
                  "tablet cursor"
                  "tablet other"
                  "tablet mod"
                  "tablet all"
                  "all"
                  "all+"
                  "all++"
                ]
              );

              default = [ "all+" ];
              description = "Tool device";
            };

            color = lib.mkOption {
              type = lib.types.str;
              default = "#000000";
              description = "Color name known to Qt or #RRGGBB or #AARRGGBB";
            };

            width = lib.mkOption {
              type = lib.types.ints.positive;
              default = 2;
              description = "Stroke width of drawing tools";
            };

            size = lib.mkOption {
              type = lib.types.ints.positive;
              default = 50;
              description = "Radius of pointing tools";
            };

            fill = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Fill color for drawing tools, or null for no fill";
            };

            style = lib.mkOption {
              type = lib.types.enum [
                "nopen"
                "solid"
                "dash"
                "dot"
                "dashdot"
                "dashdotdot"
              ];
              default = "solid";
              description = "Pen style";
            };

            # FIXME: brush

            shape = lib.mkOption {
              type = lib.types.enum [
                "freehand"
                "rectangle"
                "ellipse"
                "line"
                "arrow"
              ];
              default = "freehand";
              description = "Shape (or freehand) for drawing tools";
            };

            scale = lib.mkOption {
              type = lib.types.numbers.between 0.1 5;
              default = 2;
              description = "Magnification factor for the magnifier tool";
            };

            linewidth = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 1;
              description = "Eraser circle size";
            };

            # FIXME: font
            #
            # FIXME: font size

            key = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional keyboard shortcut for this tool";
            };
          };
        };

      toolAttrsToRemove =
        tool:
        let
          removeAttr =
            attr:
            if !(builtins.hasAttr attr toolAttrs) then
              false
            else if attr == "fill" && tool.fill == null then
              true # Fill can be null, but can't show up in the JSON
            else if true == toolAttrs.${attr} || false == toolAttrs.${attr} then
              toolTypes.${tool.type} != toolAttrs.${attr}
            else if builtins.isList toolAttrs.${attr} then
              !(builtins.elem tool.type toolAttrs.${attr})
            else
              false;
        in
        builtins.filter removeAttr (builtins.attrNames tool);

      toolsToKeys =
        tools:
        builtins.listToAttrs (
          builtins.map (
            tool:
            let
              toRemove = toolAttrsToRemove tool ++ [
                "key" # Not really part of the config
                "type" # Turned into "tool"
              ];
              fixed = builtins.removeAttrs tool toRemove // {
                tool = tool.type;
              };
              name = tool.key;
              json = builtins.toJSON fixed;
              escaped = lib.escape [ "\"" ] json;
              value = "\"${escaped}\"";
            in
            {
              inherit name value;
            }
          ) (builtins.filter (tool: tool.key != null) tools)
        );

      toINI =
        let
          mkVal =
            v:
            if builtins.isList v then
              lib.concatStringsSep ", " v
            else
              lib.generators.mkValueStringDefault { } v;
        in
        lib.generators.toINI {
          mkKeyValue = lib.generators.mkKeyValueDefault {
            mkValueString = mkVal;
          } "=";
        };

      defaultTools = [
        {
          color = "#521673";
          key = "P";
        }
        {
          color = "#ff00b4";
          key = "R";
        }
        {
          type = "highlighter";
          width = 20;
          color = "#8029ff00";
          key = "H";
        }
        {
          type = "highlighter";
          width = 20;
          color = "#80ffbb00";
          key = "G";
        }
        {
          type = "eraser";
          color = "gray";
          size = 10;
          key = "E";
        }
        {
          type = "magnifier";
          device = [
            "left button"
            "tablet pen"
          ];
          color = "gray";
          size = 100;
          scale = 1.75;
          key = "M";
        }
        {
          type = "torch";
          device = [
            "left button"
            "tablet pen"
          ];
          color = "#80080808";
          size = 60;
          key = "F";
        }
        {
          type = "text";
          key = "T";
        }
      ];
    in
    {
      options.tilde.programs.beamerpresenter = {
        tools = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule toolOptions);
          default = defaultTools;
          description = ''
            List of tools to configure.
          '';
        };

        settings = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = ''
            Settings written into the beamerpresenter.conf file.
          '';
        };
      };

      config = {
        home.packages = [
          pkgs.beamerpresenter
        ];

        tilde.programs.beamerpresenter.settings = {
          general = {
            "engine" = "mupdf";
            "gestures" = false;
            "automatic slide changes" = false;
            "gui config" = "${pkgs.beamerpresenter}/etc/xdg/beamerpresenter/gui.json";
          };

          drawing = {
            mode = "per label";
          };

          keys = {
            "Ctrl+A" = "select all";
            "Ctrl+C" = "copy";
            "Ctrl+O" = "open";
            "Ctrl+Q" = "quit";
            "Ctrl+S" = "save";
            "Ctrl+Shift+S" = "save as";
            "Ctrl+V" = "paste";
            "Ctrl+X" = "cut";
            "Ctrl+Y" = "redo left, redo right, redo";
            "Ctrl+Z" = "undo left, undo right, undo";
            "Delete" = "delete";
            "End" = "last";
            "Escape" = "clear selection";
            "F11" = "fullscreen";
            "Home" = "first";
            "Up" = "previous";
            "Left" = "previous";
            "PgDown" = "next";
            "PgUp" = "previous";
            "Down" = "next";
            "Right" = "next";
            "Shift+PgDown" = "next skipping overlays";
            "Shift+PgUp" = "previous skipping overlays";
            "C" = "clear";
            "Z" = "undo left, undo right, undo";
          }
          // toolsToKeys cfg.tools;
        };

        xdg.configFile."beamerpresenter/beamerpresenter.conf".text = toINI cfg.settings;
      };
    }
  );
}
