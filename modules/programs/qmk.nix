{ moduleWithSystem, ... }:
{
  flake.nixosModules.qmk = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      config = {
        hardware.keyboard.qmk.enable = true;
        services.udev.packages = [ pkgs.vial ];
        environment.systemPackages = [ pkgs.vial ];
      };
    }
  );
}
