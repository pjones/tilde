{ config, lib, pkgs, ... }:
{
  config = lib.mkMerge [
    (lib.mkIf config.tilde.enable {
      home.packages = with pkgs; [
        bc
        bind # For dig(1)
        binutils
        coreutils
        cryptsetup
        curl
        file
        fzf
        gawk
        gnugrep
        gnumake
        gnupg
        gnutls
        htop
        inetutils
        jq
        libossp_uuid
        mkpasswd
        nix-prefetch-scripts
        openssh
        openssl
        pjones.image-scripts
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
    })

    (lib.mkIf (config.tilde.enable && pkgs.stdenv.isLinux) {
      home.packages = with pkgs; [
        inotify-tools
        procps
        psmisc
      ];
    })
  ];
}
