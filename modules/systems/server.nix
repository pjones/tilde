{ ... }:
{
  # Sort by: C-u 3 M-x sort-numeric-fields
  flake.lib.services = {
    http = 80;
    https = 443;
    stun = 3478;
    znc = 6667;
    adguardhome = 8082;
    vaultwarden = 8222;
    syncthing = 8384;
    tailscale = 8443;
    kanidm = 8445;
    prometheus-collector = 9090;
    prometheus-alertmanager = 9093;
    prometheus-node = 9100;
    prometheus-systemd = 9558;
    wireguard = 51820;
  };
}
