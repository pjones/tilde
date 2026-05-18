{ moduleWithSystem, ... }:
{
  flake.homeModules.anki = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      config = {
        home.packages = [
          pkgs.anki-bin # Spaced repetition flashcard program
        ];

        home.sessionVariables = {
          # Anki in xwayland is *buggy*:
          ANKI_WAYLAND = 1;
        };
      };
    }
  );
}
