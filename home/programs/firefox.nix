{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.programs.firefox;

  homepage = "https://notes.jonesbunch.com/";

  settings = {
    # UI:
    "accessibility.typeaheadfind.autostart" = false;
    "accessibility.typeaheadfind.flashBar" = 0;
    "browser.bookmarks.showMobileBookmarks" = false;
    "browser.contentblocking.category" = "strict";
    "browser.display.use_system_colors" = true;
    "browser.formfill.enable" = false;
    "browser.newtabpage.enabled" = false;
    "browser.startup.homepage" = homepage;
    "browser.urlbar.trimURLs" = false;
    "dom.forms.autocomplete.formautofill" = false;
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "extensions.pocket.enabled" = false;
    "signon.rememberSignons" = true;
    "media.gmp-widevinecdm.visible" = false;

    # Privacy:
    "privacy.donottrackheader.enabled" = true;
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "network.trr.confirmation_telemetry_enabled" = false;
    "browser.newtabpage.activity-stream.feeds.telemetry" = false;
    "browser.newtabpage.activity-stream.telemetry" = false;
    "browser.newtabpage.activity-stream.telemetry.ut.events" = false;
    "browser.ping-centre.telemetry" = false;
    "browser.urlbar.eventTelemetry.enabled" = false;

    # Force FF to use the user chrome CSS file:
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # Force FF to use the Super key for its built in shortcuts and
    # menu bar.  Also keep FF from focusing the menu bar.
    "ui.key.accelKey" = 91;
    "ui.key.menuAccessKey" = 91;
    "ui.key.menuAccessKeyFocuses" = false;
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
        cfg.enablePlasmaBrowserIntegration = true;
      };

      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        darkreader
        privacy-badger
        tridactyl
        ublock-origin
      ];

      # General browsing:
      profiles.default = {
        inherit settings;
        name = "default";
        id = 0;

        userChrome = ''
          @import url(${pkgs.firefox-csshacks}/chrome/combined_favicon_and_tab_close_button.css);
          @import url(${pkgs.firefox-csshacks}/chrome/tabs_on_bottom.css);
        '';
      };

      # Site-specific browser configuration:
      profiles.app = {
        inherit settings;
        name = "app";
        id = 1;

        userChrome = ''
          @import url(${pkgs.firefox-csshacks}/chrome/combined_favicon_and_tab_close_button.css);
          @import url(${pkgs.firefox-csshacks}/chrome/autohide_toolbox.css);
          @import url(${pkgs.firefox-csshacks}/chrome/autohide_tabstoolbar.css);
          @import url(${pkgs.firefox-csshacks}/chrome/tabs_on_bottom.css);
        '';
      };

      # Just for Facebook :(
      profiles.facebook = {
        inherit settings;
        name = "facebook";
        id = 2;

        userChrome = ''
          @import url(${pkgs.firefox-csshacks}/chrome/combined_favicon_and_tab_close_button.css);
          @import url(${pkgs.firefox-csshacks}/chrome/autohide_toolbox.css);
          @import url(${pkgs.firefox-csshacks}/chrome/autohide_tabstoolbar.css);
          @import url(${pkgs.firefox-csshacks}/chrome/tabs_on_bottom.css);
        '';
      };
    };

    home.file.".config/tridactyl/tridactylrc".text =
      let
        # Helper function to generate bind commands:
        bindIn = modes: str:
          lib.concatMapStringsSep "\n"
            (mode: "bind --mode=${mode} ${str}")
            modes;

        # Bind a key in modes where you should be able to use global
        # modifiers like M-x:
        bindGlobal = bindIn [ "normal" "input" "insert" ];

        # Bind a key in modes where you can edit text:
        bindEdit = bindIn [ "ex" "input" "insert" ];
      in
      ''
        sanitize tridactyllocal tridactylsync
        source ${pkgs.tridactyl_emacs_config}/etc/emacs_bindings
        set editorcmd e -cw -- +%l:%c %f

        colours dark

        set homepages ["${homepage}"]
        set newtab ${homepage}
        set searchengine dd
        set modeindicatorshowkeys true

        set hintautoselect false
        set hintchars 1234567890
        set hintfiltermode vimperator-reflow

        unbind g
        unbind l
        unbind w

        " Allow the tab key to pass through some sites:
        unbindurl chat.rfa.sc.gov --mode=input <Tab>
        unbindurl beeline.com --mode=input <Tab>

        bind <C-c><A-w> clipboard yank
        bind <C-u><C-c><A-w> clipboard yankmd

        bind <C-c>lc hint -p
        bind <C-c>lw hint -y
        bind <C-c>lo hint
        bind <C-u><C-c>lo hint -t
        bind <C-u><C-u>f hint -b
        bind <C-u>f hint -t

        bind g reload
        bind r reload
        bind <C-u>g reloadhard
        bind <C-u>r reloadhard

        bind n scrollline 10
        bind p scrollline -10
        bind <A-f> followpage next
        bind <A-b> followpage prev

        " Ignore next key:
        ${bindGlobal "<C-q> nmode ignore 1 mode normal"}

        ${bindEdit "<C-w> text.backward_kill_word"}
        ${bindEdit "<C-y> composite getclip clipboard | text.insert_text"}

        bind o fillcmdline open
        ${bindGlobal "<A-n> tabnext"}
        ${bindGlobal "<A-p> tabprev"}
        ${bindGlobal "<A-x> fillcmdline_notrail"}
        ${bindGlobal "<C-c>h home"}
        ${bindGlobal "<C-i> focusinput -l"}
        ${bindGlobal "<C-x><C-b> fillcmdline buffer"}
        ${bindGlobal "<C-x><C-f> fillcmdline tabopen"}
        ${bindGlobal "<C-x><C-v> current_url open"}
        ${bindGlobal "<C-x>b fillcmdline buffer"}
        ${bindGlobal "<C-x>k tabclose"}

        set searchurls.az https://smile.amazon.com/s?k=%s&ref=nb_sb_noss
        set searchurls.dd https://duckduckgo.com/?q=%s
        set searchurls.go https://www.google.com/search?q=%s
        set searchurls.ha https://hackage.haskell.org/packages/search?terms=%s
        set searchurls.ho https://hoogle.haskell.org/?hoogle=%s&scope=set%3Astackage
        set searchurls.md https://www.themoviedb.org/search?query=%s
        set searchurls.no https://search.nixos.org/options?query=%s
        set searchurls.np https://search.nixos.org/packages?query=%s
        set searchurls.wd https://en.wiktionary.org/w/index.php?search=%s
        set searchurls.wp https://en.wikipedia.org/w/index.php?search=%s
      '';
  };
}
