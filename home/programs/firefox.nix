{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.programs.firefox;

  settings = {
    # UI:
    "accessibility.typeaheadfind.autostart" = false;
    "accessibility.typeaheadfind.flashBar" = 0;
    "browser.bookmarks.showMobileBookmarks" = false;
    "browser.contentblocking.category" = "strict";
    "browser.display.use_system_colors" = true;
    "browser.formfill.enable" = false;
    "browser.newtabpage.enabled" = false;
    "browser.startup.homepage" = "http://localhost:8080/bookmarks.html";
    "browser.urlbar.trimURLs" = false;
    "dom.forms.autocomplete.formautofill" = false;
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "extensions.pocket.enabled" = false;
    "signon.rememberSignons" = false;

    # Privacy:
    "privacy.donottrackheader.enabled" = true;
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;

    # Force FF to use the user chrome CSS file:
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # Use the super key instead of the control key:
    "ui.key.accelKey" = 91;
  };
in
{
  options.tilde.programs.firefox = {
    enable = lib.mkEnableOption "Firefox Web Browser";
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;

      package = pkgs.firefox.override {
        cfg.enableTridactylNative = true;
      };

      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        https-everywhere
        privacy-badger
        tridactyl
      ];

      # General browsing:
      profiles.default = {
        inherit settings;
        name = "default";
        id = 0;

        userChrome = ''
          @import url(${pkgs.firefox-csshacks}/chrome/autohide_tabstoolbar.css);
        '';
      };

      # Site-specific browser configuration:
      profiles.app = {
        inherit settings;
        name = "app";
        id = 1;

        userChrome = ''
          @import url(${pkgs.firefox-csshacks}/chrome/autohide_toolbox.css);
          @import url(${pkgs.firefox-csshacks}/chrome/autohide_tabstoolbar.css);
        '';
      };
    };

    home.file.".config/tridactyl/tridactylrc".text = ''
      source ${pkgs.tridactyl_emacs_config}/etc/emacs_bindings
      set editorcmd e -cws browsers -- --eval '(progn (find-file "%f") (forward-line (1- %l)) (forward-char %c))'

      colours dark

      set hintautoselect false
      set hintchars 1234567890
      set hintfiltermode vimperator-reflow

      bind --mode=insert <C-w> text.kill_word
      bind --mode=ex <C-w> text.kill_word

      bind <C-i> focusinput -l

      set searchurls.az https://smile.amazon.com/s?k=%s&ref=nb_sb_noss
      set searchurls.go https://www.google.com/search?q=%s
      set searchurls.ha https://hackage.haskell.org/packages/search?terms=%s
      set searchurls.ho https://hoogle.haskell.org/?hoogle=%s&scope=set%3Astackage
      set searchurls.no https://search.nixos.org/options?query=%s
      set searchurls.np https://search.nixos.org/packages?query=%s
      set searchurls.wd https://en.wiktionary.org/w/index.php?search=%s
      set searchurls.wp https://en.wikipedia.org/w/index.php?search=%s
    '';
  };
}
