{ self, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      apps.default = {
        type = "app";
        meta.description = "Run tilde in a VM";
        program = "${self.nixosConfigurations.demo.config.system.build.vm}/bin/run-tilde-demo-vm";
      };

      apps.wg-gen = {
        type = "app";
        program = "${self.packages.${system}.wg-gen}/bin/wg-gen-all.sh";
        meta.description = ''
          Generate WireGuard configuration files and QR codes.

          Use the -h command line option to learn more.
        '';
      };

      apps.enable-cache = {
        type = "app";

        meta.description = ''
          Configure Nix to use the tilde binary cache.
        '';

        program = toString (
          pkgs.writeShellScript "enable-cache" ''
            ${pkgs.cachix}/bin/cachix use pjones
          ''
        );
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
