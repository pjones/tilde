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
        self.inputs.superkey.nixosModules.autologin
        self.inputs.superkey.nixosModules.qemu-wayland
        self.nixosModules.qemu-guest
        self.nixosModules.tilde
        self.nixosModules.workstation
      ];

      config = {
        networking.hostName = "tilde-demo";
        tilde.putInWheel = true;
        users.users.${self.lib.test.user.name}.password = self.lib.test.user.password;
        security.sudo.wheelNeedsPassword = false;

        home-manager.users.${self.lib.test.user.name} = {
          superkey.primaryOutput = "Virtual-1";
        };
      };
    }
  );

  flake.nixosConfigurations.demo = inputs.nixpkgs.lib.nixosSystem {
    modules = self.lib.nixos.hostModules "demo" "x86_64-linux";
  };
}
