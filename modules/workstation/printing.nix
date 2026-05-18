{ moduleWithSystem, ... }:
{
  flake.nixosModules.printing = moduleWithSystem (
    { pkgs, ... }:
    { lib, ... }:
    {
      config = {
        services.printing = {
          enable = true;
          browsing = true;
          drivers = lib.optional pkgs.stdenv.isx86_64 pkgs.cups-kyodialog;

          browsedConf = ''
            BrowseDNSSDSubTypes _cups,_print
            BrowseLocalProtocols all
            BrowseRemoteProtocols all
            CreateIPPPrinterQueues All
            BrowseProtocols all
          '';
        };
      };
    }
  );
}
