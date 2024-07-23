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
    # Active some services/plugins:
    tilde.programs.man.enable = lib.mkDefault true;
    tilde.programs.syncthing.enable = lib.mkDefault true;

    # A user service that prepares for suspend:
    systemd.user.services.onsuspend = {
      Unit = {
        Description = "Prepare for suspend";
        Before = "sleep.target";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.pjones.desktop-scripts}/bin/desktop-pre-suspend";
      };

      Install = {
        WantedBy = [ "sleep.target" ];
      };
    };
  };
}
