{ moduleWithSystem, ... }:
{
  flake.nixosModules.flatpack = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      config = {
        # Flatpak:
        #
        # https://wiki.nixos.org/wiki/Flatpak
        services.flatpak.enable = true;
        systemd.services.flatpak-repo = {
          after = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          path = [ pkgs.flatpak ];
          script = ''
            flatpak remote-add --if-not-exists \
              flathub https://dl.flathub.org/repo/flathub.flatpakrepo
          '';
        };
      };
    }
  );
}
