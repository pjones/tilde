{ pkgs
, config
, lib
, ...
}:
let
  cfg = config.tilde.programs.herbstluftwm;
in
{
  options.tilde.programs.herbstluftwm = {
    enable = lib.mkEnableOption "The Herbstluftwm Window Manager";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Window manager scripts
      pjones.hlwmrc
    ];

    xsession = {
      enable = lib.mkDefault true;
      windowManager.command = ''
        ${pkgs.pjones.hlwmrc}/libexec/hlwmrc
      '';
    };
  };
}
