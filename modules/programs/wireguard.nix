{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.wireguard = moduleWithSystem (
    { pkgs, system, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.wireguard;

      jsonFile = pkgs.writeText "wg.json" (builtins.toJSON cfg);

      configFile = pkgs.runCommand "wg.conf" { } ''
        ${self.packages.${system}.wg-gen}/bin/wg-gen-wg0.sh \
          "${config.networking.hostName}" \
          "${jsonFile}" > $out
      '';

      exitFile =
        peer:
        pkgs.runCommand "${peer.name}.conf" { } ''
          ${self.packages.${system}.wg-gen}/bin/wg-gen-exit.sh \
            "${config.networking.hostName}" \
            "${peer.name}" \
            "${jsonFile}" > $out
        '';

      peerOptions = { ... }: {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "The host name for this peer";
          };

          octet = lib.mkOption {
            type = lib.types.ints.u8;
            description = "The last octet of this peer's IPv4 address";
          };

          type = lib.mkOption {
            type = lib.types.enum [
              "leaf"
              "exit"
              "router"
            ];
            default = "leaf";
            description = ''
              The role played by this node.

              - `leaf`:

                Normal peer that may or may not be running network services.  By
                default can only be reached from a router.  However, if it has a
                routable IP address then setting `hostname` will allow peers to
                connect directly.

              - `exit`:

                A peer that serve as an exit node, thus all network traffic can be
                routed through this node.  Must have a `hostname`.

              - `router`:

                A peer that runs a DNS server and can route traffic for other peers
                when they cannot reach one another.  Must have a `hostname`.
            '';
          };

          key = lib.mkOption {
            type = lib.types.str;
            description = "The public key for this peer";
          };

          hostname = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            description = ''
              A DNS name that can be used to find this peer.  When
              this option is `null` this peer can only be found
              through one of the router nodes.
            '';
          };

          nameservers = lib.mkOption {
            type = with lib.types; nullOr (listOf str);
            default = null;
            description = ''
              When `dnsFromRouter` is `true` and traffic is going through this
              router or exit node, use the given DNS servers.

              If this setting is `null` (the default) set the router's address as
              the DNS server.
            '';
          };

          networks = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = ''
              Additional network masks for networks that should be
              routed through this peer.
            '';
          };
        };
      };

      # Return the peer record for the named host.
      getPeer = host: peers: builtins.head (builtins.filter (peer: peer.name == host) peers);

      # All exit peers that are not the current peer.
      exitPeers =
        host: peers:
        builtins.filter (peer: (peer.type == "router" || peer.type == "exit") && peer.name != host) peers;

      peerIP = peer: "${cfg.prefix}.${toString peer.octet}";
      me = getPeer config.networking.hostName cfg.peers;
      exits = exitPeers config.networking.hostName cfg.peers;
      externalInterface = config.networking.nat.externalInterface;
      mask = "${cfg.prefix}.0/24";
    in
    {
      options.tilde.programs.wireguard = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "wg0";
          description = "The primary network name";
        };

        prefix = lib.mkOption {
          type = lib.types.str;
          default = "10.11.12";
          description = "The network prefix used for assigning IP addresses";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = self.lib.services.wireguard;
          description = "The port number to listen on";
        };

        privateKeyFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to a file containing the private key";
        };

        dnsFromRouter = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Use the DNS server on the router";
        };

        peers = lib.mkOption {
          type = with lib.types; listOf (submodule peerOptions);
          default = [ ];
          description = "List of peers";
        };
      };

      config = lib.mkMerge [
        # Configure the main interface and peers.  This runs on all
        # peers.
        (lib.mkIf (builtins.length cfg.peers > 0) {
          tilde.privateInterface = peerIP me;
          tilde.networkWait = lib.singleton "wg-quick-${cfg.name}.service";

          networking.firewall.allowedUDPPorts = [ cfg.port ];
          networking.firewall.trustedInterfaces = [ cfg.name ];

          networking.wg-quick.interfaces.${cfg.name} = {
            configFile = toString configFile;
          };

          # On hosts using NetworkManager, wait for the network to be
          # available so I don't have to restart WireGuard.
          systemd.services."wg-quick-${cfg.name}" = lib.mkIf config.networking.networkmanager.enable {
            requires = [ "NetworkManager-wait-online.service" ];
            after = [ "NetworkManager-wait-online.service" ];
          };
        })

        # Only routers and exit nodes need special networking
        # configuration.
        (lib.mkIf (builtins.length cfg.peers > 0 && (me.type == "router" || me.type == "exit")) {
          boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

          networking.nat = {
            enable = true;
            internalInterfaces = [ cfg.name ];
          };

          networking.wg-quick.interfaces.${cfg.name} = {
            postUp = ''
              ${pkgs.iptables}/bin/iptables \
                -A FORWARD -i ${cfg.name} -j ACCEPT

              ${pkgs.iptables}/bin/iptables \
                -t nat -A POSTROUTING -s ${mask} -o ${externalInterface} -j MASQUERADE
            '';

            preDown = ''
              ${pkgs.iptables}/bin/iptables \
                -D FORWARD -i ${cfg.name} -j ACCEPT

              ${pkgs.iptables}/bin/iptables \
                -t nat -D POSTROUTING -s ${mask} -o ${externalInterface} -j MASQUERADE
            '';
          };
        })

        # Configure private names in the AdGuard Home DNS server:
        (lib.mkIf config.services.adguardhome.enable {
          services.adguardhome.settings.filtering.rewrites = builtins.concatMap (peer: [
            {
              domain = "${peer.name}.private.${config.networking.domain}";
              answer = peerIP peer;
              enabled = true;
            }
            {
              domain = peer.name;
              answer = peerIP peer;
              enabled = true;
            }
          ]) cfg.peers;
        })

        # Configure special WireGuard interfaces on leafs so they can
        # access exit nodes.
        (lib.mkIf (builtins.length exits > 0 && me.type == "leaf") {
          networking.wg-quick.interfaces = builtins.listToAttrs (
            map (peer: {
              name = peer.name;
              value = {
                autostart = false;
                configFile = toString (exitFile peer);
              };
            }) exits
          );

          # Mark all the exit services as conflicting with the main
          # service.
          systemd.services."wg-quick-${cfg.name}".conflicts = map (
            peer: "wg-quick-${peer.name}.service"
          ) exits;
        })
      ];
    }
  );
}
