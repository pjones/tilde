{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.wayland = moduleWithSystem (
    { pkgs, system, ... }:
    { lib, ... }:
    {
      config = {
        xdg.portal = {
          enable = lib.mkDefault true;
          configPackages = [ pkgs.niri ];
          extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        };

        # Needed to trigger a screen lock when systemd locks/sleeps.
        services.systemd-lock-handler.enable = true;

        environment.pathsToLink = [
          "/share/xdg-desktop-portal"
          "/share/applications"
        ];

        # Fonts:
        fonts = {
          fontconfig.enable = true;
          fontDir.enable = true;
          enableGhostscriptFonts = true;
          packages = with pkgs; [
            atkinson-hyperlegible # Typeface designed to offer greater legibility and readability for low vision readers
            dejavu_fonts # Typeface family based on the Bitstream Vera fonts
            hermit # Monospace font designed to be clear, pragmatic and very readable
            self.packages.${system}.nerd-hyperlegible
          ];
        };
      };
    }
  );

  flake.homeModules.wayland = moduleWithSystem (
    { pkgs, system, ... }:
    { config, lib, ... }:
    {
      options.tilde.wayland = {
        theme = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${system}.theme-outrun;
          description = "A theme package.";
        };

        primaryOutput = lib.mkOption {
          type = lib.types.str;
          description = ''
            The name of the primary output (display), For example: eDP-1.
          '';
        };

        commands = {
          sendClipboard = lib.mkOption {
            type = lib.types.str;
            default = "kdeconnect-cli -n Chet --send-clipboard";
            description = "Shell command to send the clipboard to another device";
          };

          extraSessionCommands = lib.mkOption {
            type = lib.types.lines;
            default = ''
              export _JAVA_AWT_WM_NONREPARENTING=1
              export NIXOS_OZONE_WL=1
              export QT_QPA_PLATFORM=wayland
              export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
              export SDL_VIDEODRIVER=wayland
            '';
            description = ''
              Shell commands executed just before the compositor is started.
            '';
          };
        };

        lock = {
          lockAfterMin = lib.mkOption {
            type = lib.types.int;
            default = 30;
            description = ''
              Automatically lock the screen after the given number of
              minutes of being idle.
            '';
          };

          secureAfterMin = lib.mkOption {
            type = lib.types.int;
            default = 120;
            description = ''
              Automatically remove SSH/GPG keys after this many minutes of
              being idle.
            '';
          };

          imageCachePath = lib.mkOption {
            type = lib.types.path;
            default = "${config.xdg.cacheHome}/superkey/lock-image";
            internal = true;
            description = ''
              Internal path where the selected lock image will appear.
            '';
          };

          imagePath = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/documents/pictures/backgrounds/lock-screen";
            description = ''
              Path to the image or directory of images to use for the lock
              screen.
            '';
          };

          screenLockCmd = lib.mkOption {
            type = lib.types.str;
            default = null;
            description = ''
              A shell command that starts a graphical lock screen.
            '';
          };

          forceLockCmd = lib.mkOption {
            type = lib.types.str;
            default = "${self.packages.${system}.force-lock}/bin/force-lock.sh";
            description = ''
              A shell command that will lock the current session.
            '';
          };

          stopAllInhibitorsCmd = lib.mkOption {
            type = lib.types.str;
            default = "${self.packages.${system}.force-lock}/bin/stop-idle-inhibitors.sh";
            description = ''
              A shell command that will stop all idle inhibitors.
            '';
          };

          startAllInhibitorsCmd = lib.mkOption {
            type = lib.types.str;
            default = "${self.packages.${system}.force-lock}/bin/start-idle-inhibitors.sh";
            description = ''
              A shell command that will start all idle inhibitors.
            '';
          };
        };
      };

      config = {
        # Ensure the xsession is disabled so Home Manager will enable
        # Wayland settings:
        xsession.enable = lib.mkForce false;

        # This uses `xsession` but it's needed for Wayland too:
        xsession.preferStatusNotifierItems = true;

        # For apps that want a user picture like SDDM/GDM:
        home.file.".face".source = "${self.packages.${system}.pjones-avatar}/share/faces/pjones.jpg";

        systemd.user.services.screen-lock =
          let
            cfg = config.tilde.wayland.lock;

            # Script that locks the screen after finding a suitable background
            # image.
            lockCmd = pkgs.writeShellApplication {
              name = "lock";
              runtimeInputs = [ self.packages.${system}.superkey ];
              text = ''
                # Ensure the lock screen tool *always* starts:
                trap "exec ${cfg.screenLockCmd}" ERR

                default_lock_image=${../../support/images/lock.png}
                selected_image=

                if [ -d "${cfg.imagePath}" ]; then
                  selected_image=$(superkey-random-file.sh -i -d "${cfg.imagePath}" -D "$default_lock_image")
                elif [ -e "${cfg.imagePath}" ]; then
                  selected_image="${cfg.imagePath}"
                else
                  selected_image=$default_lock_image
                fi

                if [ -n "$selected_image" ] && [ -e "$selected_image" ]; then
                  mkdir --parents "$(dirname "${cfg.imageCachePath}")"
                  ln --force --symbolic "$selected_image" "${cfg.imageCachePath}"
                fi

                exec ${cfg.screenLockCmd}
              '';
            };
          in
          {
            # The targets used here are created by the NixOS setting:
            # services.systemd-lock-handler.
            Unit = {
              Description = "Screen locker for Wayland";
              PartOf = [ "lock.target" ];
              OnSuccess = [ "unlock.target" ];
              Before = [ "lock.target" ];
            };

            Service = {
              Type = "exec";
              ExecStart = "${lockCmd}/bin/lock";
              Restart = "on-failure";
              RestartSec = 0;
            };

            Install = {
              WantedBy = [ "lock.target" ];
            };
          };
      };
    }
  );
}
