{ moduleWithSystem, ... }:
{
  flake.homeModules.wlinhibit = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      config = {
        # NOTE: This service isn't wanted by anything, so it won't start
        # automatically.
        systemd.user.services.wayland-inhibit = {
          Unit = {
            Description = "Inhibit Wayland Idle";
            Documentation = "https://github.com/0x5a4/wlinhibit";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session-pre.target" ];
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };

          Service = {
            ExecStart = "${pkgs.wlinhibit}/bin/wlinhibit";
            Restart = "no";
          };
        };
      };
    }
  );
}
