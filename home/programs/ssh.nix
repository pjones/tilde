{ pkgs, config, options, lib, ... }:
let
  cfg = config.tilde.programs.ssh;


  askpass = pkgs.writeShellScript "ssh-askpass-wrapper" ''
    export WAYLAND_DISPLAY="$(systemctl --user show-environment | ${pkgs.gnused}/bin/sed 's/^WAYLAND_DISPLAY=\(.*\)/\1/; t; d')"
    exec ${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass "$@"
  '';
in
{
  options.tilde.programs.ssh = {
    keysDir = lib.mkOption {
      type = lib.types.str;
      default = "~/.ssh";
      description = "Directory where SSH private keys are stored.";
    };

    haveRestrictedKeys = lib.mkEnableOption ''
      Does this host have access to the extra set of SSH keys that I
      use to access restricted servers?
    '';
  };

  config = lib.mkMerge [
    (lib.mkIf config.tilde.enable {
      services.ssh-agent.enable = true;
      systemd.user.services.ssh-agent.Service.Environment = [
        "SSH_ASKPASS=${askpass}"
        "DISPLAY=fake" # required to make ssh-agent start $SSH_ASKPASS
      ];

      programs.ssh = {
        enable = true;

        controlMaster = "auto";
        controlPath = "~/.ssh/master-%r@%h:%p";
        addKeysToAgent = "yes";
        serverAliveInterval = 300;
        serverAliveCountMax = 5;

        extraConfig = ''
          User pjones
          TCPKeepAlive no
        ''
        + lib.optionalString
          (cfg.keysDir != options.tilde.programs.ssh.keysDir.default) ''
          IdentitiesOnly yes
          IdentityFile ${cfg.keysDir}/%l.id_ed25519
        ''
        + lib.optionalString cfg.haveRestrictedKeys ''
          IdentityFile ${cfg.keysDir}/deploy.id_ed25519
        '';

        matchBlocks =
          let pmade = { port = 4; };
          in
          {
            "*.pmade.com" = pmade;
            "*.devalot.com" = pmade;
          } // lib.optionalAttrs cfg.haveRestrictedKeys {
            "webmaster.ursula.pmade.com" = {
              inherit (pmade) port;
              hostname = "10.11.12.3";
              user = "webmaster";
              identityFile = "${cfg.keysDir}/webmaster.id_ed25519";
            };
          };
      };
    })
    (lib.mkIf config.tilde.enable {
      programs.ssh.matchBlocks = {
        "noscience.net" = {
          hostname = "node0.noscience.net";
          port = 2222;
        };
      };
    })
  ];
}
