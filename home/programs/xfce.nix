{ pkgs, config, lib, ... }:

let
  cfg = config.tilde.programs.xfce;
  images = pkgs.callPackage ../misc/images.nix { };

  # Start herbstluftwm:
  startHerbstluftwm = pkgs.writeShellScript "xfce-start-herbstluftwm" ''
    # Reset workspace names (herbstluftwm has issues with these):
    #
    # No matter what I try herbstluftwm and XFCE fight over workspace names.
    xfconf-query -c xfwm4 -p /general/workspace_count -n -t int -s 1
    xfconf-query -c xfwm4 -p /general/workspace_names -n -t string -a -s "default"

    ${pkgs.pjones.hlwmrc}/libexec/hlwmrc --no-tag-import
  '';

  # XFCE Settings to apply on login:
  settings = pkgs.writeShellScript "xfce-settings" ''
    xfconf-query -c xfce4-session -p /startup/ssh-agent/enabled -n -t bool -s false
    xfconf-query -c xfce4-session -p /startup/gpg-agent/enabled -n -t bool -s false

    # Reset which commands are started with each session:
    xfconf-query -c xfce4-session -p /sessions/Failsafe/Count -n -t int -s 2

    # Start the settings daemon first:
    xfconf-query -c xfce4-session -p /sessions/Failsafe/Client0_Command \
      -n -a -t string -s "xfsettingsd"

    # Use herbstluftwm instead of xfwm4:
    xfconf-query -c xfce4-session -p /sessions/Failsafe/Client1_Command \
      -n -a -t string -s "${startHerbstluftwm}"
  '';

  # Generate a desktop file to automatically start something:
  makeAutorun = args:
    let item = pkgs.makeDesktopItem args;
    in "${item}/share/applications/${args.name}.desktop";
in
{
  options.tilde.programs.xfce = {
    enable = lib.mkEnableOption "Configure XFCE";

    wallpaperDirectory = lib.mkOption {
      type = lib.types.path;
      default = "${config.home.homeDirectory}/.config/wallpapers";
      description = "Directory of images";
    };
  };

  config = lib.mkIf cfg.enable {
    tilde.programs.polybar.enable = true;

    # Start my window manager:
    xsession = {
      enable = true;
      windowManager.command = ''
        ${pkgs.runtimeShell} ${pkgs.xfce.xfce4-session.xinitrc}
      '';
    };

    # I'm not quite sure why this doesn't start on its own:
    xdg.configFile."autostart/xfce4-notifyd.desktop".source =
      makeAutorun {
        name = "xfce4-notifyd";
        desktopName = "xfce4-notifyd";
        exec = "${pkgs.xfce.xfce4-notifyd}/lib/xfce4/notifyd/xfce4-notifyd";
      };

    # Set a default wallpaper:
    xsession.initExtra = ''
      # Apply XFCE settings before starting:
      ${settings}
    '';
  };
}
