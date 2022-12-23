# This is a NixOS module:
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ./generic-nixos.nix
  ];

  config = {
    networking.hostName = "hyde";
    system.stateVersion = lib.mkDefault "22.11";

    wsl = {
      enable = true;
      wslConf.automount.root = "/mnt";
      defaultUser = "pjones";
      startMenuLaunchers = false;
    };

    # Stuff that doesn't work in WSL:
    services.smartd.enable = lib.mkForce false;

    home-manager.users.pjones = { ... }: {
      tilde.programs.emacs.enable = true;
    };
  };
}
