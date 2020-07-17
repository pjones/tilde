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
    home.activation = {
      share-bookmarks = lib.hm.dag.entryAfter [ "writeBoundary" ]
        (builtins.readFile ../scripts/share-bookmarks.sh);
    };

    # Packages to install on all devices:
    home.packages = with pkgs;
      [
        # FIXME: Pull out packages that only work on Linux.

        # FIXME: Some of these (direnv) have special options in home-manager.
        direnv

        bc
        curl
        gitAndTools.git
        gnumake
        gnupg
        gnutls
        htop
        inotifyTools
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
