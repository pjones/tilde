{ config, lib, pkgs, ... }:

let
  cfg = config.tilde.programs.peaclock;

  runPeaclock = name: pkgs.writeShellScript "peaclock-${name}" ''
    eterm -e 'peaclock --config-dir ${config.xdg.configHome}/peaclock/${name}'
  '';
in
{
  options.tilde.programs.peaclock = {
    enable = lib.mkEnableOption "Peaclock";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      peaclock # Clock, timer, and stopwatch for the terminal
    ];

    xdg.configFile."peaclock/fifteen/config".source = ../../support/peaclock/config;

    xdg.desktopEntries = {
      timer-fifteen = {
        name = "Fifteen Minute Timer";
        exec = "${runPeaclock "fifteen"}";
        icon = "text-x-script";
        terminal = false;
        categories = [ "Application" ];
      };
    };
  };
}
