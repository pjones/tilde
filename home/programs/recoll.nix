{ config, lib, pkgs, ... }:

let
  cfg = config.tilde.programs.recoll;

  defaultDirectories = [
    "contacts"
    "documents"
    "mail"
    "notes"
  ];
in
{
  options.tilde.programs.recoll = {
    enable = lib.mkEnableOption "Enable and configure Recoll.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.tesseract # For OCR.
    ];

    services.recoll = {
      enable = true;
      configDir = "${config.xdg.configHome}/recoll";

      settings = {
        topdirs =
          map (dir: "${config.home.homeDirectory}/${dir}") defaultDirectories;

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
