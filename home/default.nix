{ pkgs
, config
, lib
, ...
}:

{
  imports = [
    ./programs
    ./xsession
    ./workstation
  ];

  options.tilde = {
    enable = lib.mkEnableOption "Enable setings for tilde";
  };

  config = lib.mkIf config.tilde.enable {
    # Ensure consistent behavior:
    home.stateVersion = "20.09";

    nixpkgs = {
      config.allowUnfree = true;
      config.android_sdk.accept_license = true;
      overlays = [ (import ../overlays) ];
    };

    # Custom activation scripts:
    home.activation.share-bookmarks =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.tilde-scripts-activation}/bin/share-bookmarks.sh
      '';
  };
}
