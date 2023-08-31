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

    dpi = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = ''
        Scale the primary screen by setting its DPI directly.

        The default scale (100%) is 96 DPI.  If you want to scale
        everything up by 150% then set this option to 144.

        This setting is propagated into tilde home-manager settings as
        well.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Enable other settings:
      tilde.workstation.enable = true;
      tilde.programs.qmk.enable = true;

      services.xserver = {
        enable = lib.mkDefault true;
        layout = lib.mkDefault "us";

        displayManager.defaultSession = lib.mkForce "none+hm";
        displayManager.gdm.enable = lib.mkDefault true;

        windowManager.session = [{
          name = "hm";
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

      # For setting GTK themes:
      programs.dconf.enable = true;
      services.dbus.packages = [ pkgs.dconf ];

      # Let me remote in:
      services.openssh.settings.X11Forwarding = lib.mkForce true;
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
    })
  ];
}
