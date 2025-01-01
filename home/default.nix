{ pkgs
, config
, lib
, ...
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
  };

  config = lib.mkIf config.tilde.enable {
    # Ensure consistent behavior:
    home.stateVersion = lib.mkDefault "24.11";

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
