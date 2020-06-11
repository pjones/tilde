{ config, pkgs, lib, ... }:
with lib;

let
  cfg = config.pjones.neuron;

  neuron = with pkgs.haskell.lib;
    justStaticExecutables pkgs.haskellPackages.neuron;

  bin = "${neuron}/bin/neuron";

in {
  #### Interface:
  options.pjones.neuron = {
    enable = mkEnableOption "Neuron Zettelkasten";
    port = mkOption {
      type = types.ints.s16;
      default = 8080;
      description = "Port to run neuron server on.";
    };
  };

  #### Implementation:
  config = mkIf cfg.enable {
    home-manager.users.pjones = { ... }: {
      systemd.user.services.neuron = {
        Unit = {
          Description = "Neuron Zettelkasten";
          After = [ "network.target" ];
        };

        Install = { WantedBy = [ "default.target" ]; };

        Service = {
          ExecStart =
            "${bin} -d notes/zettelkasten rib --watch --serve 0.0.0.0:${
              toString cfg.port
            }";
          Restart = "always";
          RestartSec = 3;
          WorkingDirectory = "~";
        };
      };
    };
  };
}
