{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.tilde.workstation;
in
{

  options.tilde.workstation = {
    enable = lib.mkEnableOption ''
      Install and configure workstation applications.

      For more details please see the nixos/workstation.nix file.
    '';
  };

  config = lib.mkIf cfg.enable {
    # Active some services/plugins:
    tilde.programs.man.enable = lib.mkDefault true;
    tilde.programs.mpd.enable = lib.mkDefault true;
    tilde.programs.neuron.enable = lib.mkDefault true;
    tilde.programs.nixops.enable = true;
    services.syncthing.enable = lib.mkDefault true;

    home.packages = with pkgs; [
      # System and Security
      nixops
      pass

      # Network
      youtube-dl

      # Audio/Video
      # beets (2020-04-24: broken)
      abcde
      atomicparsley
      cdrkit # cdrecord, mkisofs, etc.
      ffmpeg
      lame
      moc
      mpc_cli
      mpg123

      # Document Conversion:
      pandoc
      pdftk

      # Development
      libxml2
      libxslt
      mr
      niv
      ripgrep

      # My packages
      pjones.encryption-utils
      pjones.vimeta
      pulse-audio-scripts
    ];
  };
}
