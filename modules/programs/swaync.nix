{ moduleWithSystem, ... }:
{
  flake.homeModules.swaync = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        services.swaync = {
          enable = true;

          settings = {
            timeout = 10;
            timeout-low = 5;
            timeout-critical = 0;

            widgets = [
              "inhibitors"
              "title"
              "dnd"
              "mpris"
              "notifications"
            ];

            widget-config = {
              inhibitors = {
                text = "Inhibitors";
                button-text = "Clear All";
                clear-all-button = true;
              };
              title = {
                text = "Notifications";
                clear-all-button = true;
                button-text = "Clear All";
              };
              dnd = {
                text = "Do Not Disturb";
              };
              mpris = {
                image-size = 96;
                image-radius = 12;
              };
            };
          };
        };
      };
    }
  );
}
