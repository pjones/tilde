{ inputs, ... }:
{
  flake.overlays = {
    default = final: prev: {
      peaclock = prev.peaclock.overrideAttrs (_orig: {
        src = inputs.peaclock;
      });
    };

    bashrc = inputs.bashrc.overlays.default;
    encryption-utils = inputs.encryption-utils.overlays.default;
    image-scripts = inputs.image-scripts.overlays.default;
    maintenance-scripts = inputs.maintenance-scripts.overlays.default;
    mediarc = inputs.mediarc.overlays.mediarc;
    network-scripts = inputs.network-scripts.overlays.default;
    nur = inputs.nur.overlays.default;
    superkey = inputs.superkey.overlays.superkey;
    tmuxrc = inputs.tmuxrc.overlays.default;
    zshrc = inputs.zshrc.overlays.default;
  };

  perSystem =
    { pkgs, ... }:
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
      # Various scripts needed inside tilde:
      packages.tilde-scripts-activation = pkgs.callPackage ../../pkgs/tilde-scripts-activation.nix {
        inherit tildeInstallScripts;
      };

      packages.tilde-scripts-browser = pkgs.callPackage ../../pkgs/tilde-scripts-browser.nix {
        inherit tildeInstallScripts;
      };

      packages.tilde-scripts-misc = pkgs.callPackage ../../pkgs/tilde-scripts-misc.nix {
        inherit tildeInstallScripts;
      };

      # Firefox CSS Hacks:
      #
      # https://mrotherguy.github.io/firefox-csshacks/
      packages.firefox-csshacks = pkgs.callPackage ../../pkgs/firefox-csshacks.nix {
        src = inputs.firefox-csshacks;
      };

      # Emacs configuration for tridactyl:
      packages.tridactyl_emacs_config = pkgs.callPackage ../../pkgs/tridactyl_emacs_config.nix {
        src = inputs.tridactyl_emacs_config;
      };
    };
}
