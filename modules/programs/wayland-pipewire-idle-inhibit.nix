{ moduleWithSystem, ... }:
{
  flake.homeModules.wayland-pipewire-idle-inhibit = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      config = {
        home.packages = [
          pkgs.wayland-pipewire-idle-inhibit
        ];

        xdg.configFile."wayland-pipewire-idle-inhibit/config.toml".source =
          let
            tomlFormat = pkgs.formats.toml { };
            toToml = tomlFormat.generate "wayland-pipewire-idle-inhibit.toml";
          in
          toToml {
            verbosity = "INFO";
            media_minimum_duration = 5;
            idle_inhibitor = "wayland";

            sink_whitelist = [
              { name = "Scarlett"; }
              { name = "Office"; }
              { name = "Earbuds"; }
              { name = "Built-in"; }
            ];

            node_blacklist = [ ];
          };

        systemd.user.services.wayland-pipewire-idle-inhibit = {
          Unit = {
            Description = "Inhibit the screen locker when using audio";
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${pkgs.wayland-pipewire-idle-inhibit}/bin/wayland-pipewire-idle-inhibit";
            Restart = "on-failure";
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    }
  );
}
