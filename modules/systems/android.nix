# https://github.com/t184256/nix-on-droid/
{ self, moduleWithSystem, ... }:
{
  flake.nixOnDroidModules.tilde = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      system.stateVersion = "25.11";
      environment.etcBackupExtension = ".backup";
      user.shell = "${pkgs.zsh}/bin/zsh";
      #time.timeZone = "America/Phoenix";

      home-manager.config = {
        imports = with self.homeModules; [
          basic
        ];
      };
    }
  );
}
