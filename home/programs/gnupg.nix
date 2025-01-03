{ config, lib, pkgs, ... }:

let
  cfg = config.tilde.programs.gnupg;

  cardIsUnlocked = pkgs.writeShellApplication {
    name = "card-is-unlocked";
    runtimeInputs = [ config.programs.gpg.package ];
    text = ''
      echo "test" |
        gpg2 \
          --sign \
          --armor \
          --quiet \
          --batch \
          --no-tty \
          --pinentry-mode error \
          -o /dev/null
    '';
  };
in
{
  options.tilde.programs.gnupg = {
    enable = lib.mkEnableOption "Enable GnuPG";

    cardIsUnlockedScript = lib.mkOption {
      type = lib.types.path;
      default = "${cardIsUnlocked}/bin/card-is-unlocked";
      description = "Script that can test if a smartcard is unlocked.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cardIsUnlocked ];

    programs.gpg = {
      enable = true;
      homedir = "${config.home.homeDirectory}/keys/gpg";
      settings = {
        default-key = "4D0CD0756F1B8B9D3DCD0CAAE1CF584F79D0D3DC";
        default-recipient-self = true;
      };
    };

    services.gpg-agent = {
      enable = true;
      enableSshSupport = false;
      defaultCacheTtl = 3600;
      defaultCacheTtlSsh = 14400;
      maxCacheTtl = 7200;
      maxCacheTtlSsh = 21600;
      pinentryPackage = pkgs.pinentry-qt;
    };
  };
}
