{ moduleWithSystem, ... }:
{
  flake.homeModules.rbw = moduleWithSystem (
    { ... }:
    { config, ... }:
    {
      config = {
        programs.rbw = {
          enable = true;

          settings = {
            email = config.programs.git.settings.user.email;
            pinentry = config.services.gpg-agent.pinentry.package;
            lock_timeout = config.services.gpg-agent.defaultCacheTtl;
          };
        };
      };
    }
  );
}
