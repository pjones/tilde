# Build a cache database for man(1).
{ pkgs, config, lib, ... }:
let
  cacheDir = "${config.xdg.cacheHome}/man";
  script = "${pkgs.tilde-scripts-activation}/bin/create-mandb-cache.sh";
in
{
  config = lib.mkIf config.tilde.enable {
    home.activation.build-man-db-cache =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${script} ${cacheDir}
      '';
  };
}
