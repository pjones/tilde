{ pkgs, config, lib, ... }:

let
  cfg = config.tilde.programs.telegram;
in
{
  options.tilde.programs.telegram = {
    enable = lib.mkEnableOption "Telegram";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.tdesktop ];

    # Disable some really stupid Telegram settings:
    home.file.".local/share/TelegramDesktop/tdata/shortcuts-custom.json".text = ''
      [
        {
          "command": null,
          "keys": "ctrl+f"
        },
        {
          "command": null,
          "keys": "ctrl+w"
        }
      ]
    '';
  };
}
