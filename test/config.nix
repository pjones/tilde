{ pkgs, module }:
let
  user = import ./user.nix;
in
pkgs.nixosTest {
  name = "tilde-config-test";

  nodes = {
    machine = { config, ... }: {
      imports = [
        module
        ../devices/generic-nixos.nix
      ];

      tilde.username = user.name;

      home-manager.users.${config.tilde.username} = { ... }: {
        tilde.programs.emacs.enable = true;
      };
    };
  };

  testScript = ''
    with subtest("Start machines and prepare directories"):
        start_all()
        machine.succeed("mkdir -m 0755 -p ${user.home}/notes/bookmarks")
        machine.succeed("chown ${user.name}:root ${user.home}/notes/bookmarks")

    with subtest("Verify home-manager installed config files"):
        machine.wait_for_unit("home-manager-${user.name}.service")
        machine.succeed("test -L ${user.home}/.config/emacs/init.el")

    with subtest("Verify activation script created some links"):
        machine.succeed("test -L ${user.home}/.cache/emacs/bookmarks")
  '';
}
