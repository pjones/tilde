{ inputs, moduleWithSystem, ... }:
{
  flake.homeModules.anyrun = moduleWithSystem (
    { system, ... }:
    { ... }:
    {
      imports = [
        ({ modulesPath, ... }: {
          disabledModules = [ "${modulesPath}/programs/anyrun.nix" ];
        })

        inputs.anyrun.homeManagerModules.default
      ];

      config = {
        programs.anyrun = {
          enable = true;
          daemon.enable = true;

          config = {
            x.fraction = 0.5;
            y.fraction = 0.3;
            width.fraction = 0.3;
            hidePluginInfo = true;

            keybinds = [
              {
                action = "up";
                ctrl = true;
                key = "p";
              }
              {
                action = "down";
                ctrl = true;
                key = "n";
              }
              {
                action = "close";
                ctrl = true;
                key = "g";
              }
              {
                action = "select";
                key = "Return";
              }
            ];

            plugins = with inputs.anyrun.packages.${system}; [
              actions
              applications
              niri-focus
              shell
              websearch
            ];
          };

          extraConfigFiles."niri-focus.ron".text = ''
            Config(
              max_entries: 10,
            )
          '';
        };
      };
    }
  );
}
