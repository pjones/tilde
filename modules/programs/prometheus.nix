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
    { system, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.prometheus-collector;

      # Like `lib.mkEnableOption` except the default is `true`.
      mkDefaultEnabledOption = str: lib.mkEnableOption str // { default = true; };

      # Return the port number for the given service as a string.
      getPort = key: toString self.lib.services."prometheus-${key}";

      # Add a port number to the given host name.
      addPort =
        key: host:
        let
          name = if builtins.isAttrs host then host.host else host;
        in
        "${name}:${getPort key}";

      # Generate the repetitive static_configs craziness.
      mkStaticConfigs =
        outside: inside:
        outside
        // {
          static_configs = [ inside ];
        };

      # Relabel an instance so it no longer has the port number in it.
      relabelInstance = {
        source_labels = [ "__address__" ];
        regex = "([^:]+):[0-9]+";
        target_label = "instance";
        replacement = "$1";
      };

      # Create a static_configs with a targets value.
      mkTargets = outside: targets: mkStaticConfigs outside { inherit targets; };

      # Return a scrape config for the given service containing all
      # nodes that have that service enabled.
      optionalScrape =
        key: nodes:
        if builtins.any (node: node.scrape.${key}) nodes then
          lib.singleton (
            mkTargets {
              job_name = key;
              relabel_configs = lib.singleton relabelInstance;
            } (map (addPort key) (builtins.filter (node: node.scrape.${key}) nodes))
          )
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

        alertmanagers = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
          description = "List of host names that are alert managers";
        };
      };

      config = {
        services.prometheus = {
          enable = true;
          port = self.lib.services.prometheus-collector;
          scrapeConfigs = toScrapeConfigs (builtins.attrValues cfg.nodes);
          ruleFiles = lib.singleton "${self.packages.${system}.prometheus-extra}/alerts.yml";
          alertmanagers = lib.optional (builtins.length cfg.alertmanagers > 0) (
            mkTargets { } (map (addPort "alertmanager") cfg.alertmanagers)
          );
        };
      };
    }
  );

  # https://prometheus.io/docs/alerting/latest/configuration/
  flake.nixosModules.prometheus-alertmanager = moduleWithSystem (
    { ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.prometheus-alertmanager;
    in
    {
      options.tilde.programs.prometheus-alertmanager = {
        receivers = lib.mkOption {
          type = with lib.types; nonEmptyListOf (attrsOf anything);
          default = [ ];
          description = ''
            List of receiver configuration options.
            See the following URL for more details:

            https://prometheus.io/docs/alerting/latest/configuration/#receiver
          '';
        };
      };

      config = {
        services.prometheus.alertmanager = {
          enable = true;
          port = self.lib.services.prometheus-alertmanager;

          configuration = {
            route = {
              receiver = "default";

              group_by = [
                "alertname"
                "instance"
              ];

              group_wait = "30s";
              group_interval = "5m";
              repeat_interval = "2h";
            };

            receivers = cfg.receivers;
          };
        };
      };
    }
  );
}
