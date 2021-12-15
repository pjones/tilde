{ config
, lib
, ...
}:
let
  cfg = config.tilde.programs.emacs;
in
{
  options.tilde.programs.emacs = {
    enable = lib.mkEnableOption "Emacs and Peter's Configuration";
  };

  config = lib.mkIf cfg.enable {
    # Enable the nix/home.nix code in emacsrc:
    programs.pjones.emacsrc.enable = true;
  };
}
