{
  self,
  moduleWithSystem,
  ...
}:

{
  flake.nixosModules.slugworth = moduleWithSystem (
    { ... }:
    { ... }:
    {
      imports = with self.nixosModules; [
        basic
        tilde
      ];

      config = {
        networking.hostName = "slugworth";

        home-manager.users.pjones = {
          imports = with self.homeModules; [
            basic
            syncthing
          ];
        };
      };
    }
  );

  perSystem = self.lib.nixos.checkHost "slugworth";
}
