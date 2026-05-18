{ self, moduleWithSystem, ... }:
{
  flake.homeModules.browser = moduleWithSystem (
    { pkgs, ... }:
    { lib, ... }:
    let
      # MIME types that should be associated with a web browser:
      mimeTypes = [
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/unknown"
        "application/xhtml+xml"
        "text/html"
      ];

      tilde-scripts-browser = self.packages.${pkgs.pkgs.stdenv.hostPlatform.system}.tilde-scripts-browser;
    in
    {
      config = {
        xdg.desktopEntries = {
          browser = {
            name = "Browser";
            icon = "firefox";
            genericName = "Web Browser";
            exec = "${tilde-scripts-browser}/bin/browser %U";
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
  );
}
