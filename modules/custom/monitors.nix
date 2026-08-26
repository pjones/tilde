{ self, moduleWithSystem, ... }:
{
  flake.homeModules.monitors = moduleWithSystem (
    { system, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.monitors;

      identityType = lib.types.submodule {
        options = {
          manufacturer = lib.mkOption {
            type = lib.types.str;
            default = "*";
            description = "Monitor manufacturer or *";
          };

          model = lib.mkOption {
            type = lib.types.str;
            default = "*";
            description = "Monitor model number or *";
          };

          serial = lib.mkOption {
            type = lib.types.str;
            default = "*";
            description = "Monitor seral number";
          };
        };
      };

      monitorType = lib.types.submodule (
        { name, ... }: {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = "An name for this monitor";
            };

            connector = lib.mkOption {
              type =
                with lib.types;
                oneOf [
                  str
                  identityType
                ];
            };

            width = lib.mkOption {
              type = with lib.types; nullOr ints.unsigned;
              default = null;
              description = "Width in pixels";
            };

            height = lib.mkOption {
              type = with lib.types; nullOr ints.unsigned;
              default = null;
              description = "Height in pixesl";
            };

            rate = lib.mkOption {
              type = with lib.types; nullOr float;
              default = null;
              description = "Optional refresh rate";
            };

            scale = lib.mkOption {
              type = lib.types.float;
              default = 1.0;
              description = "Scale factor";
            };

            alias = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = "Configuration alias (without the dollar sign)";
            };
          };
        }
      );

      layoutType = lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "A unique name for this layout";
          };

          args = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Arguments to pass to the superkey-output.sh script";
          };

          outputs = lib.mkOption {
            type = with lib.types; nonEmptyListOf str;
            default = [ ];
            description = ''
              List of monitor names that must be connected to activate
              this layout.

              You can use the name "*" to match any monitor as long as
              it is the last monitor listed.
            '';
          };
        };
      };

      toCriteria =
        monitor:
        if builtins.isAttrs monitor.connector then
          # FIXME: What if one of these has a space in them?
          with monitor.connector; "${manufacturer} ${model} ${serial}"
        else
          monitor.connector;

      toMode =
        monitor:
        "${toString monitor.width}x${toString monitor.height}"
        + lib.optionalString (monitor.rate != null) "@${toString monitor.rate}";

      toKanshiOutput = monitor: {
        output = {
          criteria = toCriteria monitor;
          mode = toMode monitor;
          scale = monitor.scale;
          alias = monitor.alias;
        };
      };

      # Layout monitors from left to right in the given order.
      leftToRight =
        monitors:
        let
          start = monitor: {
            inherit monitor;
            position.x = 0;
            position.y = 0;
          };

          next = monitor: x: {
            inherit monitor;
            position.x = x;
            position.y = 0;
          };
        in
        lib.foldl (
          acc: output:
          if builtins.length acc != 0 then
            let
              prev = lib.last acc;
              x = prev.position.x + prev.monitor.width;
            in
            acc ++ [ (next output x) ]
          else
            [ (start output) ]
        ) [ ] monitors;

      findMonitor =
        monitors: name:
        if name == "*" then
          {
            connector = "*";
            width = 0;
            height = 0;
          }
        else
          monitors.${name};

      toKanshiProfile = monitors: layout: {
        profile = {
          name = layout.name;
          exec = "${self.packages.${system}.superkey}/bin/superkey-output.sh ${layout.args}";
          outputs = map (output: {
            criteria = if output.monitor ? alias then "$" + output.monitor.alias else output.monitor.connector;
            position = lib.concatMapStringsSep "," toString [
              output.position.x
              output.position.y
            ];
          }) (leftToRight (map (findMonitor monitors) layout.outputs));
        };
      };
    in
    {
      options.tilde.monitors = {
        devices = lib.mkOption {
          type = with lib.types; attrsOf monitorType;
          default = { };
          description = "Monitors that you may connect to";
        };

        layouts = lib.mkOption {
          type = with lib.types; nonEmptyListOf layoutType;
          default = [ ];
          description = "Layouts to automatically activate";
        };

        primary = lib.mkOption {
          type = lib.types.str;
          default = "internal";
          description = "The name of the primary monitor";
        };

        extraNiri = lib.mkOption {
          type = with lib.types; attrsOf anything;
          default = { };
          description = "Extra Niri config for the primary monitor";
        };
      };

      config = {
        tilde.monitors.devices = {
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

        tilde.monitors.layouts = [
          {
            name = "home";
            args = "-n -p ${cfg.devices.${cfg.primary}.connector}";
            outputs = [
              "home"
              "internal"
            ];
          }
          {
            name = "work";
            args = "-dn -p ${cfg.devices.${cfg.primary}.connector}";
            outputs = [
              "work"
              "internal"
            ];
          }
          {
            name = "conference";
            args = "-P -p ${cfg.devices.${cfg.primary}.connector}";
            outputs = [
              "internal"
              "conference"
            ];
          }
          {
            name = "others";
            args = "-P -p ${cfg.devices.${cfg.primary}.connector}";
            outputs = [
              "internal"
              "*"
            ];
          }
          {
            name = "internal";
            args = "-p ${cfg.devices.${cfg.primary}.connector}";
            outputs = [ "internal" ];
          }
        ];

        services.kanshi = {
          enable = true;
          settings =
            map toKanshiOutput (builtins.attrValues cfg.devices)
            ++ map (toKanshiProfile cfg.devices) cfg.layouts;
        };

        tilde.wayland.primaryOutput = cfg.devices.${cfg.primary}.connector;

        wayland.windowManager.niri.settings =
          let
            monitor = cfg.devices.${cfg.primary};
          in
          {
            output = [
              (
                {
                  _args = [ monitor.connector ];
                  mode = with monitor; "${toString width}x${toString height}";
                  scale = monitor.scale;
                }
                // cfg.extraNiri
              )
            ];
          };
      };
    }
  );
}
