{ moduleWithSystem, ... }:
{
  flake.nixosModules.libvirt = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      config = {
        environment.systemPackages = with pkgs; [
          OVMFFull # For EFI booting.
          spice-gtk
          virt-manager
        ];

        virtualisation.libvirtd = {
          enable = true;
          onShutdown = "suspend";
          onBoot = "ignore";

          qemu = {
            swtpm.enable = true;
            vhostUserPackages = [ pkgs.virtiofsd ];
          };
        };

        networking = {
          nat.internalInterfaces = [ "ve-+" ];
          networkmanager.unmanaged = [ "interface-name:ve-*" ];
        };
      };
    }
  );
}
