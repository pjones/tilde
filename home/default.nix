{
  pkgs,
  config,
  lib,
  ...
}:

{
  imports = [
    ./graphical.nix
    ./mail
    ./programs
    ./workstation.nix
  ];

  options.tilde = {
    enable = lib.mkEnableOption "Enable setings for tilde";

    createBookmarksDir = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Ensure the bookmarks directory is set up.";
    };
  };

  config = lib.mkIf config.tilde.enable {
    # Ensure consistent behavior:
    home.stateVersion = lib.mkDefault "24.11";

    # Custom activation scripts:
    home.activation.share-bookmarks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.optionalString config.tilde.createBookmarksDir ''
        run mkdir --mode 0750 --parents ${config.home.homeDirectory}/notes/bookmarks
      ''}
      ${pkgs.tilde-scripts-activation}/bin/share-bookmarks.sh
    '';
  };
}
