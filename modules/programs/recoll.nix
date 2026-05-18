{ moduleWithSystem, ... }:
{
  flake.homeModules.recoil = moduleWithSystem (
    { pkgs, ... }:
    { config, ... }:
    {
      config = {
        home.packages = [
          pkgs.tesseract # For OCR.
        ];

        services.recoll = {
          enable = true;
          configDir = "${config.xdg.configHome}/recoll";

          settings = {
            topdirs = map (dir: "${config.home.homeDirectory}/${dir}") [
              "contacts"
              "documents"
              "mail"
              "notes"
            ];

            "skippedNames+" = [
              "*.iso"
              "*.gpg"
            ];

            pdfocr = 1;
            pdfattach = 1;
          };
        };
      };
    }
  );
}
