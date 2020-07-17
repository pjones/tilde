{ pkgs
, config
, lib
, ...
}:

{
  config = lib.mkIf config.tilde.enable {
    home.packages = with pkgs; [
      pjones.emacsrc
    ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/mailto" = "gnus.desktop";
        "application/pdf" = "emacsclient.desktop";
      };
    };

    home.file.".emacs".source =
      "${pkgs.pjones.emacsrc}/dot.emacs.el";
    home.file.".local/share/applications/gnus.desktop".source =
      "${pkgs.pjones.emacsrc}/share/applications/gnus.desktop";
    home.file.".local/share/applications/emacsclient.desktop".source =
      "${pkgs.pjones.emacsrc}/share/applications/emacsclient.desktop";
  };
}
