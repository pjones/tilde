{ self, moduleWithSystem, ... }:
{
  flake.homeModules.suspend = moduleWithSystem (
    { system, ... }:
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
            ExecStart = "${self.packages.${system}.superkey}/bin/superkey-pre-suspend.sh";
          };

          Install = {
            WantedBy = [ "sleep.target" ];
          };
        };
      };
    }
  );
}
