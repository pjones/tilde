let sources = import ../nix/sources.nix;
in
{ pkgs ? import sources.nixpkgs { }
}:
{
  config = import ./config.nix { inherit pkgs sources; };
  cron = import ./cron.nix { inherit pkgs sources; };
  herbstluftwm = import ./herbstluftwm.nix { inherit pkgs sources; };
  kmonad = import ./kmonad.nix { inherit pkgs sources; };
  mandb = import ./mandb.nix { inherit pkgs sources; };
}
