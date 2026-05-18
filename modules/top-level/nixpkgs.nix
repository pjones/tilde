{
  self,
  inputs,
  ...
}:
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;

        config.allowUnfree = true;
        config.android_sdk.accept_license = true;
        config.permittedInsecurePackages = [ "python3.13-pypdf3-1.0.6" ];
        overlays = builtins.attrValues self.overlays;
      };
    };
}
