{ config
, lib
, ...
}:
let
  cfg = config.tilde.programs.haskell;
in
{
  options.tilde.programs.haskell = {
    enable = lib.mkEnableOption "Peter's Haskell Configuration";
  };

  config = lib.mkIf cfg.enable {
    # Enable the home-manager code in haskellrc:
    programs.pjones.haskellrc.enable = true;
  };
}
