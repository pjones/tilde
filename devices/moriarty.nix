# This is a NixOS module:
{ config, lib, pkgs, ... }:
let
  cfg = config.tilde;

in
{
  imports = [
    ./generic-nixos.nix
  ];

  users.users.${cfg.username} = {
    openssh.authorizedKeys.keys = [
      (lib.concatStringsSep " " [
        (lib.concatStringsSep "," [
          "restrict"
          ''from="10.11.12.0/24"''
          ''command="muchsync --server"''
        ])
        "ssh-ed25519"
        "AAAAC3NzaC1lZDI1NTE5AAAAICIvTHd8l++xIvaqdW+4sM72im7Is9aWdcBoyOk9ZJuD"
        "muchsync"
      ])
    ];
  };
}
