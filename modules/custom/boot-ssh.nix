{ moduleWithSystem, ... }:
{
  flake.nixosModules.boot-ssh = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.boot-ssh;

      hostKey = {
        initrdPath = "/secrets/boot/ssh/ssh_host_ed25519_key";
        pkg = pkgs.runCommand "initrd-ssh" { } ''
          cp ${cfg.ssh.hostKey} "$out"
        '';
      };
    in
    {
      options.tilde.boot-ssh = {
        enable = lib.mkEnableOption ''
          Configure initrd to boot with networking enabled and a SSH
          server running.

          Note this module also enables systemd-boot so that the SSH host
          key is stored in the boot partition and *not* in the hosts's Nix
          store.
        '';

        kernelModules = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
          description = ''
            Kernel modules needed in initrd to use networking.  You
            especially need any modules that are required for your network
            device.  You can discover those modules via:

            ```sh
            lspci -v | grep -iA8 'network\|ethernet'
            ```
          '';
        };

        ssh.port = lib.mkOption {
          type = lib.types.port;
          default = 4;
          description = ''
            Port on which the SSH running in initrd should listen.

            Using port 22 isn't advised because this SSH daemon will have
            a different host key and SSH clients don't like having two
            keys for the same port.
          '';
        };

        ssh.authorizedKeys = lib.mkOption {
          type = with lib.types; listOf str;
          default = config.users.users.root.openssh.authorizedKeys.keys;
          description = ''
            Which SSH keys are allowed to be used for logging in.  By
            default all of root's authorized keys are used.
          '';
        };

        ssh.hostKey = lib.mkOption {
          type = lib.types.path;
          description = ''
            A Nix path to the SSH host key.  This path will be copied
            to the Nix store to work around issues with the initrd SSH
            module.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        boot.loader.systemd-boot.enable = true;

        boot.initrd = {
          availableKernelModules = cfg.kernelModules;
          secrets.${hostKey.initrdPath} = toString hostKey.pkg;

          network = {
            enable = true;

            ssh = {
              enable = true;
              port = cfg.ssh.port;
              authorizedKeys = cfg.ssh.authorizedKeys;
              ignoreEmptyHostKeys = true;
              extraConfig = "HostKey ${hostKey.initrdPath}";
            };
          };

          systemd = {
            enable = true;
            users.root.shell = "/bin/systemd-tty-ask-password-agent";
            services.sshd.preStart = "/bin/chmod 0600 ${hostKey.initrdPath}";

            network = {
              enable = true;
              wait-online.anyInterface = true;

              networks."10-any" = {
                matchConfig.Name = "*";
                networkConfig.DHCP = "ipv4";
                linkConfig.RequiredForOnline = "routable";
              };
            };
          };
        };
      };
    }
  );
}
