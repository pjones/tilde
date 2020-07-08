{ sources ? import ../nix/sources.nix, ghc ? "default" }:

# Arguments to the overlay function:
self: super:
let
  # Arguments to pass to derivations:
  args = {
    inherit ghc;
    pkgs = super;
  };

  # Load a package and call its function with any arguments that it
  # requests from the `args' set above.
  load = package: args:
    let
      fn = import package;
      fargs = builtins.functionArgs fn;
    in
    fn (super.lib.filterAttrs (n: _: fargs ? ${n}) args);

  # My packages have this prefix:
  prefix = "pjones/";

  # Filter out any packages that aren't mine and then load them:
  pjones = with super.lib;
    mapAttrs' (n: v: nameValuePair (removePrefix prefix n) (load v args))
      (filterAttrs (n: _: hasPrefix prefix n) sources);

in
{
  inherit pjones;

  # Use the latest version of Neuron:
  haskellPackages = super.haskellPackages.override (orig: {
    overrides = super.lib.composeExtensions (orig.overrides or (_: _: { }))
      (_: _: { neuron = import sources.neuron; });
  });

  # Use a more recent version of vimb:
  vimb = super.wrapFirefox
    (super.vimb-unwrapped.overrideAttrs (_: {
      version = sources.vimb.branch;
      src = sources.vimb;
    }))
    { };

  # NixOps is currently broken:
  # https://github.com/NixOS/nixops/issues/1216
  nixops = (super.callPackage "${sources.nixops}/release.nix" {
    p = _: [
      (super.callPackage "${sources.nixops-libvirtd}/release.nix" { })
    ];
  }).build.${super.system};
}
