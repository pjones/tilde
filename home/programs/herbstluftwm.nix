{ pkgs
, config
, lib
, ...
}:
let
  cfg = config.tilde.programs.herbstluftwm;
  de = config.tilde.xsession.desktopEnv;

in
{
  options.tilde.programs.herbstluftwm = {
    enable = lib.mkEnableOption "The Herbstluftwm Window Manager";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Window manager scripts
      pjones.hlwmrc
      herbstluftwm
    ];

    xsession = {
      enable = lib.mkDefault true;
      windowManager.command =
        let
          command = "${pkgs.pjones.hlwmrc}/libexec/hlwmrc";

          decmd = ''
            export ${de.envVar}=${command}
            ${de.command}
          '';
        in
        if de.enable then decmd else command;
    };
  };
}
