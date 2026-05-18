{ pkgs, self }:
let
  user = self.lib.test.user;
in
pkgs.testers.runNixOSTest {
  name = "tilde-config-test";

  nodes = {
    machine =
      { config, ... }:
      {
        imports = [
          self.nixosModules.test
        ];

        home-manager.users.${config.tilde.username} = {
          imports = with self.homeModules; [
            bookmarks
            emacs
          ];
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
