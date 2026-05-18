{ moduleWithSystem, ... }:
{
  flake.homeModules.chromium = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      config = {
        programs.chromium = {
          enable = true;
          package = pkgs.ungoogled-chromium;
          dictionaries = with pkgs.hunspellDictsChromium; [ en_US ];
        };
      };
    }
  );
}
