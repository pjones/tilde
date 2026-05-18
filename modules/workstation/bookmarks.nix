{ self, moduleWithSystem, ... }:
{
  flake.homeModules.bookmarks = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      tilde-scripts-activation =
        self.packages.${pkgs.stdenv.hostPlatform.system}.tilde-scripts-activation;
    in
    {
      config = {
        # Custom activation scripts:
        home.activation.share-bookmarks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir --mode 0750 --parents ${config.home.homeDirectory}/notes/bookmarks
          ${tilde-scripts-activation}/bin/share-bookmarks.sh
        '';
      };
    }
  );
}
