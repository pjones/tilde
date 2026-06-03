{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
let
  host = "slugworth";
  system = "x86_64-linux";
in
{
  flake.nixosModules.${host} = moduleWithSystem (
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
        networking.hostName = host;

        # Hardware:
        boot.initrd.availableKernelModules = [
          "ata_piix"
          "uhci_hcd"
          "virtio_pci"
          "sr_mod"
          "virtio_blk"
        ];

        # Boot:
        boot.loader.systemd-boot.enable = true;

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

  flake.nixosConfigurations.${host} = inputs.nixpkgs.lib.nixosSystem {
    modules = self.lib.nixos.hostModules host system;
  };

  flake.checks.${system} = self.lib.nixos.mkCheck { inherit host; };
}
