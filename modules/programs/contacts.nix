{ moduleWithSystem, ... }:
{
  flake.homeModules.contacts = moduleWithSystem (
    { pkgs, ... }:
    { config, ... }:
    let
      fmPassFile = "services/email/fastmail.com/vdirsyncer";
      tuPassFile = "work/tuebingen/wsi";

      passDeps = with pkgs; [
        config.programs.gpg.package
        coreutils
        gnugrep
        gnused
        pass
      ];

      readUserName =
        entry:
        pkgs.writeShellApplication {
          name = "read-fm-user";
          runtimeInputs = passDeps;
          text = ''
            pass show ${entry} | grep -iE ^user: | sed -E 's/^user: +//i' | head -1
          '';
        };

      readPassword =
        entry:
        pkgs.writeShellApplication {
          name = "read-fm-pass";
          runtimeInputs = passDeps;
          text = ''
            pass show ${entry} | head -1
          '';
        };

      vdirsyncerConf =
        let
          user_pass = entry: ''
            username.fetch = ["command", "${readUserName entry}/bin/read-fm-user"]
            password.fetch = ["command", "${readPassword entry}/bin/read-fm-pass"]
          '';

          # Side A: Local Storage
          # Side B: Remote Storage (CalDAV)
          fmCalCollections = [
            [
              "arizona"
              "arizona"
              "f89d3c83-6ac0-4d12-9d90-6065d0b8a76d"
            ]
            [
              "fam"
              "fam"
              "a7503614-9257-41ac-8de6-67192f006233"
            ]
            [
              "germany"
              "germany"
              "9e766a84-37c4-4076-8e42-02c7520dee4c"
            ]
            [
              "peter"
              "peter"
              "9AC84BAA-0DF0-11ED-8E05-BBF12FD9EBDA"
            ]
            [
              "shanna"
              "shanna"
              "shanna@jonesbunch.com.9F658776-0DF6-11ED-86FE-38DD605BB2E4"
            ]
          ];

          fmCardCollections = [
            [
              "peter"
              "peter"
              "Default"
            ]
            [
              "global"
              "global"
              "masteruser_autohwyrel2@fastmail.com.Shared"
            ]
          ];

          tuCalCollections = [
            [
              "personal"
              "personal"
              "personal"
            ]
            [
              "kohlbacher"
              "kohlbacher"
              "kohlbacher-lab_shared_by_47d6ff10-55dd-11ed-b23a-901b0ec6eb8c"
            ]
          ];

          tuCardCollections = [
            [
              "contacts"
              "contacts"
              "contacts"
            ]
            [
              "apps"
              "apps"
              "z-app-generated--contactsinteraction--recent"
            ]
          ];
        in
        ''
          [general]
          status_path = "${config.xdg.dataHome}/vdirsyncer/status"

          [storage fm_contacts_local]
          type = "filesystem"
          path = "${config.home.homeDirectory}/contacts/fastmail"
          fileext = ".vcf"

          [storage fm_contacts_remote]
          type = "carddav"
          url = "https://carddav.fastmail.com/"
          ${user_pass fmPassFile}

          [pair fm_contacts]
          a = "fm_contacts_local"
          b = "fm_contacts_remote"
          collections = ${builtins.toJSON fmCardCollections}
          conflict_resolution = "b wins"
          metadata = ["displayname"]

          [storage fm_cal_local]
          type = "filesystem"
          path = "${config.home.homeDirectory}/calendars/fastmail"
          fileext = ".ics"

          [storage fm_cal_remote]
          type = "caldav"
          url = "https://caldav.fastmail.com/"
          ${user_pass fmPassFile}
          start_date = "datetime.now() - timedelta(days=365)"
          end_date = "datetime.now() + timedelta(days=365)"

          [pair fm_cal]
          a = "fm_cal_local"
          b = "fm_cal_remote"
          collections = ${builtins.toJSON fmCalCollections}
          conflict_resolution = "b wins"
          metadata = ["color", "displayname", "description", "order"]

          [storage tu_contacts_local]
          type = "filesystem"
          path = "${config.home.homeDirectory}/contacts/tuebingen"
          fileext = ".vcf"

          [storage tu_contacts_remote]
          type = "carddav"
          url = "https://caura.cs.uni-tuebingen.de/"
          ${user_pass tuPassFile}

          [pair tu_contacts]
          a = "tu_contacts_local"
          b = "tu_contacts_remote"
          collections = ${builtins.toJSON tuCardCollections}
          conflict_resolution = "b wins"
          metadata = ["displayname"]

          [storage tu_cal_local]
          type = "filesystem"
          path = "${config.home.homeDirectory}/calendars/tuebingen"
          fileext = ".ics"

          [storage tu_cal_remote]
          type = "caldav"
          url = "https://caura.cs.uni-tuebingen.de/"
          ${user_pass tuPassFile}
          start_date = "datetime.now() - timedelta(days=365)"
          end_date = "datetime.now() + timedelta(days=365)"

          [pair tu_cal]
          a = "tu_cal_local"
          b = "tu_cal_remote"
          collections = ${builtins.toJSON tuCalCollections}
          conflict_resolution = "b wins"
          metadata = ["color", "displayname", "description", "order"]
        '';

      khalConf = ''
        [default]
        default_calendar = Peter

        [calendars]
        [[personal]]
        path = ~/calendars/fastmail/*
        type = discover
        default_event_alarm = 15m

        [[work]]
        path = ~/calendars/tuebingen/*
        type = discover
        default_event_alarm = 15m

        [[birthdays]]
        path = ~/contacts/fastmail/peter
        type = birthdays
        readonly = True

        [locale]
        timeformat = %H:%M
        dateformat = %Y-%m-%d
        longdateformat = %Y-%m-%d %a
        datetimeformat = %Y-%m-%d %H:%M
        longdatetimeformat = %Y-%m-%d %H:%M
      '';

      khardConf = ''
        [addressbooks]
        [[personal]]
        path = ${config.home.homeDirectory}/contacts/fastmail/peter
        [[shared]]
        path = ${config.home.homeDirectory}/contacts/fastmail/global
      '';
    in
    {
      config = {
        home.packages = with pkgs; [
          khal
          khard
          vdirsyncer
        ];

        xdg.configFile = {
          "khal/config".text = khalConf;
          "khard/khard.conf".text = khardConf;
          "vdirsyncer/config".text = vdirsyncerConf;
        };
      };
    }
  );
}
