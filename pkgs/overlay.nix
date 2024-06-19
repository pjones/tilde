# Arguments to the overlay function:
{ inputs }:
final: prev: {
  # Don't use transparent themes by default:
  dracula-theme = prev.dracula-theme.overrideAttrs (prev: {
    postInstall = ''
      pushd "$out/share/Kvantum"
      mv Dracula Dracula-Transparent
      cp -a Dracula-Solid Dracula
      mv Dracula/Dracula-Solid.kvconfig Dracula/Dracula.kvconfig
      mv Dracula/Dracula-Solid.svg Dracula/Dracula.svg
      popd
      ${prev.postInstall or ""}
    '';
  });

  # Firefox CSS Hacks:
  firefox-csshacks = prev.callPackage ./firefox-csshacks.nix { inherit inputs; };

  # A gpg-agent/ssh-agent for Android:
  okc-agents = prev.callPackage ./okc-agents.nix { };

  # Custom hooks:
  tildeInstallScripts = prev.makeSetupHook
    {
      name = "tildeInstallScripts";
      propagatedBuildInputs = [ prev.makeWrapper ];
      substitutions = { shell = prev.runtimeShell; };
    } ../support/setup-hooks/install-scripts.sh;

  # Various scripts needed inside tilde:
  tilde-scripts-activation = prev.callPackage ./tilde-scripts-activation.nix { };
  tilde-scripts-browser = prev.callPackage ./tilde-scripts-browser.nix { };
  tilde-scripts-misc = prev.callPackage ./tilde-scripts-misc.nix { };

  # Emacs configuration for tridactyl:
  tridactyl_emacs_config = prev.callPackage ./tridactyl_emacs_config.nix { inherit inputs; };

  # Virtue Font:
  virtue-font = prev.callPackage ./virtue.nix { };
}
