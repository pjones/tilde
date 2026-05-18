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
          wireless.enable = false;

          networkmanager = {
            enable = true;
            plugins = with pkgs; [
              networkmanager-l2tp
              networkmanager-sstp
              networkmanager-vpnc
            ];
          };
        };
      };
    }
  );
}
