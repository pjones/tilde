{ config, pkgs, lib, ... }:
let
  cfg = config.tilde;

  sshPubKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXyxuLeosIPaFgV8M3JJlhk1vF/KTfNMnVrCtqH/aq0 sid"
  ];
in
{
  #### Additional Files:
  imports = [
    ./crontab.nix
    ./graphical.nix
    ./workstation.nix
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

    email = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The email address of the primary user.";
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

        # Packages to install on all machines for all users:
        environment.systemPackages = with pkgs; [
          lsscsi
          parted
          pciutils
          smartmontools
          usbutils
        ];

        # Monitor the SMART status on compatible drives:
        # See: smartd.conf(5)
        services.smartd = {
          enable = true;
          autodetect = true;
          defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";

          notifications = {
            mail = {
              enable = cfg.email != null;
              sender = cfg.email;
              recipient = cfg.email;
            };
          };
        };

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
            tilde.workstation.enable = cfg.workstation.enable;
          };
        };
      })
    ];
}
