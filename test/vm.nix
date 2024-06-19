{ lib, config, pkgs, modulesPath, ... }:

let
  user = import ./user.nix;
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  config = {
    system.stateVersion = "22.11";
    services.qemuGuest.enable = true;

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

      forwardPorts = [{
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }];

      sharedDirectories.home = {
        source = "$HOME";
        target = "/mnt";
      };

      qemu.options = [
        "-vga none"
        "-device virtio-gpu-pci"
      ];

      # These probably won't work:
      libvirtd.enable = lib.mkForce false;
      docker.enable = lib.mkForce false;
    };

    networking.domain = "devalot.com";
    security.sudo.wheelNeedsPassword = false;
    users.users.${user.name}.password = user.password;

    services.openssh.enable = true;
    services.openssh.settings.PermitRootLogin = "yes";

    tilde.username = user.name;
  };
}
