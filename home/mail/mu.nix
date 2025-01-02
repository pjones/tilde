{ config, lib, pkgs, ... }:

let
  mailCfg = config.tilde.mail;
  cfg = mailCfg.mu;
  util = import ./options.nix { inherit lib; };

  dbDir = "${config.xdg.cacheHome}/mu";

  initFlags = [
    "--maildir=${mailCfg.directory}"
  ] ++ builtins.map (addr: "--my-address=${addr}")
    (util.allEmailAddresses mailCfg.accounts);
in
{
  options.tilde.mail.mu = {
    enable = lib.mkEnableOption "Configure and set up mu.";
  };

  config = lib.mkIf (mailCfg.enable && cfg.enable) {
    home.packages = [ pkgs.mu ];

    home.sessionVariables = {
      MAILDIR = mailCfg.directory;
    };

    home.activation.runMuInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "${dbDir}" ]; then
        run ${lib.getExe pkgs.mu} init ${lib.escapeShellArgs initFlags}
      fi
    '';
  };
}
