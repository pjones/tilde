{ moduleWithSystem, ... }:
{
  flake.nixosModules.gnome-keyring = moduleWithSystem (
    { ... }:
    { ... }:
    {
      services.gnome.gnome-keyring.enable = true;
    }
  );

  flake.homeModules.gnome-keyring = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      home.packages = with pkgs; [
        libsecret
        lssecret
        seahorse
      ];
    }
  );
}
