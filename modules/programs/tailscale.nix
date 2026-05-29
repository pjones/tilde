{ ... }:
{
  flake.nixosModules.tailscale =
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.tailscale;
      stunPort = 3478;
      serverURL = "https://${cfg.server.domain}:${toString cfg.server.port}";

      sslCertDomain =
        if cfg.server.useACMEHost != null then cfg.server.useACMEHost else cfg.server.domain;
      sslCertDir = config.security.acme.certs.${sslCertDomain}.directory;
    in
    {
      options.tilde.programs.tailscale = {
        server = {
          enable = lib.mkEnableOption "Enable the tailscale server";

          domain = lib.mkOption {
            type = lib.types.str;
            default = "tailscale.${config.networking.domain}";
            description = "Domain where the tailscale server lives";
          };

          private = lib.mkOption {
            type = lib.types.str;
            default = "private.${config.networking.domain}";
            description = ''
              Domain to use for host names that route to other
              tailscale clients.
            '';
          };

          useACMEHost = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              A host of an existing Let's Encrypt certificate to use.
            '';
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 8443;
            description = "Internal VPN port number";
          };

          derp = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Run a DERP server";
            };
          };

          addrs = {
            ipv4 = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = ''
                IPv4 address.  Used for the DERP server.
              '';
            };

            ipv6 = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = ''
                IPv6 address.  Used for the DERP server.
              '';
            };
          };

          nameservers = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = ''
              List of DNS servers to advertise to clients.
            '';
          };

          networkMask = lib.mkOption {
            type = lib.types.str;
            default = "100.64.0.0/10";
            description = ''
              The network mask for the private network.  Also used for the DHCP pool.
            '';
          };
        };

        client = {
          enable = lib.mkEnableOption "Configure the VPN client";
          exitNode = lib.mkEnableOption "Configure as an exit node";

          keyFile = lib.mkOption {
            type = lib.types.path;
            description = ''
              Path to a file containing the authentication key.
            '';
          };

          interface = lib.mkOption {
            type = lib.types.str;
            default = "tailscale0";
            description = ''
              The name of the network interface to create for the VPN.
            '';
          };
        };
      };

      config = lib.mkMerge [

        ############################################################################
        # Headscale server:
        (lib.mkIf cfg.server.enable {
          services.headscale = {
            enable = true;
            address = "0.0.0.0";
            port = cfg.server.port;

            settings = {
              server_url = serverURL;
              log.level = "debug";
              magic_dns = true;
              prefixes.v4 = cfg.server.networkMask;

              dns = {
                magic_dns = true;
                base_domain = cfg.server.private;
                override_local_dns = builtins.length cfg.server.nameservers > 0;
                nameservers.global = cfg.server.nameservers;
              };

              derp.server = lib.mkIf cfg.server.derp.enable {
                enabled = true;
                stun_listen_addr = "0.0.0.0:${toString stunPort}";
                ipv4 = cfg.server.addrs.ipv4;
                ipv6 = cfg.server.addrs.ipv6;
              };

              tls_cert_path = "${sslCertDir}/fullchain.pem";
              tls_key_path = "${sslCertDir}/key.pem";
            };
          };

          networking.firewall = {
            allowedTCPPorts = [ cfg.server.port ];
            allowedUDPPorts = lib.optional cfg.server.derp.enable stunPort;
          };

          security.acme.certs.${sslCertDomain} =
            let
              allCerts = {
                reloadServices = [ "headscale.service" ];
              };
              ownCert = allCerts // {
                group = lib.mkDefault config.services.headscale.group;
              };
              otherCert = allCerts // {
                extraDomainNames = [ cfg.server.domain ];
              };
            in
            if cfg.server.useACMEHost != null then otherCert else ownCert;
        })

        ############################################################################
        # Client:
        (lib.mkIf cfg.client.enable {
          services.tailscale = {
            enable = true;
            interfaceName = cfg.client.interface;
            openFirewall = true;
            disableUpstreamLogging = true;

            extraUpFlags = [
              "--login-server"
              serverURL

              "--ssh=false"
            ]
            ++ lib.optionals cfg.client.exitNode [
              "--advertise-exit-node"
            ];

            useRoutingFeatures = if cfg.client.exitNode then "server" else "none";
            authKeyFile = cfg.client.keyFile;
          };

          # Make sure OpenSSH is accessible:
          networking.firewall.interfaces.${cfg.client.interface} = {
            allowedTCPPorts = config.services.openssh.ports;
          };
        })

        ############################################################################
        # Client AND server:
        (lib.mkIf (cfg.server.enable && cfg.client.enable) {
          systemd.services.tailscaled-autoconnect.after = [ "headscale.service" ];
          services.tailscale.extraUpFlags = [ "--accept-dns=false" ];
        })
      ];
    };
}
