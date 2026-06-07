{ self, moduleWithSystem, ... }:
{
  flake.homeModules.niri-hm = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      cfg = config.wayland.windowManager.niri;
      toKDL = lib.hm.generators.toKDL { };

      # Convert an attribute set to KDL and return the corresponding
      # string.
      toConfig =
        attrs:
        let
          # Nodes that repeat (list of attribute sets):
          repeatBlocks = lib.filterAttrs (_name: value: builtins.typeOf value == "list") attrs;

          # All other nodes:
          settings = removeAttrs attrs (builtins.attrNames repeatBlocks);

          repeatBlocksToKDL = lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              name: blocks: lib.concatMapStringsSep "\n" (block: toKDL { ${name} = block; }) blocks
            ) repeatBlocks
          );
        in
        toKDL settings + repeatBlocksToKDL;

      # Return a string containing the Niri configuration or `null` if the
      # user is managing the configuration manually.
      configFile =
        let
          text =
            if cfg.config != null then
              cfg.config
            else if cfg.settings != null then
              toConfig cfg.settings
            else
              null;
        in
        if text != null then
          pkgs.writeTextFile {
            name = "config.kdl";

            checkPhase = ''
              ${cfg.package}/bin/niri validate --config "$target"
            '';

            text = lib.concatStringsSep "\n" [
              text

              ''spawn-at-startup "${systemdActivation}"''

              cfg.extraConfig
            ];
          }
        else
          null;

      systemdActivation = pkgs.writeShellScript "niri-systemd-activation" ''
        systemctl --user reset-failed
        systemctl --user start niri-session.target
      '';

      # This is a wrapper around the Niri package that removes all
      # systemd related files and swaps out the niri-session script for
      # one that works with Home Manager.
      finalPackage =
        let
          variables = lib.concatMapStringsSep " " lib.escapeShellArg cfg.systemd.variables;

          sessionCommand = pkgs.writeShellScript "niri-session" ''
            set -o errexit
            exec > >(systemd-cat -t niri-session) 2>&1

            export XDG_CURRENT_DESKTOP=${cfg.package.meta.mainProgram}
            ${cfg.extraSessionCommands}
            . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
            systemctl --user import-environment ${variables}

            if [ "$DBUS_SESSION_BUS_ADDRESS" ]; then
              export DBUS_SESSION_BUS_ADDRESS
              dbus-update-activation-environment --all
              ${lib.getExe cfg.package} --session "$@"
            else
              "${pkgs.dbus}/bin/dbus-run-session" -- \
                 ${lib.getExe cfg.package} --session "$@"
            fi

            systemctl --user stop niri-session.target
          '';
        in
        pkgs.runCommand "niri-wrapper" { } ''
          while IFS= read -r -d "" file; do
            path=''${file##${cfg.package}}
            dir=$(dirname "$path")
            name=$(basename "$path")

            if ! [[ "$path" =~ systemd|niri-session ]]; then
              mkdir -p "$out/$dir"
              ln -Ls "$file" "$out/$dir/$name"
            fi
          done < <(find ${cfg.package} -type f -print0)

          ln -Ls ${sessionCommand} "$out/bin/niri-session"
        '';
    in
    {
      imports = [
        self.inputs.niri-autoselect-portal.homeManagerModules.default
      ];

      options.wayland.windowManager.niri = {
        enable = lib.mkEnableOption "Niri wayland compositor";

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.niri;
          description = ''
            The Niri package to use.

            This package will be used to construct another package that is
            then installed into the user environment.
          '';
        };

        settings = lib.mkOption {
          type = lib.types.nullOr (lib.types.attrsOf lib.types.anything);
          default = { };
          description = ''
            An attribute set that is converted to KDL.
          '';
        };

        config = lib.mkOption {
          type = lib.types.nullOr lib.types.lines;
          default = null;
          description = ''
            Optional contents of the Niri configuration file.
          '';
        };

        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = ''
            Extra configuration lines to add to ~/.config/niri/config.kdl.
          '';
        };

        extraSessionCommands = lib.mkOption {
          type = lib.types.lines;
          default = "";
          example = ''
            export SDL_VIDEODRIVER=wayland
            # needs qt5.qtwayland in systemPackages
            export QT_QPA_PLATFORM=wayland
            export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
            # Fix for some Java AWT applications (e.g. Android Studio),
            # use this if they aren't displayed properly:
            export _JAVA_AWT_WM_NONREPARENTING=1
          '';
          description = ''
            Shell commands executed just before Niri is started.
          '';
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [
            pkgs.alacritty
            pkgs.fuzzel
          ];
          description = ''
            Extra pacakges to install along with Niri.
          '';
        };

        systemd = {
          variables = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "DISPLAY"
              "NIRI_SOCKET"
              "NIXOS_OZONE_WL"
              "WAYLAND_DISPLAY"
              "XCURSOR_SIZE"
              "XCURSOR_THEME"
              "XDG_CURRENT_DESKTOP"
              "XDG_SESSION_TYPE"
            ];
            description = ''
              Environment variables imported into the systemd and D-Bus
              user environment.
            '';
          };
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          finalPackage
          pkgs.xwayland-satellite
        ]
        ++ cfg.extraPackages;

        xdg.configFile."niri/config.kdl" =
          let
            file = configFile;
          in
          lib.mkIf (file != null) { source = file; };

        services.niri-autoselect-portal.enable = true;

        xdg.portal = {
          enable = true;

          extraPortals = with pkgs; [
            xdg-desktop-portal-gnome
            xdg-desktop-portal-gtk
          ];

          config.niri = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.Access" = "gtk";
            "org.freedesktop.impl.portal.Notification" = "gtk";
            "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
          };
        };

        systemd.user.targets.niri-session = {
          Unit = {
            Description = "A scrollable-tiling Wayland compositor";
            BindsTo = [
              "graphical-session.target"
              "tray.target"
            ];
            Wants = [
              "graphical-session-pre.target"
              "xdg-desktop-autostart.target"
            ];
            After = [ "graphical-session-pre.target" ];
            Before = [ "xdg-desktop-autostart.target" ];
          };
        };
      };
    }
  );
}
