{
  inputs,
  self,
  moduleWithSystem,
  ...
}:
{
  flake.nixosModules.falken = moduleWithSystem (
    { ... }:
    { ... }:
    {
      imports =
        with self.nixosModules;
        [
          tilde
          android
          laptop
          qmk
          smartd
          workstation
          yubikey
        ]
        ++ [
          inputs.superkey.nixosModules.falken
        ];

      config = {
        networking.hostName = "falken";

        services.kmonad = {
          enable = true;

          keyboards.internal = {
            device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
            config = builtins.readFile ../../support/keyboard/us_60.kbd;

            defcfg = {
              enable = true;
              fallthrough = true;
              compose.key = "compose";
            };
          };
        };

        home-manager.users.pjones = {
          imports = with self.homeModules; [
            mail
            mbsync
            msmtp
            mu
          ];

          config = {
            tilde.programs.ssh.keysDir = "~/keys/ssh";
          };
        };
      };
    }
  );

  # flake.nixosConfigurations.falken = inputs.nixpkgs.lib.nixosSystem {
  #   modules = self.lib.nixos.modulesForHost "falken" "x86_64-linux";
  # };

  perSystem = self.lib.nixos.checkHost "falken";

  # TODO: Bring in NixOS hardware
  # What else from Cassini can be brought into here?
}
