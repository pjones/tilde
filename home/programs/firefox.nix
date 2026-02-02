{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.tilde.programs.firefox;

  homepage = "https://notes.jonesbunch.com/";

  # FIXME: Replace with:
  # https://mastodon.social/@telomerai/113909268729350091
  # ?
  extensions = with pkgs.nur.repos.rycee.firefox-addons; [
    darkreader
    privacy-badger
    tridactyl
    ublock-origin
    zotero-connector
  ];

  settings = {
    # UI:
    "accessibility.typeaheadfind.autostart" = false;
    "accessibility.typeaheadfind.flashBar" = 0;
    "browser.bookmarks.showMobileBookmarks" = false;
    "browser.contentblocking.category" = "strict";
    "browser.display.use_system_colors" = true;
    "browser.formfill.enable" = false;
    "browser.newtabpage.enabled" = false;
    "browser.sessionstore.collect_zoom" = false;
    "browser.sessionstore.resume_from_crash" = false;
    "browser.sessionstore.resume_session_once" = false;
    "browser.sessionstore.resuming_after_os_restart" = false;
    "browser.startup.homepage" = homepage;
    "browser.tabs.closeWindowWithLastTab" = false;
    "browser.tabs.inTitlebar" = 0;
    "browser.urlbar.trimURLs" = false;
    "dom.event.contextmenu.enabled" = false;
    "dom.forms.autocomplete.formautofill" = false;
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "extensions.pocket.enabled" = false;
    "media.gmp-widevinecdm.visible" = false;
    "mousewheel.system_scroll_override.horizontal.factor" = 1000;
    "signon.rememberSignons" = true;
    "ui.key.menuAccessKeyFocuses" = false;
    "widget.gtk.overlay-scrollbars.enabled" = false;

    # Privacy:
    #
    # Thanks to:
    #   - https://circumstances.run/@davidgerard/115649931911132896
    "browser.ml.chat.enabled" = false;
    "browser.ml.chat.menu" = false;
    "browser.ml.chat.page" = false;
    "browser.ml.chat.page.footerBadge" = false;
    "browser.ml.chat.page.menuBadge" = false;
    "browser.ml.enable" = false;
    "browser.ml.linkPreview.enabled" = false;
    "browser.ml.pageAssist.enabled" = false;
    "browser.newtabpage.activity-stream.feeds.telemetry" = false;
    "browser.newtabpage.activity-stream.feeds.weatherfeed" = false;
    "browser.newtabpage.activity-stream.showWeather" = false;
    "browser.newtabpage.activity-stream.system.showWeather" = false;
    "browser.newtabpage.activity-stream.telemetry" = false;
    "browser.newtabpage.activity-stream.telemetry.ut.events" = false;
    "browser.newtabpage.activity-stream.weather.locationSearchEnabled" = false;
    "browser.ping-centre.telemetry" = false;
    "browser.search.visualSearch.featureGate" = false;
    "browser.tabs.groups.smart.enabled" = false;
    "browser.tabs.groups.smart.userEnabled" = false;
    "browser.urlbar.eventTelemetry.enabled" = false;
    "browser.urlbar.suggest.weather" = false;
    "browser.urlbar.weather.featureGate" = false;
    "dom.private-attribution.submission.enabled" = false;
    "extensions.ml.enabled" = false;
    "network.trr.confirmation_telemetry_enabled" = false;
    "privacy.donottrackheader.enabled" = true;
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;

    # Force FF to use the user chrome CSS file:
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  };
in
{
  options.tilde.programs.firefox = {
    enable = lib.mkEnableOption "Firefox Web Browser";
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;

      package = pkgs.firefox.override (orig: {
        nativeMessagingHosts = (orig.nativeMessagingHosts or [ ]) ++ [ pkgs.tridactyl-native ];
      });

      # General browsing:
      profiles.default = {
        inherit settings;
        extensions.packages = extensions;
        name = "default";
        id = 0;

        search = {
          force = true;
          default = "ddg";
        };

        userChrome = ''
          /* Hide the sidebar in fullscreen */
          #main-window[inFullscreen="true"] #sidebar-main {
            display: none !important;
          }
        '';
      };

      # Site-specific browser configuration:
      profiles.app = {
        inherit settings;
        extensions.packages = extensions;
        name = "app";
        id = 1;

        # https://mrotherguy.github.io/firefox-csshacks/
        userChrome = ''
          @import url(${pkgs.firefox-csshacks}/chrome/window_control_placeholder_support.css);
          @import url(${pkgs.firefox-csshacks}/chrome/autohide_tabstoolbar.css);
          @import url(${pkgs.firefox-csshacks}/chrome/autohide_toolbox.css);
        '';
      };
    };

    home.file.".mozilla/native-messaging-hosts/tridactyl.json".source =
      "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";

    home.file.".config/tridactyl/tridactylrc".text =
      let
        # Helper function to generate bind commands:
        bindIn = modes: str: lib.concatMapStringsSep "\n" (mode: "bind --mode=${mode} ${str}") modes;

        # Bind a key in modes where you should be able to use global
        # modifiers like M-x:
        bindGlobal = bindIn [
          "normal"
          "input"
          "insert"
        ];

        # Bind a key in modes where you can edit text:
        bindEdit = bindIn [
          "ex"
          "input"
          "insert"
        ];
      in
      ''
        sanitize tridactyllocal tridactylsync
        source ${pkgs.tridactyl_emacs_config}/etc/emacs_bindings
        set editorcmd e -cw -- +%l:%c %f

        colours dark
        set theme midnight

        set homepages ["${homepage}"]
        set newtab ${homepage}
        set searchengine dd
        set modeindicatorshowkeys true
        set modeindicator.normal false

        set hintautoselect false
        set hintchars 1234567890
        set hintfiltermode vimperator-reflow

        " Org-capture:
        command org-capture js location.href='org-protocol://capture?' + new URLSearchParams({template: 'p', url: window.location.href, title: document.title, body: window.getSelection()});
        command org-store-link js location.href='org-protocol://store-link?' + new URLSearchParams({url:location.href, title:document.title});

        unbind q
        unbind g
        unbind w

        " History (like info pages)
        bind l back
        bind r forward
        bind u urlparent

        bind w clipboard yank
        bind <C-u>w clipboard yankorg
        bind --mode=visual w composite js document.getSelection().toString() | clipboard yank

        bind <C-c>lc hint -p
        bind <C-c>lw hint -y
        bind <C-c>lo hint
        bind <C-u><C-c>lo hint -t
        bind <C-u><C-u>f hint -b
        bind <C-u>f hint -t

        bind g reload
        bind <C-u>g reloadhard

        bind n scrollline 10
        bind p scrollline -10
        bind <A-f> followpage next
        bind <A-b> followpage prev
        bind <C-+> zoom 0.1 true
        bind <C--> zoom -0.1 true

        " Ignore next key:
        ${bindGlobal "<C-q> nmode ignore 1 mode normal"}

        ${bindEdit "<A-w> composite js document.getSelection().toString() | clipboard yank"}
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

        " Close the current tab:
        bind --mode=normal q tabclose
        bind --mode=visual q tabclose
        bind <A-Backspace> tabclose

        set searchurls.az https://smile.amazon.com/s?k=%s&ref=nb_sb_noss
        set searchurls.bk https://books.google.com?q=%s
        set searchurls.dd https://duckduckgo.com/?q=%s
        set searchurls.dp https://www.deepl.com/en/translator#en/de/%s
        set searchurls.go https://www.google.com/search?q=%s
        set searchurls.ge https://translate.google.com/?sl=de&tl=en&op=translate&text=%s
        set searchurls.ha https://hackage.haskell.org/packages/search?terms=%s
        set searchurls.ho https://hoogle.haskell.org/?hoogle=%s&scope=set%3Astackage
        set searchurls.md https://www.themoviedb.org/search?query=%s
        set searchurls.mp https://maps.google.com/?q=%s
        set searchurls.no https://search.nixos.org/options?query=%s
        set searchurls.np https://search.nixos.org/packages?query=%s
        set searchurls.sc https://scholar.google.com/scholar?q=%s
        set searchurls.wd https://en.wiktionary.org/w/index.php?search=%s
        set searchurls.wp https://en.wikipedia.org/w/index.php?search=%s
      '';
  };
}
