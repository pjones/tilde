{ pkgs
, config
, lib
, ...
}:

{
  imports = [
    ./programs
    ./workstation
    ./xsession
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
      config.extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };

    # Custom activation scripts:
    home.activation.share-bookmarks =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.tilde-scripts-activation}/bin/share-bookmarks.sh
      '';
  };
}
