{ self, moduleWithSystem, ... }:
{
  flake.homeModules.swayidle = moduleWithSystem (
    { pkgs, system, ... }:
    { config, ... }:
    let
      cfg = config.tilde.wayland.lock;
      superkey = self.packages.${system}.superkey;

      lockTimeout = cfg.lockAfterMin * 60;
      secureTimeout = cfg.secureAfterMin * 60;
      blankTimeout = lockTimeout + 60;

      loginctl = "${pkgs.systemd}/bin/loginctl";
      pre-suspend-script = "${superkey}/bin/superkey-pre-suspend.sh";

      # Script that is run by swayidle when it's time to blank the screen.
      onIdleCommand = pkgs.writeShellApplication {
        name = "on-superkey-idle";
        runtimeInputs = [
          config.wayland.windowManager.niri.package
          superkey
        ];
        text = ''
          ${cfg.stopAllInhibitorsCmd} || :
          superkey-output.sh -O
        '';
      };

      # Script that is run by swayidle when it's time to wake the screen.
      onNotIdleCommand = pkgs.writeShellApplication {
        name = "on-superkey-not-idle";
        runtimeInputs = [
          config.wayland.windowManager.niri.package
          superkey
        ];
        text = ''
          superkey-output.sh -o
          ${cfg.startAllInhibitorsCmd} || :
        '';
      };
    in
    {
      config = {
        services.swayidle = {
          enable = true;
          extraArgs = [ "-w" ];

          timeouts = [
            {
              timeout = lockTimeout;
              command = "${loginctl} lock-session";
            }
            {
              timeout = secureTimeout;
              command = pre-suspend-script;
            }
            {
              timeout = blankTimeout;
              command = "${onIdleCommand}/bin/on-superkey-idle";
              resumeCommand = "${onNotIdleCommand}/bin/on-superkey-not-idle";
            }
          ];
        };
      };
    }
  );

}
