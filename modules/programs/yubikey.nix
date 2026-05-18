{ moduleWithSystem, ... }:
{
  flake.nixosModules.yubikey = moduleWithSystem (
    { pkgs, ... }:
    { config, ... }:
    {
      config = {
        # Helpful packages:
        users.users.${config.tilde.username}.packages = with pkgs; [
          yubikey-personalization # Library and command line tool to personalize YubiKeys
        ];

        services.udev.extraRules = ''
          ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0111", MODE="0660", GROUP="wheel", SYMLINK+="yubikey"
        '';
      };
    }
  );
}
