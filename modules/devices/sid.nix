{
  self,
  moduleWithSystem,
  ...
}:
{
  flake.nixosModules.sid = moduleWithSystem (
    { pkgs, ... }:
    { lib, ... }:
    {
      imports = with self.nixosModules; [
        basic
        tilde
      ];

      config = {
        networking.hostName = "sid";

        services.kmonad = {
          enable = true;

          keyboards.internal = {
            device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
            config = builtins.readFile ../../support/keyboard/us_60.kbd;

            defcfg = {
              enable = true;
              fallthrough = true;
              compose.key = "compose";
            };
          };
        };

        # Ignore all lid switch events:
        services.logind.settings.Login =
          let
            ignore = lib.mkForce "ignore";
            keys = [
              "HandleLidSwitch"
              "HandleLidSwitchDocked"
              "HandleLidSwitchExternalPower"
            ];
          in
          builtins.listToAttrs (
            map (key: {
              name = key;
              value = ignore;
            }) keys
          );

        tilde = {
          crontab = {
            image-import = {
              user = "pjones";
              schedule = "*-*-* 00/4:15:00";
              path = [ pkgs.pjones.image-scripts ];
              script = "image-import";
            };
          };
        };

        home-manager.users.pjones = {
          imports = with self.homeModules; [
            basic
            syncthing
          ];
        };
      };
    }
  );

  perSystem = self.lib.nixos.checkHost "sid";
}
