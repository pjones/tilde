{ moduleWithSystem, ... }:
{
  flake.nixosModules.networking = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      config = {
        networking = {
          nat.enable = true;
          useDHCP = false;

          networkmanager = {
            enable = true;

            # Might as well install them all since I don't know which
            # one my university is using.
            plugins = with pkgs; [
              networkmanager-iodine
              networkmanager-l2tp
              networkmanager-libreswan
              networkmanager-openconnect
              networkmanager-openvpn
              networkmanager-ssh
              networkmanager-strongswan
            ];
          };
        };
      };
    }
  );
}
