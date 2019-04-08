# User entry for pjones.
{ config, pkgs, lib, ... }:

with lib;

let
  sshPubKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOT7Ys7LyugF3A5wsJ1EH1CF9jAdihtSWrJskUtDACCR medusa"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1g7KoenMd6JIWnIuOQOYAaPNk6rF+6vwXBqNic2Juk elphaba"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKW//sdBipEzLP85H89J1a8ma4J5IRbhEL+3/jEDANk leota"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuiLy4mwlSXLn18H/8tTqCcfq0obMNkEQfU27AgJDdw slugworth"
  ];
in
{
  #### Additional Files:
  imports = [
    ./modules/shells.nix
    ./modules/wheel.nix
    ./modules/workstation
  ];

  #### Interface:
  options.pjones = {
    putInWheel = mkEnableOption "Allow access to the wheel group";
    isWorkstation = mkEnableOption "The current machine is a workstation, not a server.";
  };

  #### Implementation:
  config = {

    # A group just for me:
    users.groups.pjones = { };

    # And my user account:
    users.users.pjones = {
      isNormalUser = true;
      description = "Peter J. Jones";
      group = "pjones";
      createHome = true;
      home = "/home/pjones";
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = sshPubKeys;

      extraGroups = [
        "docker"
        "libvirtd"
        "users"
        "webhooks"
        "webmaster"
      ];

      # Base set of packages I want on all machines:
      packages = with pkgs; [
        (unison.override {enableX11 = false;})
        bc
        curl
        gitAndTools.gitAnnex
        gitAndTools.git
        gnupg
        gnutls
        htop
        inotifyTools
        jq
        lsscsi
        mkpasswd
        openssl
        parted
        pciutils
        pwgen
        rdiff-backup
        rsync
        tmux
        tree
        unzip
        usbutils
        wget
        zip
      ];
    };
  };
}
