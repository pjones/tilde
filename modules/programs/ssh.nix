{ lib, moduleWithSystem, ... }:
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

          settings = {
            "Host webmaster.jonesbunch.com" = {
              User = "webmaster";
              IdentityFile = "${cfg.keysDir}/webmaster.id_ed25519";
            };

            "Host *" = {
              HashKnownHosts = false;
              UserKnownHostsFile = "~/.ssh/known_hosts";
              ForwardAgent = false;
              ControlMaster = "auto";
              ControlPath = "~/.ssh/master-%r@%h:%p";
              ControlPersist = "no";
              AddKeysToAgent = "yes";
              ServerAliveInterval = 300;
              ServerAliveCountMax = 5;
              IdentitiesOnly = true;
              ConnectionAttempts = "120";
              TCPKeepAlive = "no";

              IdentityFile = [
                "${cfg.keysDir}/%l.id_ed25519"
                "${cfg.keysDir}/deploy.id_ed25519"
              ];
            };
          };
        };
      };
    }
  );

  flake.lib.ssh = {
    # Return a public SSH key that can be added to authorized keys.
    # It has the requested restrictions added it.
    mkRestrictedKey =
      {
        # The public key.
        key,

        # List of network masks.  The returned key will only allow
        # connections from the listed networks.
        netmasks ? [ ],

        # Other restrictions to add.  See the "AUTHORIZED_KEYS FILE
        # FORMAT" section in sshd(8).
        restrictions ? [ ],
      }:
      let
        parts = lib.splitString " " key;
        fingerprint = builtins.elemAt parts 1;
        keyType = builtins.elemAt parts 0;
        description = builtins.elemAt parts 2;
        from = lib.concatStringsSep "," netmasks;
      in
      (lib.concatStringsSep " " [
        (lib.concatStringsSep "," (
          [
            "restrict"
            ''from="${from}"''
          ]
          ++ restrictions
        ))
        keyType
        fingerprint
        description
      ]);
  };
}
