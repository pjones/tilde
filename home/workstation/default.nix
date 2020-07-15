{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.pjones.workstation;
in
{

  options.pjones.workstation = {
    enable = lib.mkEnableOption ''
      Install and configure workstation applications.

      For more details please see the nixos/workstation.nix file.
    '';
  };


  # haskellPackages.neuron

  config = lib.mkIf cfg.enable {
    # Active some services/plugins:
    pjones.programs.mpd.enable = lib.mkDefault true;
    pjones.programs.neuron.enable = lib.mkDefault true;
    services.syncthing.enable = lib.mkDefault true;

    home.packages = with pkgs; [
      # System and Security
      (aspellWithDicts (d: [
        d.en
        d.en-computers
        d.en-science
      ]))
      dict
      nixops
      pass

      # Network
      youtube-dl

      # Audio/Video
      # beets (2020-04-24: broken)
      abcde
      atomicparsley
      bs1770gain
      cdrkit # cdrecord, mkisofs, etc.
      ffmpeg
      lame
      moc
      mpc_cli
      mpg123
      ncmpcpp

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
    ];
  };
}
