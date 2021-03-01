{ pkgs, ... }:
let
  base = with pkgs; [
    bc
    bind # For dig(1)
    binutils
    coreutils
    cryptsetup
    curl
    file
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
    pjones.network-scripts
    pjones.image-scripts
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

  linux = base ++ (with pkgs; [
    inotify-tools
    procps
    psmisc
  ]);

in
{
  inherit base linux;
}
