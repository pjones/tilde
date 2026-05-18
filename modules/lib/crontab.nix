# Emulate cron via systemd timers.
#
# Why, you ask?  Because then I can configure cron jobs in Nix.
{ moduleWithSystem, ... }:
{
  flake.nixosModules.crontab = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      cronjobs = lib.attrValues config.tilde.crontab;

      # Type to represent a single cron job.
      jobType =
        { name, ... }:
        {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "The name of this cron job.";
            };

            user = lib.mkOption {
              type = lib.types.str;
              description = "The user this job runs as.";
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
        description = "${job.name} cron job for ${job.user}";
        path = [ pkgs.coreutils ] ++ job.path;
        script = job.script;
        serviceConfig.Type = "simple";
        serviceConfig.User = job.user;
        serviceConfig.WorkingDirectory = "~";
      };

      # Generate a systemd timer for a job.
      timer = unit: job: {
        description = "Scheduled ${job.name} cron job for ${job.user}";
        wantedBy = [ "timers.target" ];
        timerConfig.OnCalendar = job.schedule;
        timerConfig.Unit = "${unit}.service";
      };

      # Generate systemd services and timers.
      toSystemd =
        f:
        lib.foldr (
          job: config:
          let
            unit = "crontab-${job.user}-${job.name}";
          in
          config // { ${unit} = f unit job; }
        ) { } cronjobs;
    in
    {
      options.tilde.crontab = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule jobType);
        default = { };
        description = "Attribute set of jobs to schedule.";
      };

      config = lib.mkIf (builtins.length cronjobs != 0) {
        systemd = {
          services = toSystemd service;
          timers = toSystemd timer;
        };
      };
    }
  );
}
