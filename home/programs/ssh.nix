{ pkgs, config, lib, ... }:
let
  cfg = config.tilde.programs.ssh;

in
{
  options.tilde.programs.ssh = {
    keysDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "~/.ssh";
      description = "Directory where SSH private keys are stored";
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
          IdentitiesOnly yes
        ''
        + lib.optionalString (cfg.keysDir != null) ''
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
    (lib.mkIf (config.tilde.enable && cfg.keysDir != null) {
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
            identityFile = keys.code;
          };

          "scgateway" = {
            hostname = "198.202.228.119";
            port = 2251;
            identityFile = keys.scors;
          };

          "epa-util01" = {
            proxyJump = "scgateway";
            identityFile = keys.scors;
          };

          "cugateway" = {
            proxyJump = "scgateway";
            identityFile = keys.scors;
          };

          "hutl" = {
            proxyJump = "cugateway";
            identityFile = keys.clemson;
            user = "rsp30947";
          };
        };
    })
  ];
}
