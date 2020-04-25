{ sources ? import ../nix/sources.nix
, ghc ? "default"
}:

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
    let fn = import package;
        fargs = builtins.functionArgs fn;
    in fn (super.lib.filterAttrs (n: _: fargs ? ${n}) args);

  # My packages have this prefix:
  prefix = "pjones/";

  # Filter out any packages that aren't mine and then load them:
  pjones = with super.lib;
    mapAttrs' (n: v: nameValuePair (removePrefix prefix n) (load v args))
    (filterAttrs (n: _: hasPrefix prefix n) sources);

in
{
  pjones = pjones // {
    # Edify can only build with GHC 8.8.3 right now:
    edify = load sources."pjones/edify" { ghc = "883"; pkgs = super; };
  };
}
