{
  self,
  moduleWithSystem,
  ...
}:

{
  flake.nixosModules.slugworth = moduleWithSystem (
    { ... }:
    { modulesPath, ... }:
    {
      imports =
        with self.nixosModules;
        [
          basic
          fetchmail
          imapd
          single-disk
          tilde
        ]
        ++ [
          (modulesPath + "/profiles/qemu-guest.nix")
        ];

      config = {
        networking.hostName = "slugworth";

        # Hardware:
        boot.initrd.availableKernelModules = [
          "ata_piix"
          "uhci_hcd"
          "virtio_pci"
          "sr_mod"
          "virtio_blk"
        ];

        # Disk configuration:
        tilde.hardware.disks.single = {
          enable = true;
          device = "/dev/vda";
          swap.enable = false;
        };

        zramSwap.enable = true;

        home-manager.users.pjones = {
          imports = with self.homeModules; [
            basic
            syncthing
          ];
        };
      };
    }
  );

  perSystem = self.lib.nixos.checkHost "slugworth";
}
