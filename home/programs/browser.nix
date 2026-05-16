{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.tilde.programs.browser;

  # MIME types that should be associated with a web browser:
  mimeTypes = [
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/unknown"
    "application/xhtml+xml"
    "text/html"
  ];

in
{
  options.tilde.programs.browser = {
    enable = lib.mkEnableOption "Web Browser Scripts";
  };

  config = lib.mkIf cfg.enable {
    tilde.programs.chromium.enable = true;
    tilde.programs.firefox.enable = true;

    xdg.desktopEntries = {
      browser = {
        name = "Browser";
        icon = "firefox";
        genericName = "Web Browser";
        exec = "${pkgs.tilde-scripts-browser}/bin/browser %U";
        terminal = false;
        comment = "Wrapper around Firefox";
        categories = [
          "Network"
          "WebBrowser"
        ];
        mimeType = mimeTypes;
      };
    };

    xdg.mimeApps = {
      enable = lib.mkDefault true;

      defaultApplications = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = "browser.desktop";
        }) mimeTypes
      );
    };
  };
}
