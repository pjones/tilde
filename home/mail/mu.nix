{
  config,
  lib,
  pkgs,
  ...
}:

let
  mailCfg = config.tilde.mail;
  cfg = mailCfg.mu;
  util = import ./options.nix { inherit lib; };

  dbDir = "${config.xdg.cacheHome}/mu";

  initFlags = [
    "--maildir=${mailCfg.directory}"
  ]
  ++ builtins.map (addr: "--my-address=${addr}") (util.allEmailAddresses mailCfg.accounts);
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

    # It's safe to run this more than once.  In fact, we want to run
    # it more than once so we can update user email addresses when
    # they change.
    home.activation.runMuInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! ${pkgs.procps}/bin/pgrep -u "$USER" mu && [ ! -d "${dbDir}" ]; then
        run ${lib.getExe pkgs.mu} init ${lib.escapeShellArgs initFlags}
      fi
    '';
  };
}
