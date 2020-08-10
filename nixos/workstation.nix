{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.workstation;
in
{
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
        tilde.workstation.keyboard.enable = lib.mkDefault true;

        # Extra system pacakges:
        environment.systemPackages = with pkgs; [
          lm_sensors
          OVMF # For EFI booting.
          rfkill
          virtmanager
          wirelesstools
        ];

        # For using different Nix caches:
        nix.trustedUsers = [ "@wheel" ];

        # Useful services:
        hardware.bluetooth.enable = true;
        services.blueman.enable = lib.mkDefault true;
        services.avahi.enable = true;
        services.clight.enable = true;

        # Networking:
        networking = {
          nat.enable = true;
          nat.internalInterfaces = [ "ve-+" ];
          networkmanager.enable = true;
          useDHCP = false;
          wicd.enable = false;
          wireless.enable = false;
        };

        # Sound:
        sound.enable = true;
        hardware.pulseaudio.enable = true;
        hardware.pulseaudio.package = pkgs.pulseaudioFull;

        # Printing:
        services.printing = {
          enable = true;
          drivers = with pkgs; [
            cups-googlecloudprint
          ];
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

        # Needed by virt-manager:
        security.wrappers.spice-client-glib-usb-acl-helper.source =
          "${pkgs.spice_gtk}/bin/spice-client-glib-usb-acl-helper";
      })
      (lib.mkIf (cfg.enable && cfg.type == "laptop") {
        environment.systemPackages = with pkgs;
          [
            acpi
            powertop
          ];

        # Closing the lid should suspend the computer.  See
        # logind.conf(5) for more details.
        services.logind.extraConfig = ''
          IdleAction=ignore
          HandlePowerKey=hybrid-sleep
          HandleSuspendKey=suspend
          HandleHibernateKey=suspend
          HandleLidSwitch=suspend
          PowerKeyIgnoreInhibited=on
          SuspendKeyIgnoreInhibited=on
          HibernateKeyIgnoreInhibited=on
          LidSwitchIgnoreInhibited=on
        '';

        # Useful services:
        hardware.acpilight.enable = true;
        services.thermald.enable = true;
        services.upower.enable = true;
      })
    ];
}
