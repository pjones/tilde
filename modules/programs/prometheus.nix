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

  # A NixOS module to collect metrics from other hosts.
  flake.nixosModules.prometheus-collector = moduleWithSystem (
    { ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.prometheus-collector;

      # Like `lib.mkEnableOption` except the default is `true`.
      mkDefaultEnabledOption = str: lib.mkEnableOption str // { default = true; };

      # Return the port number for the given service as a string.
      getPort = key: toString self.lib.services."prometheus-${key}";

      # Return a scrape config for the given service containing all
      # nodes that have that service enabled.
      optionalScrape =
        key: nodes:
        if builtins.any (node: node.scrape.${key}) nodes then
          [
            {
              job_name = key;
              static_configs = [
                {
                  targets = map (node: "${node.host}:${getPort key}") (
                    builtins.filter (node: node.scrape.${key}) nodes
                  );
                }
              ];
            }
          ]
        else
          [ ];

      # Options for "nodes", that is, machines to monitor.
      nodeOptions = { name, ... }: {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "Host name or IP address for the node";
          };

          # NOTE: Keys in this set must also be in `self.lib.services`
          # prefixed by "prometheus-".
          scrape = {
            node = mkDefaultEnabledOption "Prometheus node exporter";
            systemd = mkDefaultEnabledOption "Prometheus systemd exporter";
          };
        };
      };

      # Generate scrape configuration for Prometheus.
      toScrapeConfigs = nodes: optionalScrape "node" nodes ++ optionalScrape "systemd" nodes;
    in
    {
      options.tilde.programs.prometheus-collector = {
        nodes = lib.mkOption {
          type = with lib.types; attrsOf (submodule nodeOptions);
          default = [ ];
          description = "List of nodes to monitor";
        };
      };

      config = {
        services.prometheus = {
          enable = true;
          port = self.lib.services.prometheus-collector;
          scrapeConfigs = toScrapeConfigs (builtins.attrValues cfg.nodes);
        };
      };
    }
  );
}
