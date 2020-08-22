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

    # Packages to install on all devices:
    home.packages = with pkgs;
      [
        # FIXME: Some of these (direnv) have special options in home-manager.
        direnv

        bc
        curl
        gawk
        gnumake
        gnupg
        gnutls
        htop
        jq
        libossp_uuid
        mkpasswd
        nix-prefetch-scripts
        openssl
        pjones.network-scripts
        pwgen
        rdiff-backup
        rsync
        tmux
        tree
        unzip
        vim
        wget
        which
        zip
      ];
  };
}
