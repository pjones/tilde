{ moduleWithSystem, ... }:

{
  # Common settings for hardening a server.
  flake.nixosModules.server = moduleWithSystem (
    { ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.server;
    in
    {
      options.tilde.server = with lib; {
        openssh.groups = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "List of groups allowed to use SSH";
        };
      };

      config = {
        # Restrict access to Nix:
        nix.settings.allowed-users = [ "root" ];

        # Enable the audit log:
        security.auditd.enable = true;
        security.audit.enable = "lock";
        security.audit.rules = [ "-a exit,always -F arch=b64 -S execve" ];

        # Don't allow executable binaries except for in /nix/store:
        fileSystems."/".options = [ "noexec" ];

        # Further restrict OpenSSH:
        services.openssh = {
          settings.AllowStreamLocalForwarding = false;
          settings.AllowGroups = cfg.openssh.groups;
        };
      };
    }
  );

  # Sort by: C-u 3 M-x sort-numeric-fields
  flake.lib.services = {
    http = 80;
    https = 443;
    jellyfin-unknown = 1900; # NixOS opens this, not sure why
    immich = 2283;
    immich-ml = 3003;
    stun = 3478;
    redis = 6379;
    bitlbee = 6666;
    znc = 6667;
    jellyfin-discovery = 7359;
    miniflux = 8081;
    adguardhome = 8082;
    jellyfin-http = 8096;
    vaultwarden = 8222;
    syncthing = 8384;
    kanidm = 8445;
    jellyfin-https = 8920;
    prometheus-collector = 9090;
    prometheus-alertmanager = 9093;
    prometheus-node = 9100;
    prometheus-systemd = 9558;
    prometheus-immich-api = 9683;
    prometheus-immich-microservices = 9684;
    wireguard = 51820;
  };
}
