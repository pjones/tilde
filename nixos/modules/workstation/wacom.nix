# Hardware settings for a Wacom One M tablet:
#
# FIXME: This doesn't work yet because it depends on external scripts
# that I have not yet put in public repos.
{ config, lib, pkgs, ...}: with lib;

let cfg = config.pjones.wacom;

    user = "pjones";

    script = pkgs.writeScript "wacom-init" ''
      #!${pkgs.bash}/bin/bash -eu
      export PATH="/home/${user}/.nix-profile/bin:/run/current-system/sw/bin"
      export XAUTHORITY=/home/${user}/.Xauthority
      export DISPLAY=":0"

      sleep 1

      xinput --map-to-output "Wacom Bamboo One M Pad" "$display" || :
      xinput --map-to-output "Wacom Bamboo One M Pen" "$display" || :
      notify-send "Wacom Bamboo" "Device configured and ready for use on $display."
    '';
in
{
  options.pjones.wacom = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable desktop Wacom configuration.";
    };
  };

  config = mkIf cfg.enable {
    services.udev.extraRules = ''
      SUBSYSTEM=="input", ATTRS{name}=="Wacom Bamboo One M Pad", RUN+="${script}"
    '';
  };
}
