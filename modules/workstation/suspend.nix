{ moduleWithSystem, ... }:
{
  flake.homeModules.suspend = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      config = {
        # A user service that prepares for suspend:
        systemd.user.services.onsuspend = {
          Unit = {
            Description = "Prepare for suspend";
            Before = "sleep.target";
          };

          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.pjones.superkey-scripts}/bin/superkey-pre-suspend.sh";
          };

          Install = {
            WantedBy = [ "sleep.target" ];
          };
        };
      };
    }
  );
}
