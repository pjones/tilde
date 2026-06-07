{ moduleWithSystem, ... }:
{
  flake.nixosModules.sound = moduleWithSystem (
    { ... }:
    {
      config = {
        services.pipewire.enable = true;
        services.pipewire.pulse.enable = true;
        services.pipewire.alsa.enable = true;
      };
    }
  );
}
