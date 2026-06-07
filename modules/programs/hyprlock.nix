{ moduleWithSystem, ... }:
{
  flake.nixosModules.hyprlock = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        # https://github.com/NixOS/nixpkgs/issues/158025
        security.pam.services.hyprlock = { };
      };
    }
  );

  flake.homeModules.hyprlock = moduleWithSystem (
    { ... }:
    { config, ... }:
    {
      config = {
        tilde.wayland.lock.screenLockCmd = "${config.programs.hyprlock.package}/bin/hyprlock";

        programs.hyprlock = {
          enable = true;

          settings = {
            general = {
              hide_cursor = true;
              ignore_empty_input = true;
            };

            auth = {
              fingerprint = {
                enabled = true;
                ready_message = "󰈷";
                present_message = "󰁲";
                retry_delay = 250;
              };
            };

            background = [
              {
                monitor = "";
                path = config.tilde.wayland.lock.imageCachePath;
              }
            ];

            animations = {
              enabled = true;
              fade_in = {
                duration = 300;
                bezier = "easeOutQuint";
              };
              fade_out = {
                duration = 300;
                bezier = "easeOutQuint";
              };
            };

            input-field = [
              {
                size = "200, 50";
                halign = "center";
                valign = "bottom";
                position = "0, 10";
                monitor = "";
                dots_center = true;
                fade_on_empty = true;
                font_color = "rgb(202, 211, 245)";
                inner_color = "rgb(91, 96, 120)";
                outer_color = "rgb(24, 25, 38)";
                outline_thickness = 5;
                shadow_passes = 2;
                placeholder_text = "";
              }
            ];

            label = [
              {
                text = "$FPRINTPROMPT";
                monitor = "";
                font_size = 25;
                font_family = "AtkinsonHyperlegible Nerd Font";
                position = "0, 10";
                halign = "left";
                valign = "bottom";
              }
            ];
          };
        };
      };
    }
  );
}
