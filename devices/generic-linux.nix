# This is a home-manager module:
{ ... }:
{
  imports = [
    ../home
  ];

  config = {
    home.username = "pjones";
    home.homeDirectory = "/home/pjones";

    home-manager = {
      backupFileExtension = "backup";
      useUserPackages = true;
    };

    tilde = {
      enable = true;
    };
  };
}
