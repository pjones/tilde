{
  inputs,
  self,
  withSystem,
  ...
}:
{
  flake.nixOnDroidConfigurations.chet = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
    pkgs = withSystem "aarch64-linux" ({ pkgs, ... }: pkgs);

    modules = with self.nixOnDroidModules; [
      tilde
    ];
  };
}
