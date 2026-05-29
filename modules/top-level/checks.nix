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
          config = test ../../test/config.nix;
          cron = test ../../test/cron.nix;
          mail-imap = test ../../test/mail/imap.nix;
          mail-fetch = test ../../test/mail/fetch.nix;
          mail-home = test ../../test/mail/home.nix;

          emacs = inputs.emacsrc.checks.${system}.default;
          superkey-greetd = inputs.superkey.checks.${system}.greetd;
        };
    };

  flake.nixosModules.test = moduleWithSystem (
    { ... }:
    { config, ... }:
    let
      user = self.lib.test.user;
    in
    {
      imports = [
        self.nixosModules.tilde
        self.nixosModules.basic
        self.nixosModules.tailscale
        self.nixosModules.www
      ];

      tilde.putInWheel = true;
      users.users.${user.name}.password = user.password;
      security.sudo.wheelNeedsPassword = false;

      home-manager.users.${config.tilde.username} = {
        imports = [
          self.homeModules.basic
        ];
      };
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
