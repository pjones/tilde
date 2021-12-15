# Arguments to the overlay function:
final: prev:
let
  sources = import ../nix/sources.nix;

  polybar-scripts = sources.polybar-scripts // {
    version = "git-" + builtins.substring 0 7 sources.polybar-scripts.rev;
  };

in
{
  pjones = (prev.pjones or { }) //
    { avatar = prev.callPackage ../pkgs/pjones-avatar.nix { }; };

  # Some local scripts:
  pulse-audio-scripts = prev.callPackage ../pkgs/pulse-audio-scripts.nix { };

  # Package way out of date:
  bibata-cursors = prev.callPackage ../pkgs/bibata-cursors.nix { };

  # Packages that are not upstream yet:
  sweet-nova = prev.callPackage ../pkgs/sweet-nova.nix { };

  polybar-scripts.player-mpris-tail =
    prev.callPackage ../pkgs/polybar-scripts/player-mpris-tail.nix {
      inherit polybar-scripts;
      inherit (prev) stdenv;
      inherit (prev.python3Packages) wrapPython dbus-python pygobject3;
    };

  # I'm stuck on Neuron 1.0.1.0 right now, which is an unreleased and
  # yet old version :(
  haskellPackages = prev.haskellPackages.override (orig: {
    overrides = prev.lib.composeExtensions
      (orig.overrides or (_: _: { }))
      (_: super: {
        neuron = super.neuron.overrideAttrs (_: {
          src = "${sources.neuron}/neuron";
        });
      });
  });

  # Custom hooks:
  tildeInstallScripts = prev.makeSetupHook
    {
      deps = [ prev.makeWrapper ];
      substitutions = { shell = prev.runtimeShell; };
    } ../support/setup-hooks/install-scripts.sh;

  # Various scripts needed inside tilde:
  tilde-scripts-activation = prev.callPackage ../pkgs/tilde-scripts-activation.nix { };
  tilde-scripts-misc = prev.callPackage ../pkgs/tilde-scripts-misc.nix { };
  tilde-scripts-browser = prev.callPackage ../pkgs/tilde-scripts-browser.nix { };

  tilde-scripts-lock-screen = prev.callPackage ../pkgs/tilde-scripts-lock-screen.nix {
    inherit (prev.xorg) xrandr xset;
    inherit (final.polybar-scripts) player-mpris-tail;
  };

  # A gpg-agent/ssh-agent for Android:
  okc-agents = prev.callPackage ../pkgs/okc-agents.nix { };

  # Firefox CSS Hacks:
  firefox-csshacks = prev.callPackage ../pkgs/firefox-csshacks.nix { };

  # Emacs configuration for tridactyl:
  tridactyl_emacs_config = prev.callPackage ../pkgs/tridactyl_emacs_config.nix { };

  # A wrapper around chromium:
  chromium-launcher = prev.callPackage ../pkgs/chromium-launcher.nix {
    chromium = prev.chromium.override {
      ungoogled = false; # Currently broken :(
    };
  };
}
