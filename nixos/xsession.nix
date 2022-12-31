{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession;
  colors = import ../home/misc/colors.nix { inherit pkgs; };
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

    services.xserver = {
      enable = lib.mkDefault true;
      layout = lib.mkDefault "us";

      displayManager.sddm = {
        enable = lib.mkDefault true;
        theme = colors.theme.name;
      };

      displayManager.defaultSession = lib.mkForce "none+hm";
      desktopManager.plasma5.enable = lib.mkDefault true;
      desktopManager.xfce.enable = lib.mkDefault true;

      windowManager.session = [{
        name = "hm";
        desktopNames = [ "XFCE" ];
        bgSupport = true;
        start = ''
          ${pkgs.runtimeShell} $HOME/.hm-xsession &
          waitPID=$!
        '';
      }];

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

    # Allow smartd to display notifications on the X11 display:
    services.smartd.notifications.x11.enable = true;

    environment.systemPackages = with pkgs; [
      colors.theme.package
      (callPackage ../pkgs/pjones-avatar.nix { })
    ];

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
          virtue-font
        ] ++ others;
      };
  };
}
