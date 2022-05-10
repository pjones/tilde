{ pkgs, config, lib, ... }:

let
  cfg = config.tilde.programs.plasma;

  gtkConfig = pkgs.writeScript "gtk-config"
    (builtins.readFile ../../support/gtk-config.sh);

  kdeConfig = pkgs.writeScript "kde-config"
    (lib.concatStrings
      (lib.mapAttrsToList
        (file: groups:
          lib.concatStrings
            (lib.mapAttrsToList
              (kWriteConfig file)
              groups))
        cfg.settings)
    + lib.concatStrings
      (lib.mapAttrsToList
        (group: attrs:
          kWriteConfig "kglobalshortcutsrc" group
            (lib.mapAttrs' bindingToNameValuePair attrs)
        )
        cfg.bindings));

  toKdeValue = v:
    if v == null then
      "--delete"
    else if builtins.isString v then
      lib.escapeShellArg v
    else if builtins.isBool v then
      "--type bool " + lib.boolToString v
    else if builtins.isInt v then
      builtins.toString v
    else
      builtins.abort ("Unknown value type: " ++ builtins.toString v);

  bindingToNameValuePair = _key: binding: {
    name = binding.name;
    value = lib.concatStringsSep "," [
      (lib.concatStringsSep "\t" binding.keys)
      (lib.concatStringsSep "\t" binding.defaults)
      binding.display
    ];
  };

  kWriteConfig = file: group: attrs:
    lib.concatStringsSep "\n" (lib.mapAttrsToList
      (key: value: ''
        ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 \
          --file ''${XDG_CONFIG_HOME:-$HOME/.config}/${lib.escapeShellArg file} \
          --group ${lib.escapeShellArg group} \
          --key ${lib.escapeShellArg key} \
          ${toKdeValue value}
      '')
      attrs);
in
{
  options.tilde.programs.plasma = {
    enable = lib.mkEnableOption "Configure KDE Plasma";

    bindings = lib.mkOption {
      default = { };
      description = "List of key bindings (shortcuts)";
      type = lib.types.attrsOf (lib.types.attrsOf
        (lib.types.submodule ({ name, ... }: {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = "Shortcut name";
            };

            display = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = "The display string used by KDE settings";
            };

            defaults = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Default key bindings";
            };

            keys = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Active key bindings";
            };
          };
        })));
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.attrs);
      default = { };
      description = "KDE Settings";
      example = {
        file = {
          group = {
            key = "value";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Default key bindings:
    tilde.programs.plasma.bindings =
      let none = [ "none" ];
      in
      {
        ksmserver = {
          "Lock Session".keys = [ "Screensaver" "Meta+Ctrl+Alt+L" ];
        };

        kded5 = {
          "display" = { keys = [ "Display" ]; display = "Switch Display"; };
        };

        kaccess = {
          "Toggle Screen Reader On and Off".keys = none;
        };

        kwin = {
          "Activate Window Demanding Attention".keys = [ "Meta+U" ];
          "Expose" = { keys = none; display = "Toggle Present Windows (Current desktop)"; };
          "ExposeAll" = { keys = [ "Meta+\\," ]; display = "Toggle Present Windows (All desktops)"; };
          "ExposeClass" = { keys = none; display = "Toggle Present Windows (Window class)"; };
          "Kill Window".keys = [ "Meta+Shift+Q" ];
          "MoveMouseToFocus".keys = [ "Meta+W" ];
          "Show Desktop".keys = none;
          "ShowDesktopGrid" = { keys = none; display = "Show Desktop Grid"; };
          "Suspend Compositing".keys = none;
          "Switch to Next Screen".keys = [ "Meta+." ];
          "Switch Window Down" = { keys = [ "Meta+J" ]; display = "Switch to Window Below"; };
          "Switch Window Left" = { keys = [ "Meta+H" ]; display = "Switch to Window to the Left"; };
          "Switch Window Right" = { keys = [ "Meta+L" ]; display = "Switch to Window to the Right"; };
          "Switch Window Up" = { keys = [ "Meta+K" ]; display = "Switch to Window Above"; };
          "Walk Through Windows (Reverse)".keys = [ "Meta+~" ];
          "Walk Through Windows of Current Application (Reverse)".keys = [ "Meta+Shift+Tab" ];
          "Walk Through Windows of Current Application".keys = [ "Meta+Tab" ];
          "Walk Through Windows".keys = [ "Meta+`" ];
          "Window Close" = { keys = [ "Meta+Q" ]; display = "Close Window"; };
          "Window Maximize" = { keys = [ "Meta+F" ]; display = "Maximize Window"; };
          "Window Minimize" = { keys = [ "Meta+M" ]; display = "Minimize Window"; };
          "Window One Desktop Down".keys = none;
          "Window One Desktop to the Left".keys = none;
          "Window One Desktop to the Right".keys = none;
          "Window One Desktop Up".keys = none;
          "Window Operations Menu".keys = none;
          "Window Quick Tile Bottom" = { keys = [ "Meta+Shift+J" ]; display = "Quick Tile Window to the Bottom"; };
          "Window Quick Tile Left" = { keys = [ "Meta+Shift+H" ]; display = "Quick Tile Window to the Left"; };
          "Window Quick Tile Right" = { keys = [ "Meta+Shift+L" ]; display = "Quick Tile Window to the Right"; };
          "Window Quick Tile Top" = { keys = [ "Meta+Shift+K" ]; display = "Quick Tile Window to the Top"; };
          "Window to Next Screen".keys = [ "Meta+>" ];
          "Window to Previous Screen".keys = none;
          "view_actual_size" = { keys = [ "Meta+=" ]; display = "Actual Size"; };
          "view_zoom_in" = { keys = [ "Meta++" ]; display = "Zoom In"; };
          "view_zoom_out" = { keys = [ "Meta+-" ]; display = "Zoom Out"; };
        } // (
          let
            shiftKeys = [ "!" "@" "#" "$" "%" "^" "&" "*" "(" ")" ];
            keys = map toString (lib.range 1 9 ++ [ 0 ]);
          in
          builtins.listToAttrs (lib.flatten (lib.imap1
            (n: c: [
              {
                name = "Switch to Desktop ${toString n}";
                value = { keys = [ "Meta+${builtins.elemAt keys (n - 1)}" ]; };
              }
              {
                name = "Window to Desktop ${toString n}";
                value = { keys = [ "Meta+${c}" ]; };
              }
            ])
            shiftKeys))
        );

        "org.kde.krunner.desktop" = {
          "_launch" = { keys = [ "Meta+Space" ]; display = "KRunner"; };
          "RunClipboard" = { keys = [ "Meta+Shift+Space" ]; display = "Run command on clipboard contents"; };
        };

        "org.kde.dolphin.desktop"."_launch" = { keys = none; display = "Dolphin"; };
        "org.kde.plasma.emojier.desktop"."_launch" = { keys = [ "Meta+Shift+E" ]; display = "Emoji Selector"; };

        "KDE Keyboard Layout Switcher" = {
          "Switch to Next Keyboard Layout".keys = none;
        };

        plasmashell = {
          "clipboard_action" = { keys = none; display = "Enable Clipboard Actions"; };
          "manage activities" = { keys = [ "Meta+A" ]; display = "Show Activity Switcher"; };
          "next activity" = { keys = none; display = "Walk through activities"; };
          "previous activity" = { keys = none; display = "Walk through activities (Reverse)"; };
          "repeat_action" = { keys = none; display = "Manually Invoke Action on Current Clipboard"; };
          "show dashboard" = { keys = none; display = "Show Desktop"; };
        } // (builtins.listToAttrs (map
          (n: {
            name = "activate task manager entry ${toString n}";
            value = { keys = none; display = "Activate Task Manager Entry ${toString n}"; };
          })
          (lib.range 1 10)));
      };

    # Default settings.
    tilde.programs.plasma.settings = {
      kdeglobals = {
        General.AllowKDEAppsToRememberWindowPositions = false;
        KDE.SingleClick = false;
      };

      baloofilerc = {
        "Basic Settings"."Indexing-Enabled" = false;
        General."only basic indexing" = true;
      };

      kwinrc = {
        MouseBindings.CommandTitlebarWheel = "Change Opacity";
        Windows.ElectricBorderMaximize = false;
        Windows.ElectricBorders = 1;
        Windows.FocusPolicy = "FocusFollowsMouse";
        Windows.Placement = "Smart";
        Windows.TitlebarDoubleClickCommand = "Shade";
      };

      plasma-localerc = {
        Formats.LC_TIME = "C";
      };

      spectaclerc = {
        Save.defaultSaveLocation = "file://${config.home.homeDirectory}/documents/pictures/screenshots";
        Save.saveFilenameFormat = "%Y/Screenshot_%Y%M%D_%H%m%S";
      };

      # Ensure the GUI settings still works:
      kglobalshortcutsrc = {
        ksmserver._k_friendly_name = "Session Management";
        "org.kde.krunner.desktop"._k_friendly_name = "KRunner";
        "org.kde.dolphin.desktop"._k_friendly_name = "Dolphin";
        "org.kde.plasma.emojier.desktop"._k_friendly_name = "Emoji Selector";
      };
    };

    home.packages = with pkgs; [
      crudini # For editing the GTK settings.ini file.
      krunner-pass # Access passwords in krunner
      qt5.qttools # for qdbus(1)
    ];

    home.activation.configure-plasma =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${gtkConfig}
        $DRY_RUN_CMD ${kdeConfig}
      '';
  };
}
