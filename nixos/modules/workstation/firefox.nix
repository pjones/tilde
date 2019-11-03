{ config, pkgs, lib, ... }: with lib;

{
  nixpkgs.config.firefox = {
    enablePlasmaBrowserIntegration = true;
  };
}
