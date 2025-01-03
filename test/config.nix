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
      users.users.${user.name}.password = user.password;

      home-manager.users.${config.tilde.username} = { ... }: {
        tilde.createBookmarksDir = true;
        tilde.programs.emacs.enable = true;
      };
    };
  };

  testScript = ''
    with subtest("Start machines and prepare directories"):
        start_all()

    with subtest("Verify home-manager installed config files"):
        machine.wait_for_unit("multi-user.target")
        machine.succeed("test -L ${user.home}/.config/emacs/init.el")

    with subtest("Verify activation script created some links"):
        machine.succeed("test -d ${user.home}/notes/bookmarks")
        machine.succeed("test -L ${user.home}/.cache/emacs/bookmarks")
  '';
}
