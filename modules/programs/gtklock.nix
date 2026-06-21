{ moduleWithSystem, ... }:
{
  flake.nixosModules.gtklock = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        security.pam.services.gtklock = { };
      };
    }
  );

  flake.homeModules.gtklock = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    {
      config = {
        tilde.wayland.lock.screenLockCmd = "${pkgs.gtklock}/bin/gtklock";

        home.packages = [ pkgs.gtklock ];

        xdg.configFile."gtklock/config.ini".text =
          let
            modules = with pkgs; [ gtklock-powerbar-module ];
            modstr = lib.concatMapStringsSep ";" (
              pkg: "${pkg}/lib/gtklock/${lib.removePrefix "gtklock-" pkg.pname}.so"
            ) modules;
          in
          ''
            [main]
            background=${config.tilde.wayland.lock.imageCachePath}
            date-format=
            follow-focus=true
            idle-hide=true
            idle-timeout=5
            modules=${modstr}
            monitor-priority=${config.tilde.wayland.primaryOutput}
            start-hidden=true
            time-format=
          '';
      };
    }
  );
}
