{ config, pkgs, lib, ... }:

let
  cfg = config.tilde.programs.syncthing;
in
{
  options.tilde.programs.syncthing = {
    enable = lib.mkEnableOption "Syncthing File Synchronization";

    gui.ip = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "IP address to bind the GUI to";
    };

    gui.port = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8384;
      description = "The port the GUI will listen on";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;

      extraOptions = [
        "--gui-address=${cfg.gui.ip}:${toString cfg.gui.port}"
        "--no-default-folder"
      ];
    };
  };
}
