{ config, pkgs, lib, ... }:
let
  cfg = config.tilde.programs.qmk;

in
{
  options.tilde.programs.qmk = {
    enable = lib.mkEnableOption "QMK Firmware Rules and Helper Apps";
  };

  config = lib.mkIf cfg.enable {
    hardware.keyboard.qmk.enable = true;
    services.udev.packages = [ pkgs.vial ];
    environment.systemPackages = [ pkgs.vial ];
  };
}
