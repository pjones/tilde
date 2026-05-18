{ moduleWithSystem, ... }:
{
  flake.homeModules.peaclock = moduleWithSystem (
    { pkgs, ... }:
    { config, ... }:
    let
      runPeaclock =
        name:
        pkgs.writeShellScript "peaclock-${name}" ''
          eterm -e 'peaclock --config-dir ${config.xdg.configHome}/peaclock/${name}'
        '';
    in
    {
      config = {
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
  );
}
