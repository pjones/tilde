{ pkgs, self }:

let
  keys = {
    public_enemy.pri = "YBTgy5486lUH8iMlzcOh8Lok0Ag84eQwXLStxuTenng=";
    public_enemy.pub = "6rP2e5pL+yLAvjK50W988MKFesoH54C8pS9NhqlX5SE=";

    depeche_mode.pri = "IKxheBRJSuktL4qbS9+/AYOU1fBhkoky4gmVyWk2w2A=";
    depeche_mode.pub = "o7Jtahy0yGkCevJc7NSNJkTIocST/gK8ZDIr7pokLno=";

    nirvana.pri = "KIga9UolEKtW7vv7jc0k8A414FFS8IPyhKEOvc3B+F0=";
    nirvana.pub = "G4G+790exEFRtL1UkhqqFrPWKHEZY6rZrFa/W5I4mwQ=";

    fever_ray.pri = "cCQ+MLiypTeziTE7pRn13Q5wfKV6Q/nE4reR7bCkvX0=";
    fever_ray.pub = "xWJVhnyKsiUk548zycSL+YNVCbRJXASJQQOgX0Gf0zs=";
  };

  ips = {
    public_enemy = "192.168.0.1";
    depeche_mode = "192.168.0.2";
    nirvana = "192.168.0.3";
    fever_ray = "192.168.0.4";
  };

  peers = [
    {
      name = "public_enemy";
      octet = 1;
      type = "router";
      key = keys.public_enemy.pub;
      dnsName = ips.public_enemy;
    }

    {
      name = "depeche_mode";
      octet = 2;
      type = "exit";
      key = keys.depeche_mode.pub;
      dnsName = ips.depeche_mode;
    }

    {
      name = "nirvana";
      octet = 3;
      type = "leaf";
      key = keys.nirvana.pub;
    }

    {
      name = "fever_ray";
      octet = 4;
      type = "leaf";
      key = keys.fever_ray.pub;
    }
  ];

  extraConfig = {
    public_enemy = { ... }: {
      imports = [ self.nixosModules.adguardhome ];
    };

    depeche_mode = { };
    nirvana = { };

    fever_ray = { ... }: {
      imports = [ self.nixosModules.prometheus-node ];
    };
  };

  prometheusURL = "http://fever_ray.private.freerangebits.com:${toString self.lib.services.prometheus-node}/metrics";
in
pkgs.testers.nixosTest {
  name = "tilde-wireguard-test";

  nodes = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = { pkgs, ... }: {
        imports = [
          self.nixosModules.test
          self.nixosModules.wireguard
          extraConfig.${name}
        ];

        networking.domain = "freerangebits.com";
        networking.hostName = name;
        networking.useDHCP = false;
        networking.nat.externalInterface = "eth1";

        networking.interfaces.eth1 = {
          ipv4.addresses = [
            {
              address = ips.${name};
              prefixLength = 24;
            }
          ];
        };

        tilde.programs.wireguard = {
          inherit peers;
          privateKeyFile =
            let
              file = pkgs.writeTextFile {
                name = "wg-private-key";
                text = keys.${name}.pri;
              };
            in
            "${file}";
        };
      };
    }) (builtins.attrNames ips)
  );

  testScript = ''
    peers = [public_enemy, depeche_mode, nirvana]

    start_all()

    for peer in peers:
      peer.wait_for_unit("wg-quick-wg0.service")

    nirvana.succeed("ping -c1 10.11.12.1")
    nirvana.succeed("ping -c1 10.11.12.2")
    nirvana.succeed("ping -c1 10.11.12.4")
    nirvana.succeed("ping -c1 public_enemy.private.freerangebits.com")
    nirvana.succeed("ping -c1 depeche_mode.private.freerangebits.com")

    nirvana.succeed("host fever_ray | grep --fixed-strings 10.11.12.4")
    nirvana.succeed("host fever_ray.private.freerangebits.com | grep --fixed-strings 10.11.12.4")

    depeche_mode.succeed("ping -c1 10.11.12.1")
    depeche_mode.succeed("ping -c1 10.11.12.3")
    depeche_mode.succeed("ping -c1 public_enemy.private.freerangebits.com")
    depeche_mode.succeed("ping -c1 nirvana.private.freerangebits.com")

    public_enemy.succeed("ping -c1 10.11.12.2")
    public_enemy.succeed("ping -c1 10.11.12.3")

    nirvana.succeed("curl --verbose ${prometheusURL} | grep 'nodename=\"feverray\"'")
  '';
}
