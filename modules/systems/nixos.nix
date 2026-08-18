{
  inputs,
  self,
  lib,
  withSystem,
  moduleWithSystem,
  ...
}:
{
  flake.nixosModules.tilde = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    {
      imports = [
        inputs.backup-scripts.nixosModules.backup-scripts
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        inputs.nixpkgs.nixosModules.notDetected
        inputs.sops-nix.nixosModules.sops
        self.nixosModules.boot-ssh
        self.nixosModules.crontab
        self.nixosModules.hardening
        self.nixosModules.nix
        self.nixosModules.pjones
        self.nixosModules.sudo
      ];

      options.tilde = {
        privateInterface = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = ''
            An interface that private services can listen on.
          '';
        };

        networkWait = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
          description = ''
            List of systemd services that network services should wait
            for.  For example, starting services after the WireGuard
            interface is up.
          '';
        };
      };

      config = {
        system.stateVersion = self.lib.state.version;

        # Basic firewall settings:
        networking.firewall = {
          enable = true;
          allowPing = true;
          pingLimit = "--limit 1/minute --limit-burst 5";
        };

        # Don't let PostgreSQL change with each upgrade:
        services.postgresql.package = lib.mkForce pkgs.postgresql_16;

        # Keep /boot from filling up!
        boot.loader.systemd-boot.configurationLimit = 20;

        #time.timeZone = lib.mkDefault "America/Phoenix";
        time.hardwareClockInLocalTime = true;
        hardware.enableRedistributableFirmware = true;

        # Remote access:
        services.openssh = {
          enable = true;
          openFirewall = false; # Must go through VPN.
          settings.PasswordAuthentication = false;
          settings.PermitRootLogin = "without-password";
        };

        # I want my user account in the wheel group for sudo:
        tilde.putInWheel = true;

        tilde.crontab = {
          # All machines should have their download directory cleaned
          # periodically:
          clean-download-directory = {
            user = config.tilde.username;
            schedule = "daily";
            path = [ pkgs.pjones.maintenance-scripts ];
            script = ''
              if [ -d "$HOME/download" ]; then
                delete-older-files.sh "$HOME/download"
              fi
            '';
          };
        };

        home-manager = {
          backupFileExtension = "backup";
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };
    }
  );

  flake.lib.nixos = {
    # Return a systemd service configuration that forces a service to
    # wait until after critical network services are alive.
    waitForTilde = config: {
      requires = config.tilde.networkWait;
      after = config.tilde.networkWait;
    };

    # Return a list of NixOS modules for the given host.
    hostModules = host: system: [
      # The host module:
      self.nixosModules.${host}

      # Don't allow changing nixpkgs after this:
      inputs.nixpkgs.nixosModules.readOnlyPkgs

      # Set nixpkgs:
      (
        { ... }:
        {
          nixpkgs.pkgs = withSystem system ({ pkgs, ... }: pkgs);
        }
      )
    ];

    # Create a NixOS test to ensure each host configuration works
    # correctly. For now I just build a VM but don't run it.
    mkCheck =
      {
        host,
        withDisko ? true,
      }:
      {
        ${host} = self.nixosConfigurations.${host}.config.system.build.vm;
      }
      // lib.optionalAttrs withDisko {
        "disko-${host}" = self.nixosConfigurations.${host}.config.system.build.diskoScript;
      };
  };
}
