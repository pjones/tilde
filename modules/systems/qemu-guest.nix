{ ... }:
{
  flake.nixosModules.qemu-guest =
    {
      lib,
      config,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        (modulesPath + "/virtualisation/qemu-vm.nix")
      ];

      config = {
        services.qemuGuest.enable = true;
        hardware.graphics.enable = true;

        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
          autoResize = true;
        };

        boot = {
          growPartition = true;
          loader.timeout = 5;
          kernelParams = [
            "console=ttyS0"
            "boot.shell_on_fail"
          ];
        };

        virtualisation = {
          diskSize = lib.mkDefault 8000; # MB
          memorySize = lib.mkDefault 2048; # MB

          forwardPorts = [
            {
              from = "host";
              host.port = 2222;
              guest.port = 22;
            }
          ];

          sharedDirectories.home = {
            source = "$HOME";
            target = "/mnt";
          };

          qemu.options = [
            "-spice port=0,disable-ticketing=on,image-compression=off,gl=on,rendernode=/dev/dri/by-path/pci-0000:c1:00.0-render,seamless-migration=on"
            "-device virtio-vga-gl,max_outputs=1"
            "-display spice-app,gl=on"
          ];

          # These probably won't work:
          libvirtd.enable = lib.mkForce false;
        };

        networking.domain = "example.test";
        security.sudo.wheelNeedsPassword = false;

        #users.users.${config.tilde.user}.password = user.password;

        services.openssh.enable = true;
        services.openssh.settings.PermitRootLogin = lib.mkForce "yes";

        home-manager.users.${config.tilde.username} =
          { ... }:
          {
            tilde.wayland.primaryOutput = lib.mkForce "Virtual-1";
          };
      };
    };
}
