{ self, moduleWithSystem, ... }:
{
  flake.homeModules.beets = moduleWithSystem (
    { pkgs, system, ... }:
    { ... }:
    {
      config = {
        home.packages = with pkgs; [
          beets # Music tagger and library organizer
          ffmpeg # For the replaygain plugin
        ];

        xdg.configFile = {
          "beets/config.yaml".source = "${self.packages.${system}.mediarc}/etc/beets.yaml";
        };
      };
    }
  );
}
