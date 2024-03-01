{ pkgs, config, options, lib, ... }:
let
  cfg = config.tilde.programs.contacts;

  passFile = "services/email/fastmail.com/vdirsyncer";

  readUserName = pkgs.writeShellApplication {
    name = "read-fm-user";
    runtimeInputs = with pkgs; [
      config.programs.gpg.package
      gnugrep
      gnused
      pass
    ];
    text = ''
      pass show ${passFile} | grep -E ^user: | sed -E 's/^user: +//'
    '';
  };

  readPassword = pkgs.writeShellApplication {
    name = "read-fm-pass";
    runtimeInputs = with pkgs; [
      config.programs.gpg.package
      coreutils
      pass
    ];
    text = ''
      pass show ${passFile} | head -1
    '';
  };

  cardIsUnlocked = pkgs.writeShellApplication {
    name = "card-is-unlocked";
    runtimeInputs = [ config.programs.gpg.package ];
    text = ''
      echo "test" |
        gpg2 --sign --armor --quiet --batch --no-tty --pinentry-mode error -o /dev/null
    '';
  };

  vdirsyncerConf = ''
    [general]
    status_path = "${config.xdg.dataHome}/vdirsyncer/status"

    [pair fm_contacts]
    a = "fm_contacts_local"
    b = "fm_contacts_remote"
    collections = ["from b"]
    conflict_resolution = "b wins"

    [storage fm_contacts_local]
    type = "filesystem"
    path = "${config.home.homeDirectory}/contacts"
    fileext = ".vcf"

    [storage fm_contacts_remote]
    type = "carddav"
    url = "https://carddav.fastmail.com/"
    username.fetch = ["command", "${readUserName}/bin/read-fm-user"]
    password.fetch = ["command", "${readPassword}/bin/read-fm-pass"]
  '';

  khardConf = ''
    [addressbooks]
    [[personal]]
    path = ${config.home.homeDirectory}/contacts/Default/
    [[shared]]
    path = ${config.home.homeDirectory}/contacts/masteruser_autohwyrel2@fastmail.com.Shared/
  '';
in
{
  options.tilde.programs.contacts = {
    enable = lib.mkEnableOption "Sync with CardDAV";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      vdirsyncer
      khard
    ];

    xdg.configFile = {
      "vdirsyncer/config".text = vdirsyncerConf;
      "khard/khard.conf".text = khardConf;
    };

    systemd.user.services.vdirsyncer = {
      Unit = {
        Description = "vdirsyncer synchronization";
        PartOf = [ "network-online.target" ];
      };

      Service = {
        Type = "oneshot";
        Environment = [ "GNUPGHOME=${config.programs.gpg.homedir}" ];
        ExecCondition = "${cardIsUnlocked}/bin/card-is-unlocked";
        ExecStart =
          let vdirsyncer = "${pkgs.vdirsyncer}/bin/vdirsyncer";
          in [
            "${vdirsyncer} metasync"
            "${vdirsyncer} sync"
          ];
      };
    };

    systemd.user.timers.vdirsyncer = {
      Unit.Description = "vdirsyncer synchronization";
      Install.WantedBy = [ "timers.target" ];

      Timer = {
        OnUnitActiveSec = "1h";
        Unit = "vdirsyncer.service";
      };
    };
  };
}
