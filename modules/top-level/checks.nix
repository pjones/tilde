{
  inputs,
  self,
  moduleWithSystem,
  ...
}:
{
  perSystem =
    { system, pkgs, ... }:
    {
      checks =
        let
          test = path: import path { inherit pkgs self; };
        in
        {
          boot-ssh = test ../../test/boot-ssh.nix;
          config = test ../../test/config.nix;
          cron = test ../../test/cron.nix;
          emacs = inputs.emacsrc.checks.${system}.emacsrc;
          greetd = test ../../test/greetd.nix;
          mail-fetch = test ../../test/mail/fetch.nix;
          mail-home = test ../../test/mail/home.nix;
          mail-imap = test ../../test/mail/imap.nix;
          prometheus = test ../../test/prometheus.nix;
          wireguard = test ../../test/wireguard.nix;

          # niri = test ../../test/niri.nix;
        };
    };

  flake.nixosModules.test-base = moduleWithSystem (
    { ... }:
    { ... }:
    let
      user = self.lib.test.user;
    in
    {
      imports = [
        self.nixosModules.tilde
        self.nixosModules.www
      ];

      tilde.putInWheel = true;
      users.users.${user.name}.password = user.password;
      security.sudo.wheelNeedsPassword = false;

    }
  );

  flake.nixosModules.test = moduleWithSystem (
    { ... }:
    { config, ... }:
    {
      imports = [
        self.nixosModules.test-base
        self.nixosModules.basic
      ];
      home-manager.users.${config.tilde.username} = {
        imports = [
          self.homeModules.basic
        ];
      };
    }
  );

  flake.nixosModules.test-wayland = moduleWithSystem (
    { system, ... }:
    { config, ... }:
    {
      imports = [
        self.nixosModules.test-base
        self.nixosModules.workstation
      ];

      environment.systemPackages = [
        self.packages.${system}.wayland-test-helpers
      ];

      home-manager.users.${config.tilde.username} = {
        tilde.wayland.primaryOutput = "Virtual-1";
      };
    }
  );

  flake.nixosModules.test-autologin = moduleWithSystem (
    { ... }:
    { lib, ... }:
    let
      startCompositor = ''
        export COMPOSITOR_VERIFY_EXIT=1
        niri-session && touch /tmp/compositor-exit-ok
      '';

      startCompositorFromShell = ''
        if [ -z "''${START_COMPOSITOR_FROM_SHELL:-}" ] && [ "$(tty)" = "/dev/tty1" ]; then
          export START_COMPOSITOR_FROM_SHELL=1
          ${startCompositor}
        fi
      '';
    in
    {
      services.greetd.enable = lib.mkForce false;
      services.getty.autologinUser = lib.mkForce "pjones";
      programs.bash.loginShellInit = startCompositorFromShell;
      programs.zsh.loginShellInit = startCompositorFromShell;
    }
  );

  flake.lib.test = {
    user = {
      name = "pjones";
      home = "/home/pjones";
      password = "password";
    };
  };
}
