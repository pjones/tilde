{ self, inputs, ... }:
{
  flake.overlays = {
    default = final: prev: {
      peaclock = prev.peaclock.overrideAttrs (_orig: {
        src = inputs.peaclock;
      });

      # https://github.com/NixOS/nixpkgs/pull/526756
      cups-kyodialog = prev.callPackage ../../pkgs/cups-kyodialog.nix { };

      org-clock-dbus = self.inputs.org-clock-dbus.packages.${prev.stdenv.hostPlatform.system}.monitor;
    };

    bashrc = inputs.bashrc.overlays.default;
    image-scripts = inputs.image-scripts.overlays.default;
    maintenance-scripts = inputs.maintenance-scripts.overlays.default;
    network-scripts = inputs.network-scripts.overlays.default;
    nur = inputs.nur.overlays.default;
    tmuxrc = inputs.tmuxrc.overlays.default;
    zshrc = inputs.zshrc.overlays.default;
  };

  perSystem =
    { pkgs, system, ... }:
    let
      # Custom hooks:
      tildeInstallScripts = pkgs.makeSetupHook {
        name = "tildeInstallScripts";
        propagatedBuildInputs = [ pkgs.makeWrapper ];
        substitutions = {
          shell = pkgs.runtimeShell;
        };
      } ../../support/setup-hooks/install-scripts.sh;

    in
    {
      packages = {
        # Set a default package for CI
        #
        # FIXME: Come up with something better though:
        default = pkgs.peaclock;

        # Various scripts needed inside tilde:
        tilde-scripts-activation = pkgs.callPackage ../../pkgs/tilde-scripts-activation.nix {
          inherit tildeInstallScripts;
        };

        tilde-scripts-browser = pkgs.callPackage ../../pkgs/tilde-scripts-browser.nix {
          inherit tildeInstallScripts;
        };

        tilde-scripts-misc = pkgs.callPackage ../../pkgs/tilde-scripts-misc.nix {
          inherit tildeInstallScripts;
        };

        encryption-utils = inputs.encryption-utils.packages.${system}.encryption-utils;

        # Firefox CSS Hacks:
        #
        # https://mrotherguy.github.io/firefox-csshacks/
        firefox-csshacks = pkgs.callPackage ../../pkgs/firefox-csshacks.nix {
          src = inputs.firefox-csshacks;
        };

        # Emacs configuration for tridactyl:
        tridactyl_emacs_config = pkgs.callPackage ../../pkgs/tridactyl_emacs_config.nix {
          src = inputs.tridactyl_emacs_config;
        };

        # Scripts to force the wayland compositor to lock the screen
        # now (even if a lock is inhibited).
        force-lock = pkgs.callPackage ../../pkgs/force-lock { };

        mediarc = self.inputs.mediarc.packages.${system}.mediarc;

        nerd-hyperlegible = pkgs.callPackage ../../pkgs/nerd-hyperlegible.nix { };

        pjones-avatar = pkgs.callPackage ../../pkgs/pjones-avatar.nix { };

        presenter-mode = pkgs.callPackage ../../pkgs/presenter-mode { };

        prometheus-extra = pkgs.callPackage ../../pkgs/prometheus-extra { };

        rofirc = pkgs.callPackage ../../pkgs/rofirc {
          superkey = self.packages.${system}.superkey;
        };

        superkey = pkgs.callPackage ../../pkgs/superkey { };

        theme-dracula = pkgs.callPackage ../../pkgs/theme {
          colors = ../../pkgs/theme/dracula.json;
        };

        theme-outrun = pkgs.callPackage ../../pkgs/theme { colors = ../../pkgs/theme/outrun.json; };

        wayland-test-helpers = pkgs.callPackage ../../pkgs/wayland-test-helpers { };

        wg-gen = pkgs.callPackage ../../pkgs/wg-gen {
          encryption-utils = self.packages.${system}.encryption-utils;
        };

        xwininfo-tests = pkgs.writeShellApplication {
          name = "xwininfo";
          runtimeInputs = with pkgs; [
            jq
          ];
          text = builtins.readFile ../../support/scripts/xwininfo-tests;
        };
      };
    };
}
