# https://github.com/t184256/nix-on-droid/
{ self, moduleWithSystem, ... }:
{
  flake.nixOnDroidModules.tilde = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      system.stateVersion = self.lib.state.version;
      environment.etcBackupExtension = ".backup";
      user.shell = "${pkgs.zsh}/bin/zsh";
      #time.timeZone = "America/Phoenix";

      home-manager.config = {
        home.stateVersion = self.lib.state.version;
        imports = with self.homeModules; [
          basic
        ];
      };
    }
  );
}
