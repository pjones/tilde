{ ... }:
{
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
