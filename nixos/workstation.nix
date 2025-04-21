{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.workstation;
in
{
  imports = [
    programs/android.nix
    programs/qmk.nix
  ];

  options.tilde.workstation = {
    enable = lib.mkEnableOption ''
      Enable settings for workstations.

      A workstation is a machine that doesn't necessarily have a GUI
      but may nonetheless have features that are not available on a
      server-like machine.  For example, Bluetooth and printing.
    '';

    type = lib.mkOption {
      type = lib.types.enum [ "desktop" "laptop" ];
      default = "desktop";
      description = ''
        Control the type of workstation.
      '';
    };
  };

  config = lib.mkMerge
    [
      (lib.mkIf cfg.enable {
        # Some other modules to enable by default:
        tilde.workstation.yubikey.enable = lib.mkDefault true;

        # Extra system pacakges:
        environment.systemPackages = with pkgs; [
          lm_sensors
          man-pages # Developer man pages.
          OVMFFull # For EFI booting.
          spice-gtk
          virt-manager
          wirelesstools
        ];

        # Install documentation and man pages:
        documentation = {
          enable = true;
          man.enable = true;
          info.enable = true;
          doc.enable = true;
          dev.enable = true;
          man.generateCaches = true;
        };

        # Default time zone:
        time.timeZone = lib.mkDefault "America/Phoenix";
        time.hardwareClockInLocalTime = true;

        # For using different Nix caches:
        nix.settings.trusted-users = [ "@wheel" ];

        # For improved experience developing with Nix:
        nix.extraOptions = ''
          keep-outputs = true
          keep-derivations = true
        '';

        # Useful services:
        hardware.bluetooth.enable = true;
        services.blueman.enable = lib.mkDefault true;

        # Local service discovery:
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          domainName = config.networking.domain;
        };

        # Networking:
        networking = {
          nat.enable = true;
          nat.internalInterfaces = [ "ve-+" ];
          networkmanager.enable = true;
          networkmanager.unmanaged = [ "interface-name:ve-*" ];
          useDHCP = false;
          wireless.enable = false;
        };

        # Printing:
        services.printing = {
          enable = true;
          browsing = true;

          drivers =
            lib.optional
              pkgs.stdenv.isx86_64
              pkgs.cups-kyodialog;

          browsedConf = ''
            BrowseDNSSDSubTypes _cups,_print
            BrowseLocalProtocols all
            BrowseRemoteProtocols all
            CreateIPPPrinterQueues All
            BrowseProtocols all
          '';
        };

        virtualisation = {
          libvirtd = {
            enable = true;
            onShutdown = "suspend";
            onBoot = "ignore";

            qemu = {
              swtpm.enable = true;
              ovmf.packages = [ pkgs.OVMFFull.fd ];
            };
          };

          docker = {
            enable = true;
            enableOnBoot = cfg.type != "laptop";
            autoPrune.enable = true;
          };
        };

        # Flatpak:
        #
        # https://wiki.nixos.org/wiki/Flatpak
        services.flatpak.enable = true;
        systemd.services.flatpak-repo = {
          after = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          path = [ pkgs.flatpak ];
          script = ''
            flatpak remote-add --if-not-exists \
              flathub https://dl.flathub.org/repo/flathub.flatpakrepo
          '';
        };
      })
      (lib.mkIf (cfg.enable && cfg.type == "laptop") {
        environment.systemPackages = with pkgs; [
          acpi
          powertop
        ];

        # Use the local time zone:
        services.geoclue2.enable = true;
        services.localtimed.enable = true;
        location.provider = "geoclue2";
        time.timeZone = lib.mkForce null;

        # Sleeping (see sleep.conf.d(5)):
        #
        # Only set these if you want to force hibernation earlier:
        #  HibernateDelaySec=2h
        #  SuspendEstimationSec=10m
        systemd.sleep.extraConfig = ''
          SuspendState=mem
        '';

        services.logind = {
          lidSwitch = "suspend-then-hibernate";
          lidSwitchDocked = "suspend-then-hibernate";
          lidSwitchExternalPower = "suspend-then-hibernate";
        };

        # Useful services:
        hardware.acpilight.enable = true;
        services.thermald.enable = pkgs.stdenv.isx86_64;
        services.upower.enable = true;
      })
    ];
}
