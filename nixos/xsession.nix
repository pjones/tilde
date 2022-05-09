{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession;
in
{
  options.tilde.xsession = {
    enable = lib.mkEnableOption ''
      Enable the X server and configure Peter's xsession.

      Implies that this machine is a workstation as well.
    '';
  };

  config = lib.mkIf cfg.enable {
    # Enable other settings:
    tilde.workstation.enable = true;
    tilde.programs.qmk.enable = true;

    services.xserver = lib.mkIf cfg.enable {
      enable = lib.mkDefault true;
      layout = lib.mkDefault "us";

      desktopManager.plasma5.enable =
        lib.mkDefault true;

      displayManager.sddm = {
        enable = lib.mkDefault true;
        theme = "sweet-nova";
      };

      libinput = {
        enable = true;

        touchpad = {
          clickMethod = "clickfinger";
          disableWhileTyping = true;
          scrollMethod = "twofinger";
          tapping = false;
        };
      };
    };

    # Let me remote in:
    services.openssh.forwardX11 = lib.mkForce true;
    programs.ssh.startAgent = false; # I use GnuPG Agent.

    environment.systemPackages = with pkgs; [
      (callPackage ../pkgs/sweet-nova.nix { })
      (callPackage ../pkgs/pjones-avatar.nix { })
    ];

    # Bluetooth tools need to be installed as wrappers so normal users
    # can use them.  For example, the screensaver inhibit code in this
    # repo.
    security.wrappers.l2ping = {
      source = "${pkgs.bluez}/bin/l2ping";
      owner = "nobody";
      group = "nogroup";
      capabilities = "cap_net_raw+ep";
    };

    fonts =
      let
        specs = import ../home/misc/fonts.nix { inherit pkgs; };
        others = map (f: f.package) (lib.attrValues specs);
      in
      {
        fontconfig.enable = true;
        fontDir.enable = true;
        enableGhostscriptFonts = true;

        fonts = with pkgs; [
          dejavu_fonts
          ubuntu_font_family
        ] ++ others;
      };
  };
}
