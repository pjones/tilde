# Emulate cron via systemd timers.
{ pkgs, config, lib, ... }:
let
  cfg = config.tilde.crontab;
  user = config.tilde.username;

  # Type to represent a single cron job.
  jobType = { name, ... }: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "The name of this cron job.";
      };

      path = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "List of packages to put in PATH.";
      };

      script = lib.mkOption {
        type = lib.types.lines;
        description = "Script to run.";
      };

      schedule = lib.mkOption {
        type = lib.types.str;
        example = "*-*-* *:00/30:00";
        description = ''
          A systemd calendar specification to designate the frequency
          of the script.  You can use the "systemd-analyze calendar"
          command to validate your calendar specification.
        '';
      };
    };

    config = {
      name = lib.mkDefault name;
    };
  };

  # Generate a systemd service for a job.
  service = _unit: job: {
    description = "${job.name} cron job for ${user}";
    path = [ pkgs.coreutils ] ++ job.path;
    script = job.script;
    serviceConfig.Type = "simple";
    serviceConfig.User = user;
    serviceConfig.WorkingDirectory = "~";
  };

  # Generate a systemd timer for a job.
  timer = unit: job: {
    description = "Scheduled ${job.name} cron job for ${user}";
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = job.schedule;
    timerConfig.Unit = "${unit}.service";
  };

  # Generate systemd services and timers.
  toSystemd = f:
    lib.foldr
      (job: config:
        let unit = "crontab-${user}-${job.name}";
        in config // { ${unit} = f unit job; })
      { }
      (lib.attrValues cfg);
in
{
  options.tilde.crontab = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule jobType);
    default = { };
    description = "Attribute set of jobs to schedule.";
  };

  config = lib.mkIf config.tilde.enable {
    systemd = {
      services = toSystemd service;
      timers = toSystemd timer;
    };
  };
}
