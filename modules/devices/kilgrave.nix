{
  self,
  moduleWithSystem,
  ...
}:
{
  flake.nixosModules.kilgrave = moduleWithSystem (
    { ... }:
    { ... }:
    {
      imports = with self.nixosModules; [
        basic
        tilde
      ];

      config = {
        networking.hostName = "kilgrave";

        home-manager.users.pjones = {
          imports = with self.homeModules; [
            basic
            syncthing
          ];
        };
      };
    }
  );

  perSystem = self.lib.nixos.checkHost "kilgrave";
}
