{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
{
  flake.nixosModules.demo = moduleWithSystem (
    { pkgs, ... }:
    { lib, ... }:
    let
      wallpaper = pkgs.fetchurl {
        url = "https://i.redd.it/tg9ac8kn10x41.jpg";
        sha256 = "0pb32hzrngl06c1icb2hmdq8ja7v1gc2m4ss32ihp6rk45c59lji";
      };
    in
    {
      imports = [
        self.nixosModules.qemu-guest
        self.nixosModules.test-autologin
        self.nixosModules.tilde
        self.nixosModules.workstation
      ];

      config = {
        networking.hostName = "tilde-demo";
        tilde.putInWheel = true;
        users.users.${self.lib.test.user.name}.password = self.lib.test.user.password;
        security.sudo.wheelNeedsPassword = false;

        home-manager.users.${self.lib.test.user.name} = {
          tilde.wayland.primaryOutput = "Virtual-1";

          services.wayle.settings.wallpaper.monitors = lib.singleton {
            name = "Virtual-1";
            wallpaper = toString wallpaper;
            fit-mode = "fill";
          };
        };
      };
    }
  );

  flake.nixosConfigurations.demo = inputs.nixpkgs.lib.nixosSystem {
    modules = self.lib.nixos.hostModules "demo" "x86_64-linux";
  };
}
