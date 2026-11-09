{ moduleWithSystem, ... }:
{
  # Clock, timer, and stopwatch for the terminal.
  flake.homeModules.peaclock = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.peaclock;

      timerOptions = { name, ... }: {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "The name of the timer";
          };

          duration = lib.mkOption {
            type = lib.types.str;
            description = "How long the timer runs";
          };
        };
      };

      timerToConfig =
        _: timer:
        let
          name = lib.toLower timer.name;

          config = pkgs.runCommand "peaclock-timer-${name}" { } ''
            install --mode=0644 '${../../support/peaclock/config}' "$out"
            echo "set hours off" >> "$out"
            echo "set seconds on" >> "$out"
            echo "mode timer" >> "$out"
            echo 'timer ${timer.duration}' >> "$out"
          '';
        in
        {
          name = "peaclock/timers/${name}/config";
          value = {
            source = toString config;
          };
        };

      timerToDesktop =
        _: timer:
        let
          name = lib.toLower timer.name;
          dir = config.xdg.configHome + "/peaclock/timers/${name}";

          runPeaclock = pkgs.writeShellScript "peaclock-timer-${name}" ''
            eterm -me 'peaclock --config-dir=${dir}'
          '';
        in
        {
          name = "timer-${name}";
          value = {
            name = "${timer.name} Minute Timer";
            exec = "${runPeaclock}";
            icon = "text-x-script";
            terminal = false;
            categories = [ "Application" ];
          };
        };
    in
    {
      options.tilde.programs.peaclock = {
        timers = lib.mkOption {
          type = with lib.types; attrsOf (submodule timerOptions);
          default = { };
          description = "Timers to configure";
        };
      };

      config = {
        tilde.programs.peaclock.timers = {
          "Fifteen" = {
            duration = "15m:0s";
          };

          "Four" = {
            duration = "4m:0s";
          };
        };

        home.packages = [ pkgs.peaclock ];
        home.file.".peaclock/config".source = ../../support/peaclock/config;
        xdg.desktopEntries = lib.mapAttrs' timerToDesktop cfg.timers;
        xdg.configFile = lib.mapAttrs' timerToConfig cfg.timers;
      };
    }
  );
}
