{ config, pkgs, lib, ... }:
let
  cfg = config.tilde;

  sshPubKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOT7Ys7LyugF3A5wsJ1EH1CF9jAdihtSWrJskUtDACCR medusa"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1g7KoenMd6JIWnIuOQOYAaPNk6rF+6vwXBqNic2Juk elphaba"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKW//sdBipEzLP85H89J1a8ma4J5IRbhEL+3/jEDANk leota"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuiLy4mwlSXLn18H/8tTqCcfq0obMNkEQfU27AgJDdw slugworth"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDvJYnRo8tjxq9CaPaIhdYmMfZotfUJ/pxopRcd0Rd6Bp7CMgcTEPschA4Bn77kHT35XiAoGrpkW1exEbdfhfPFV1r8Eo3/gYxrkfJ34IWXtncCDXZDLuiykuKi3MpidOY2YzLTYW+SeppcUskujsytyKf1NYuT1sYQLe3GgkJzZvg+ZtsIDSeFSKfrTQ+yRdyUKPKNPCdXLEMVMCorDwxpdYYZEf+SJTFrBwieyPViIBBvgJRT6+FsyC+x6ivTVXF0ZQ9c4aFDlIBd1QHdyMHjTgYE9uyPLQdIsi9dqlZSkxpH04sWfOCZKp201ip8HdkfCYvPMJ/K3AhpNpTydfQn"
  ];
in
{
  #### Additional Files:
  imports = [
    ./crontab.nix
    ./workstation.nix
    ./xsession.nix
    ./yubikey.nix
  ];

  #### Interface:
  options.tilde = {
    enable = lib.mkEnableOption "Create and configure a user account";
    putInWheel = lib.mkEnableOption "Allow access to the wheel group";

    username = lib.mkOption {
      type = lib.types.str;
      default = "pjones";
      description = "The username to use.";
    };

    extraGroups = lib.mkOption {
      type = with lib.types; listOf str;
      default = [
        "cdrom"
        "dialout"
        "disk"
        "docker"
        "input"
        "libvirtd"
        "media"
        "networkmanager"
        "scanner"
        "users"
        "video"
        "webhooks"
        "webmaster"
      ];
      description = "Extra groups for the user account";
    };
  };

  #### Implementation:
  config = lib.mkMerge
    [
      (lib.mkIf cfg.enable {
        # Basic security:
        networking.firewall.enable = true;

        # I want firmware updates:
        hardware.enableRedistributableFirmware = true;

        # Basic setup for nix and nixpkgs:
        nix = {
          nixPath = [ "nixpkgs=${pkgs.path}" ];
          extraOptions = ''
            experimental-features = nix-command flakes
          '';
        };

        nixpkgs.config = {
          allowUnfree = true; # Proprietary drivers :(
        };

        # Packages to install on all machines for all users:
        environment.systemPackages = with pkgs; [
          lsscsi
          parted
          pciutils
          smartmontools
          usbutils
        ];

        programs.zsh = {
          enable = true;
          enableCompletion = true;
          syntaxHighlighting.enable = true;
        };

        # A group just for me:
        users.groups.${cfg.username} = { };

        # And my user account:
        users.users.${cfg.username} = {
          isNormalUser = true;
          description = "Peter J. Jones";
          group = cfg.username;
          createHome = true;
          home = "/home/${cfg.username}";
          shell = pkgs.zsh;
          openssh.authorizedKeys.keys = sshPubKeys;
          extraGroups = cfg.extraGroups ++
            lib.optional cfg.putInWheel "wheel";
        };
      })

      ({
        home-manager.users.${cfg.username} = { ... }: {
          config = lib.mkIf cfg.enable {
            # Propagate some settings into home-manager:
            home.username = cfg.username;
            home.homeDirectory = config.users.users.${cfg.username}.home;
            tilde.enable = cfg.enable;
            tilde.xsession.enable = cfg.xsession.enable;
            tilde.workstation.enable = cfg.workstation.enable;
          };
        };
      })
    ];
}
