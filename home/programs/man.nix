# Build a cache database for man(1).
{ pkgs, config, lib, ... }:
let
  cfg = config.tilde.programs.man;
  cacheDir = "${config.xdg.cacheHome}/man";
  script = "${pkgs.tilde-scripts-activation}/bin/create-mandb-cache.sh";
in
{
  options.tilde.programs.man = {
    enable = lib.mkEnableOption "The mandb database";
  };

  config = lib.mkIf cfg.enable {
    home.activation.build-man-db-cache =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${script} ${cacheDir}
      '';
  };
}
