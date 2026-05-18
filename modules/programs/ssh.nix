{ moduleWithSystem, ... }:
{
  flake.homeModules.ssh = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.ssh;

      askpass = pkgs.writeShellScript "ssh-askpass-wrapper" ''
        export WAYLAND_DISPLAY="$(systemctl --user show-environment | ${pkgs.gnused}/bin/sed 's/^WAYLAND_DISPLAY=\(.*\)/\1/; t; d')"
        exec ${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass "$@"
      '';
    in
    {
      options.tilde.programs.ssh = {
        askpass = lib.mkOption {
          type = lib.types.path;
          default = askpass;
          description = "Path to a script to use as ssh-askpass";
        };

        keysDir = lib.mkOption {
          type = lib.types.str;
          default = "~/.ssh";
          description = "Directory where SSH private keys are stored.";
        };
      };

      config = {
        # Agent config:
        services.ssh-agent.enable = true;

        systemd.user.services.ssh-agent.Service.Environment = [
          "SSH_ASKPASS=${cfg.askpass}"
          "DISPLAY=:0" # required to make ssh-agent start $SSH_ASKPASS
        ];

        home.sessionVariables = {
          SSH_ASKPASS = cfg.askpass;
          SSH_ASKPASS_REQUIRE = "prefer";

          # Hack around https://github.com/nix-community/home-manager/issues/8129
          SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/${config.services.ssh-agent.socket}";
        };

        # SSH config:
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;

          matchBlocks = {
            "webmaster.jonesbunch.com" = {
              user = "webmaster";
              identityFile = "${cfg.keysDir}/webmaster.id_ed25519";
            };

            "*" = {
              hashKnownHosts = false;
              userKnownHostsFile = "~/.ssh/known_hosts";
              forwardAgent = false;
              controlMaster = "auto";
              controlPath = "~/.ssh/master-%r@%h:%p";
              controlPersist = "no";
              addKeysToAgent = "yes";
              serverAliveInterval = 300;
              serverAliveCountMax = 5;
              identitiesOnly = true;

              identityFile = [
                "${cfg.keysDir}/%l.id_ed25519"
                "${cfg.keysDir}/deploy.id_ed25519"
              ];

              extraOptions = {
                ConnectionAttempts = "120";
                TCPKeepAlive = "no";
              };
            };
          };
        };
      };
    }
  );
}
