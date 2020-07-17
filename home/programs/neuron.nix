{ config, pkgs, lib, ... }:
let
  cfg = config.tilde.programs.neuron;

  neuron = with pkgs.haskell.lib;
    justStaticExecutables pkgs.haskellPackages.neuron;

  bin = "${neuron}/bin/neuron";
  sport = toString cfg.port;

in
{
  #### Interface:
  options.tilde.programs.neuron = {
    enable = lib.mkEnableOption "Neuron Zettelkasten";

    port = lib.mkOption {
      type = lib.types.ints.s16;
      default = 8080;
      description = "Port to run neuron server on.";
    };

    dir = lib.mkOption {
      type = lib.types.str;
      default = "notes/zettelkasten";
      description = "Path to the Zettelkasten";
    };
  };

  #### Implementation:
  config = lib.mkIf cfg.enable {
    home.packages = [ neuron ];

    systemd.user.services.neuron = {
      Unit = {
        Description = "Neuron Zettelkasten";
        After = [ "network.target" ];
      };

      Install = { WantedBy = [ "default.target" ]; };

      Service = {
        ExecStart = "${bin} -d ${cfg.dir} rib --watch --serve 0.0.0.0:${sport}";
        Restart = "always";
        RestartSec = 3;
        WorkingDirectory = "~";
      };
    };
  };
}
