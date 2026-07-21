{ self, moduleWithSystem, ... }:
{
  # A NixOS module to monitor a system using Prometheus.
  flake.nixosModules.prometheus-node = moduleWithSystem (
    { ... }:
    { lib, ... }:
    {
      config = {
        services.prometheus = {
          exporters.node = {
            enable = true;
            port = self.lib.services.prometheus-node;
            listenAddress = "0.0.0.0";
            openFirewall = lib.mkForce false;

            enabledCollectors = [
              "systemd"
            ];
          };

          exporters.systemd = {
            enable = true;
            port = self.lib.services.prometheus-systemd;
            listenAddress = "0.0.0.0";
            openFirewall = lib.mkForce false;
          };
        };
      };
    }
  );
}
