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

  # Firefox CSS Hacks:
  firefox-csshacks = prev.callPackage ./firefox-csshacks.nix { };

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

  # Emacs configuration for tridactyl:
  tridactyl_emacs_config = prev.callPackage ./tridactyl_emacs_config.nix { };

  # Virtue Font:
  virtue-font = prev.callPackage ./virtue.nix { };
}
