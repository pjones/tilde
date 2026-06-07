{ moduleWithSystem, ... }:
{
  flake.homeModules.network-manager-applet = moduleWithSystem (
    { ... }:
    {
      config = {
        # Tray icon for network connections:
        services.network-manager-applet.enable = true;
      };
    }
  );
}
