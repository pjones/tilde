{ pkgs, config, options, lib, ... }:
let
  cfg = config.tilde.programs.ssh;

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

    rfa = {
      enable = lib.mkEnableOption "SSH Settings for RFA";

      vpnJumpHost = lib.mkOption {
        type = lib.types.str;
        description = ''
          IP address (or host name) for a ProxyJump host that is
          running a VPN that can then be used to SSH to internal RFA
          servers.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.tilde.enable {
      programs.ssh = {
        enable = true;

        controlMaster = "auto";
        controlPath = "~/.ssh/master-%r@%h:%p";

        extraConfig = ''
          User pjones
          ServerAliveInterval 300
          ServerAliveCountMax 5
          TCPKeepAlive no
        ''
        + lib.optionalString
          (cfg.keysDir != options.tilde.programs.ssh.keysDir.default
            || config.tilde.programs.nixops.enable) ''
          IdentitiesOnly yes
          IdentityFile ${cfg.keysDir}/%l.id_ed25519
        ''
        + lib.optionalString config.tilde.programs.nixops.enable ''
          IdentityFile ${cfg.keysDir}/nixops.id_ed25519
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

            "muchsync.devalot.com" = {
              inherit (pmade) port;
              hostname = "10.11.12.2";
              identityFile = "${cfg.keysDir}/muchsync.id_ed25519";
              extraOptions.IdentityAgent = "none";
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
    (lib.mkIf (config.tilde.enable && cfg.rfa.enable) {
      programs.ssh.matchBlocks =
        let keys = {
          scors = "${cfg.keysDir}/scors.id_rsa";
          code = "${cfg.keysDir}/code.rfa.sc.gov.id_rsa";
          clemson = "${cfg.keysDir}/clemson.id_rsa";
        };
        in
        {
          "code.rfa.sc.gov" = {
            user = "git";
            port = 7999;
            proxyJump = cfg.rfa.vpnJumpHost;
            identityFile =
              if cfg.haveRestrictedKeys
              then keys.code
              else null;
          };

          "epa-util01" = {
            proxyJump = cfg.rfa.vpnJumpHost;
            identityFile =
              if cfg.haveRestrictedKeys
              then keys.scors
              else null;
          };

          "cugateway" = {
            proxyJump = cfg.rfa.vpnJumpHost;
            identityFile =
              if cfg.haveRestrictedKeys
              then keys.scors
              else null;
          };

          "hutl" = {
            proxyJump = "cugateway";
            user = "rsp30947";
            identityFile =
              if cfg.haveRestrictedKeys
              then keys.clemson
              else null;
          };

          "hhs-phx-p-utl02" = {
            proxyJump = "cugateway";
            user = "rsp30947";
            identityFile =
              if cfg.haveRestrictedKeys
              then keys.clemson
              else null;
          };
        };
    })
  ];
}
