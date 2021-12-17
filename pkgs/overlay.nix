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
    { avatar = prev.callPackage ./pjones-avatar.nix { }; };

  # Package way out of date:
  bibata-cursors = prev.callPackage ./bibata-cursors.nix { };

  # A wrapper around chromium:
  chromium-launcher = prev.callPackage ./chromium-launcher.nix {
    chromium = prev.chromium.override {
      ungoogled = false; # Currently broken :(
    };
  };

  # Firefox CSS Hacks:
  firefox-csshacks = prev.callPackage ./firefox-csshacks.nix { };

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

  # A gpg-agent/ssh-agent for Android:
  okc-agents = prev.callPackage ./okc-agents.nix { };

  polybar-scripts.player-mpris-tail =
    prev.callPackage ./polybar-scripts/player-mpris-tail.nix {
      inherit polybar-scripts;
      inherit (prev) stdenv;
      inherit (prev.python3Packages) wrapPython dbus-python pygobject3;
    };

  # Some local scripts:
  pulse-audio-scripts = prev.callPackage ./pulse-audio-scripts.nix { };

  # Packages that are not upstream yet:
  sweet-nova = prev.callPackage ./sweet-nova.nix { };

  # Custom hooks:
  tildeInstallScripts = prev.makeSetupHook
    {
      deps = [ prev.makeWrapper ];
      substitutions = { shell = prev.runtimeShell; };
    } ../support/setup-hooks/install-scripts.sh;

  # Various scripts needed inside tilde:
  tilde-scripts-activation = prev.callPackage ./tilde-scripts-activation.nix { };
  tilde-scripts-misc = prev.callPackage ./tilde-scripts-misc.nix { };
  tilde-scripts-browser = prev.callPackage ./tilde-scripts-browser.nix { };

  tilde-scripts-lock-screen = prev.callPackage ./tilde-scripts-lock-screen.nix {
    inherit (prev.xorg) xrandr xset;
    inherit (final.polybar-scripts) player-mpris-tail;
  };

  # Emacs configuration for tridactyl:
  tridactyl_emacs_config = prev.callPackage ./tridactyl_emacs_config.nix { };
}
