{ pkgs, module }:

let
  testPackage = pkgs.writeShellApplication {
    name = "fetchmail-test-script";
    text = builtins.readFile ./common.sh + builtins.readFile ./fetch.sh;
    runtimeInputs = with pkgs; [
      coreutils
      fetchmail
    ];
  };

  commandFilePublic = pkgs.writeTextFile {
    name = "fetchmailrc";
    text = ''
      poll localhost username example@example.com password password
    '';
  };

  commandFile = "/var/lib/lmtp/fetchmailrc";

  lda = pkgs.writeShellScript "fake-lda" ''
    cat > /var/lib/lmtp/last-msg.txt
  '';
in
pkgs.nixosTest {
  name = "fetchmail-test";

  nodes = {
    machine = { config, lib, ... }: {
      imports = [
        module
        ../../devices/generic-nixos.nix
        (import ./common.nix)
      ];

      environment.systemPackages = [ testPackage ];
      tilde.mail.imap.enable = true;

      tilde.mail.fetch = {
        enable = true;
        accounts.example = {
          inherit commandFile lda;
          localUserName = "not-used";
          moveTo = "Trash";
          extraFetchmailFlags = [ "--nosslcertck" ];
        };
      };

      systemd.services.fetchmail-example.preStart = ''
        install \
          --owner=lmtp --group=lmtp \
          --mode=0400 ${commandFilePublic} ${commandFile}
      '';
    };
  };

  testScript = ''
    with subtest("Start machines"):
        start_all()
        machine.wait_for_unit("multi-user.target")
        machine.wait_for_unit("dovecot2.service")
        machine.wait_for_unit("fetchmail-example.service")

    with subtest("Run test script"):
        machine.succeed("${testPackage}/bin/fetchmail-test-script")
  '';
}
