# Build a cache database for man(1).
{ pkgs, config, lib, ... }:
let
  cacheDir = "${config.xdg.cacheHome}/man";

  script =
    let path = with pkgs; [ coreutils gnused man-db ];
    in
    pkgs.writeShellScript "user-mandb-cache" ''
      export PATH=${lib.concatMapStringsSep ":" (p: "${p}/bin") path}:$PATH
      ${builtins.readFile ../../scripts/mandb.sh}
    '';
in
{
  config = lib.mkIf config.tilde.enable {
    home.activation = {
      build-man-db-cache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${script} ${cacheDir}
      '';
    };
  };
}
