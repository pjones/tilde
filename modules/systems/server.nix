{ ... }:
{
  # Sort by: C-u 3 M-x sort-numeric-fields
  flake.lib.services = {
    http = 80;
    https = 443;
    stun = 3478;
    adguardhome = 8082;
    vaultwarden = 8222;
    syncthing = 8384;
    tailscale = 8443;
    kanidm = 8445;
    wireguard = 51820;
  };
}
