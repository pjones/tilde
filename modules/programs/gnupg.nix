{ moduleWithSystem, ... }:
{
  flake.homeModules.gnupg = moduleWithSystem (
    { pkgs, ... }:
    { config, ... }:
    {
      config = {
        programs.gpg = {
          enable = true;
          homedir = "${config.home.homeDirectory}/keys/gpg";
          settings = {
            default-key = "4D0CD0756F1B8B9D3DCD0CAAE1CF584F79D0D3DC";
            default-recipient-self = true;
          };
        };

        services.gpg-agent = {
          enable = true;
          enableSshSupport = false;
          defaultCacheTtl = 3600;
          defaultCacheTtlSsh = 14400;
          maxCacheTtl = 7200;
          maxCacheTtlSsh = 21600;
          pinentry.package = pkgs.pinentry-qt;
        };
      };
    }
  );
}
