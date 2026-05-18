{ lib, ... }:
{
  options.flake.nixOnDroidModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "nix-on-droid Modules";
  };

  options.flake.nixOnDroidConfigurations = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "nix-on-droid System Configuration";
  };

  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = "Library functions";
  };
}
