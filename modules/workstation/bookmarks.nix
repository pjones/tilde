{ self, moduleWithSystem, ... }:
{
  flake.homeModules.bookmarks = moduleWithSystem (
    { system, ... }:
    { config, lib, ... }:
    let
      tilde-scripts-activation = self.packages.${system}.tilde-scripts-activation;
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
