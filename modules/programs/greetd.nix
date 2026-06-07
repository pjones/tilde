{ moduleWithSystem, ... }:
{
  flake.nixosModules.greetd = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      config = {
        services.greetd = {
          enable = true;
          restart = true;

          settings.default_session = {
            command = "${pkgs.greetd}/bin/agreety --cmd niri-session";
          };
        };
      };
    }
  );
}
