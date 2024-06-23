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
          OVMF # For EFI booting.
          spice-gtk
          virt-manager
          wirelesstools
        ];

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

        # Index system man pages:
        documentation.man.generateCaches = true;

        # Local service discovery:
        services.avahi = {
          enable = true;
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
          drivers =
            lib.optional
              pkgs.stdenv.isx86_64
              pkgs.canon-cups-ufr2;
        };

        virtualisation = {
          libvirtd = {
            enable = true;
            onShutdown = "suspend";
            onBoot = "ignore";
          };

          docker = {
            enable = true;
            enableOnBoot = cfg.type != "laptop";
            autoPrune.enable = true;
          };
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

        services.logind = {
          lidSwitch = "suspend-then-hibernate";
          lidSwitchExternalPower = "suspend-then-hibernate";
          extraConfig = ''
            HibernateDelaySec=30m
          '';
        };

        # Useful services:
        hardware.acpilight.enable = true;
        services.thermald.enable = pkgs.stdenv.isx86_64;
        services.upower.enable = true;

        # This is enabled by desktop environments like Plasma, so we
        # need to turn it off manually here:
        services.power-profiles-daemon.enable = lib.mkForce false;

        # And we'll use TLP to deal with power management:
        services.tlp = {
          enable = true;
          settings = {
            CPU_SCALING_GOVERNOR_ON_AC = "performance";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          };
        };
      })
    ];
}
