{ config
, lib
, ...
}:
let
  sources = import ../../nix/sources.nix;
  cfg = config.tilde.programs.emacs;
in
{
  imports = [ "${sources."pjones/emacsrc"}/nix/home.nix" ];

  options.tilde.programs.emacs = {
    enable = lib.mkEnableOption "Emacs and Peter's Configuration";
  };

  config = lib.mkIf cfg.enable {
    # Enable the nix/home.nix code in emacsrc:
    programs.pjones.emacsrc.enable = true;
  };
}
