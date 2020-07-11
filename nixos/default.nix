# User entry for pjones.
{ config, pkgs, lib, ... }:
let
  cfg = config.pjones;

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
    ./keyboard.nix
    ./workstation.nix
    ./xsession.nix
    ./yubikey.nix
  ];

  #### Interface:
  options.pjones = {
    enable = lib.mkEnableOption "Create and configure an account for Peter";
    putInWheel = lib.mkEnableOption "Allow access to the wheel group";

    extraGroups = lib.mkOption {
      type = with lib.types; listOf str;
      default = [
        "cdrom"
        "dialout"
        "disk"
        "docker"
        "libvirtd"
        "networkmanager"
        "scanner"
        "users"
        "webhooks"
        "webmaster"
      ];
      description = "Extra groups for the pjones user";
    };
  };

  #### Implementation:
  config = lib.mkIf cfg.enable {
    # Required nixpkgs settings:
    nixpkgs = {
      overlays = lib.singleton (import ../overlays);

      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
    };

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
      extraGroups = cfg.extraGroups ++
        lib.optional cfg.putInWheel "wheel";
    };

    home-manager = {
      backupFileExtension = "backup";
      users.pjones = { ... }: {
        imports = [ ../home ];

        config = {
          # Propagate some settings into home-manager:
          pjones.xsession.enable = cfg.xsession.enable;
          pjones.workstation.enable = cfg.workstation.enable;
        };
      };
    };
  };
}
