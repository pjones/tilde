import json


class Gen:
    def __init__(self, host: str, config: str, load_key=False):
        """Create a new Gen object.

        Parameters:

          - `host`: The name of the host we are generating a configuration for.
          - `config`: A string containing the JSON configuration.
        """
        self.private_key = None
        self.load_key = load_key
        self.config = json.loads(config)
        self.interface = self.config["name"]
        self.peers = self.config["peers"]
        self.host_peer = None
        self.primary_router = None
        self.only_router_peers = False
        self.keep_empty_peers = True

        for peer in self.peers:
            if peer["name"] == host:
                self.host_peer = peer
                break

        for peer in self.peers:
            if peer["type"] == "router":
                self.primary_router = peer
                break

        if self.host_peer is None:
            raise RuntimeError(f"{host} is not one of the configured peers!")

        if self.primary_router is None:
            raise RuntimeError("configuration does not include any routers!")

    def peer_ip(self, peer):
        """Return the IP address of the given peer."""
        return f"{self.config['prefix']}.{peer['octet']}"

    def peer_allowed_ips(self, peer):
        """Return a comma-separated list of allowed IPs for this peer."""
        ips = []

        if peer["type"] == "router":
            ips.append(f"{self.config['prefix']}.0/24")
        elif self.host_peer["hostname"] is not None or peer["hostname"] is not None:
            ips.append(f"{self.peer_ip(peer)}/32")

        ips.extend(peer["networks"])
        return ", ".join(ips)

    def dns_servers(self):
        """Return a comma-separated list of DNS servers."""
        if self.config["dnsFromRouter"] and self.host_peer["type"] != "router":
            if self.primary_router["nameservers"] is not None:
                return ", ".join(self.primary_router["nameservers"])
            else:
                return self.peer_ip(self.primary_router)
        else:
            return ""

    def write_interface(self, io, dns):
        """Write the interface section of a WireGuard configuration"""
        io.writelines(
            [
                "[Interface]\n",
                f"ListenPort = {self.config['port']}\n",
                f"Address = {self.peer_ip(self.host_peer)}/24\n",
            ]
        )

        if len(dns) > 0:
            io.write(f"DNS = {dns}\n")

        if self.private_key is not None:
            io.write(f"PrivateKey = {self.private_key}\n")
        elif self.load_key and self.config["privateKeyFile"]:
            keyFile = self.config["privateKeyFile"]
            io.write(f"PostUp = wg set {self.interface} private-key <(cat {keyFile})\n")

    def write_primary(self, io):
        """Write the configuration file for the primary network."""
        self.write_interface(io, self.dns_servers())

        for peer in self.peers:
            if peer["name"] == self.host_peer["name"]:
                continue

            if self.only_router_peers and peer["type"] != "router":
                continue

            allowed = self.peer_allowed_ips(peer)
            if len(allowed) == 0 and not self.keep_empty_peers:
                continue

            io.writelines(
                [
                    "\n[Peer]\n",
                    f"PublicKey = {peer['key']}\n",
                ]
            )

            if len(allowed) > 0:
                io.write(f"AllowedIPs = {allowed}\n")

            if (
                self.host_peer["type"] == "leaf"
                and self.host_peer["hostname"] is None
                and peer["type"] == "router"
            ):
                io.write("PersistentKeepalive = 25\n")

            if "hostname" in peer and peer["hostname"] is not None:
                io.write(f"Endpoint = {peer['hostname']}:{self.config['port']}\n")

    def write_exit(self, io, peer_name):
        """Write a configuration file for sending all traffic to the given exit node"""
        peer = None

        for cfg in self.peers:
            if cfg["name"] == peer_name:
                peer = cfg
                break

        if peer is None:
            raise RuntimeError(f"no peer named {peer_name}")

        if peer["hostname"] is None:
            raise RuntimeError(f"exit node {peer_name} does not have a hostname")

        dns = []

        if peer["nameservers"] is not None:
            dns = peer["nameservers"]
        else:
            dns.append(self.peer_ip(peer))

        self.write_interface(io, ", ".join(dns))
        io.writelines(
            [
                "\n[Peer]\n",
                f"PublicKey = {peer['key']}\n",
                "AllowedIPs = 0.0.0.0/0, ::/0\n"
                f"Endpoint = {peer['hostname']}:{self.config['port']}\n",
            ]
        )


if __name__ == "__main__":
    # https://docs.python.org/3/library/argparse.html
    import argparse
    import sys
    from pathlib import Path

    parser = argparse.ArgumentParser(
        prog="wg-gen",
        description="Generate a WireGuard configuration file.",
    )

    parser.add_argument(
        "-H", "--host", help="The host to generate a config for", metavar="NAME"
    )

    parser.add_argument(
        "-p",
        "--read-private-key",
        help="Read the private key from STDIN",
        action="store_true",
    )

    parser.add_argument(
        "-k",
        "--load-key",
        help="Use a PostUp section to load a private key file",
        action="store_true",
    )

    parser.add_argument(
        "-e", "--exit", help="Route all traffic through the given node", metavar="NAME"
    )

    parser.add_argument(
        "-n", "--name", help="Overwrite the interface name", metavar="NAME"
    )

    parser.add_argument(
        "-a",
        "--all",
        help="Generate all configuration files and write them to disk",
        action="store_true",
    )

    parser.add_argument(
        "-r",
        "--router-only-peers",
        help="Only add peers that are routers",
        action="store_true",
    )

    parser.add_argument(
        "-R",
        "--remove-empty-peers",
        help="Don't generate peers that don't have allowed IP addresses",
        action="store_true",
    )

    parser.add_argument("file", help="JSON configuration file")

    args = parser.parse_args()
    input = Path(args.file)
    generator = Gen(args.host, input.read_text(), load_key=args.load_key)

    generator.only_router_peers = args.router_only_peers
    generator.keep_empty_peers = not args.remove_empty_peers

    if args.name is not None:
        generator.interface = args.name

    if args.read_private_key:
        generator.private_key = sys.stdin.read().strip()

    if args.all:
        name = generator.host_peer["name"]

        with open(f"{name}-{generator.interface}.conf", mode="w") as f:
            generator.write_primary(io=f)

        for peer in generator.peers:
            if peer["name"] != args.host and (
                peer["type"] == "router" or peer["type"] == "exit"
            ):
                with open(f"{name}-{peer['name']}.conf", mode="w") as f:
                    generator.write_exit(io=f, peer_name=peer["name"])
    else:
        if args.exit is not None:
            generator.write_exit(io=sys.stdout, peer_name=args.exit)
        else:
            generator.write_primary(io=sys.stdout)
