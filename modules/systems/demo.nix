{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
{
  flake.nixosModules.demo = moduleWithSystem (
    { ... }:
    { ... }:
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
        };
      };
    }
  );

  flake.nixosConfigurations.demo = inputs.nixpkgs.lib.nixosSystem {
    modules = self.lib.nixos.hostModules "demo" "x86_64-linux";
  };
}
