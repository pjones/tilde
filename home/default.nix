{ pkgs
, ...
}:

{
  imports = [
    ./programs
    ./xsession
    ./workstation
  ];

  config = {
    # Packages to install on all devices:
    home.packages = with pkgs;
      [
        # FIXME: Pull out packages that only work on Linux.

        # FIXME: Some of these (direnv) have special options in home-manager.
        direnv

        # apacheHttpd # For htpasswd :(
        bc
        # bind # For dig(1)
        binutils
        coreutils
        cryptsetup
        curl
        file
        gitAndTools.git
        gnumake
        gnupg
        gnutls
        htop
        inetutils
        inotifyTools
        jq
        libossp_uuid
        lsscsi
        mkpasswd
        nix-prefetch-scripts
        openssl
        parted
        pciutils
        pjones.network-scripts
        psmisc
        pwgen
        rdiff-backup
        rsync
        tmux
        tree
        unzip
        usbutils
        vim
        wget
        which
        zip
      ];
  };
}
