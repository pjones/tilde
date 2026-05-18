{ moduleWithSystem, ... }:
{
  flake.nixosModules.podman = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        virtualisation.podman = {
          enable = true;
          autoPrune.enable = true;
          dockerSocket.enable = true;
        };
      };
    }
  );
}
