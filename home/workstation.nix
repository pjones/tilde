{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.tilde.workstation;
in
{

  options.tilde.workstation = {
    enable = lib.mkEnableOption ''
      Install and configure workstation applications.

      For more details please see the nixos/workstation.nix file.
    '';
  };

  config = lib.mkIf cfg.enable {
    # Keyboard settings:
    home.keyboard = {
      layout = "us";
      options = [ "compose:ralt" ];
    };

    # Active some services/plugins:
    tilde.programs.man.enable = lib.mkDefault true;
    tilde.programs.mpd.enable = lib.mkDefault true;
    tilde.programs.syncthing.enable = lib.mkDefault true;
  };
}
