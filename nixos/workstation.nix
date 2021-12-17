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
    workstation/kmonad.nix
    workstation/qmk.nix
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
          virtmanager
          wirelesstools
        ];

        # For using different Nix caches:
        nix.trustedUsers = [ "@wheel" ];

        # For improved experience developing with Nix:
        nix.extraOptions = ''
          keep-outputs = true
          keep-derivations = true
        '';

        # Useful services:
        hardware.bluetooth.enable = true;
        services.blueman.enable = lib.mkDefault true;
        services.clight.enable = true;

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
          useDHCP = false;
          wireless.enable = false;
        };

        # Sound:
        sound.enable = true;
        hardware.pulseaudio.enable = true;
        hardware.pulseaudio.package = pkgs.pulseaudioFull;

        # Printing:
        services.printing = {
          enable = true;
          drivers =
            lib.optional
              pkgs.stdenv.isx86_64
              pkgs.canon-cups-ufr2;
        };

        # Needed for some other services:
        location.provider = "geoclue2";
        time.hardwareClockInLocalTime = true;
        time.timeZone = "America/Phoenix";

        virtualisation = {
          libvirtd.enable = true;
          docker = {
            enable = true;
            autoPrune.enable = true;
          };
        };
      })
      (lib.mkIf (cfg.enable && cfg.type == "laptop") {
        environment.systemPackages = with pkgs; [
          acpi
          powertop
        ];

        services.logind = {
          # Closing the lid will store hibernation data to disk then
          # suspend.  Therefore, if the battery dies while on standby,
          # you can still get back to where you left off.
          lidSwitch = "hybrid-sleep";
          lidSwitchExternalPower = "hybrid-sleep";
        };

        # Useful services:
        hardware.acpilight.enable = true;
        services.thermald.enable = pkgs.stdenv.isx86_64;
        services.upower.enable = true;
        powerManagement.powertop.enable = true;
      })
    ];
}
