{ self, ... }:
{
  perSystem =
    { ... }:
    {
      apps.default = {
        type = "app";
        meta.description = "Run tilde in a VM";
        program = "${self.nixosConfigurations.demo.config.system.build.vm}/bin/run-tilde-demo-vm";
      };

      # Run a VM then take a screenshot and store it locally:
      # screenshot =
      #   let
      #     script = pkgs.writeShellScript "screenshot" ''
      #       cp --force \
      #         ${self.packages.${system}.screenshot}/screenshot-*.png \
      #         support/
      #     '';
      #   in
      #   {
      #     type = "app";
      #     meta.description = "Run the VM and take a screenshot";
      #     program = "${script}";
    };
}
