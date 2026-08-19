{ pkgs, self }:

let
  nodePortStr = toString self.lib.services.prometheus-node;
  colPortStr = toString self.lib.services.prometheus-collector;
in

pkgs.testers.nixosTest {
  name = "tilde-prometheus";

  nodes = {
    kraftwerk = { ... }: {
      imports = [
        self.nixosModules.test
        self.nixosModules.prometheus-node
      ];

      networking.firewall.allowedTCPPorts = [
        self.lib.services.prometheus-node
      ];

      tilde.privateInterface = "0.0.0.0";
    };

    numan = { lib, ... }: {
      imports = [
        self.nixosModules.test
        self.nixosModules.prometheus-alertmanager
        self.nixosModules.prometheus-collector
      ];

      environment.systemPackages = [
        pkgs.jq
      ];

      networking.firewall.allowedTCPPorts = [
        self.lib.services.prometheus-collector
      ];

      tilde.privateInterface = "0.0.0.0";

      tilde.programs.prometheus-collector = {
        nodes.kraftwerk = { };
        alertmanagers = [ "localhost" ];
      };

      tilde.programs.prometheus-alertmanager.receivers = lib.singleton {
        name = "default";
        email_configs = lib.singleton {
          to = "example@example.test";
          from = "example@example.test";
          smarthost = "localhost:587";
        };
      };
    };
  };

  testScript = ''
    kraftwerk.wait_for_unit("prometheus-node-exporter.service")
    kraftwerk.wait_until_succeeds("curl -sSf http://localhost:${nodePortStr}/metrics")

    numan.wait_for_unit("prometheus.service")
    numan.wait_until_succeeds("curl -sSf http://localhost:${colPortStr}/-/healthy")
  '';
}
