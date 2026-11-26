{ moduleWithSystem, ... }:
{
  flake.nixosModules.eduvpn = moduleWithSystem (
    { pkgs-unstable, ... }:
    { ... }:
    {
      networking.firewall.trustedInterfaces = [ "eduVPN" ];
      networking.firewall.checkReversePath = "loose"; # :(
      environment.systemPackages = [ pkgs-unstable.eduvpn-client ];
    }
  );

}
