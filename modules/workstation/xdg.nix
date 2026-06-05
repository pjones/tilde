{ self, moduleWithSystem, ... }:
{
  flake.homeModules.xdg = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    let
      tilde-scripts-misc = self.packages.${pkgs.pkgs.stdenv.hostPlatform.system}.tilde-scripts-misc;
    in
    {
      config = {
        xdg.desktopEntries =
          let
            url = name: url: {
              inherit name;
              exec = "browser ${url}";
              icon = "user-bookmarks";
              terminal = false;
            };
          in
          {
            image-view = {
              name = "IMV";
              genericName = "Image Viewer";
              exec = "${pkgs.imv}/bin/imv %U";
              terminal = false;
              categories = [ "Application" ];
              mimeType = [
                "image/jpeg"
                "image/png"
              ];
            };

            memento-mori = {
              name = "Memento Mori";
              exec = "${tilde-scripts-misc}/bin/memento-mori.sh";
              icon = "image-x-generic";
              terminal = false;
              categories = [ "Application" ];
            };

            start-desktop-apps = {
              name = "Start Desktop Apps";
              exec = "${tilde-scripts-misc}/bin/start-desktop-apps.sh";
              icon = "text-x-script";
              terminal = false;
              categories = [ "Application" ];
            };

            calendar = url "Calendar" "https://app.fastmail.com/calendar/month";
            discord = url "Discord" "https://discord.com/channels/688750797378682946/689772813481279547";
            google-voice = url "Google Voice" "https://voice.google.com/u/0/messages";
            mastodon = url "Mastodon" "https://hostux.social/";
            slack = url "Slack" "https://app.slack.com/client/T0304H0EMPS/C08T7QXJX0A";
            whatsapp = url "WhatsApp" "https://web.whatsapp.com/";
          };

        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "image/jpeg" = "image-view.desktop";
            "image/png" = "image-view.desktop";
            "x-scheme-handler/sgnl" = "signal-desktop.desktop";
            "x-scheme-handler/signalcaptcha" = "signal-desktop.desktop";
          };
        };

        # Some apps are rude and overwrite this file:
        # https://github.com/nix-community/home-manager/issues/1213
        xdg.configFile."mimeapps.list".force = true;
      };
    }
  );
}
