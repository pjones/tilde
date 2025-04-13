{ config, lib, pkgs, ... }:

let
  cfg = config.tilde.boot;

  staticIpOptions = { ... }: {
    options = {
      address = lib.mkOption {
        type = lib.types.str;
        description = "IPv4 address to listen on";
      };

      gateway = lib.mkOption {
        type = lib.types.str;
        description = "IPv4 gateway";
      };

      netmask = lib.mkOption {
        type = lib.types.str;
        description = "IPv4 netmask";
      };
    };
  };

  # https://www.kernel.org/doc/Documentation/filesystems/nfs/nfsroot.txt
  kernelNetworkingOptions =
    let
      options =
        if cfg.network != null
        then {
          inherit (cfg.network) address gateway netmask;
          dhcp = "none";
        }
        else {
          address = "";
          gateway = "";
          netmask = "";
          dhcp = "dhcp";
        };
    in
    "ip=" + lib.concatStringsSep ":" [
      options.address
      "" # NFS server address
      options.gateway
      options.netmask
      config.networking.hostName
      cfg.interface
      options.dhcp
    ];
in
{
  options.tilde.boot = {
    enable = lib.mkEnableOption ''
      Configure initrd to boot with networking enabled and a SSH
      server running.

      Note this module also enables systemd-boot so that the SSH host
      key is stored in the boot partition and *not* in the hosts's Nix
      store.
    '';

    interface = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        The interface device to configure.  Leave blank to let the
        kernel decide.
      '';
    };

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

    network = lib.mkOption {
      type = with lib.types; nullOr (submodule staticIpOptions);
      default = null;
      description = ''
        Network configuration.  By default DHCP is used.
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
        Path to a SSH host key that will be copied into initrd at
        build time.  That means the key will be in the Nix store on
        the build machine :(

        WARNING: you should generate a separate SSH host key for
        initrd.  DO NOT use the system's host key in `/etc`!
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot.enable = lib.mkDefault true;
    boot.kernelParams = [ kernelNetworkingOptions ];

    boot.initrd = {
      inherit (cfg) kernelModules;

      network = {
        enable = true;

        ssh = {
          enable = true;
          port = cfg.ssh.port;
          authorizedKeys = cfg.ssh.authorizedKeys;
          hostKeys = [ cfg.ssh.hostKey ];
        };

        postCommands = ''
          cat <<EOT > /root/.profile
          cryptsetup-askpass
          EOT
        '';
      };
    };
  };
}
