{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.pjones = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde;

      sshPubKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXyxuLeosIPaFgV8M3JJlhk1vF/KTfNMnVrCtqH/aq0 sid"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKwxYPy97lzfVcrkLQ5gm1L7AhrvfUbXYbqiiP4tqNn4 falken"
      ];
    in
    {
      options.tilde = {
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

      config = {
        # This is needed to use ZSH as a login shell:
        programs.zsh.enable = true;

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
          extraGroups = cfg.extraGroups ++ lib.optional cfg.putInWheel "wheel";
        };

        home-manager.users.pjones = {
          home = {
            stateVersion = lib.mkDefault self.lib.state.version;
            username = cfg.username;
            homeDirectory = config.users.users.${cfg.username}.home;
          };
        };
      };
    }
  );
}
