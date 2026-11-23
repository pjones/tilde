#!/usr/bin/env python

from datetime import datetime
import argparse
import json
import re
import subprocess
import sys


class Generation:
    """
    A single generation.
    """

    def __init__(self, details):
        self.id = details["generation"]
        self.date = datetime.fromisoformat(details["date"])
        self.nixosVersion = details["nixosVersion"]

    def id(self):
        return self.id

    def date_str(self):
        return self.date.date().isoformat()

    def version(self):
        return re.sub(r"^([0-9]+\.[0-9]+).*$", r"\1", self.nixosVersion)

    def cluster_key(self):
        """
        Return the cluster name this generation belongs to.
        """
        return f"{self.date_str()}/{self.version()}"


class Cluster:
    """
    A cluster of generations.  Only the newest generation in the
    cluster should remain after deleting older generations.
    """

    def __init__(self, key):
        self.generations = []
        self.to_delete = []
        self.key = key

    def key(self):
        return self.key

    def append(self, generation):
        self.generations.append(generation)
        self.generations.sort(key=Generation.id, reverse=True)

    def keep(self, count):
        """
        Only keep `count` generations.  The rest should be deleted.
        """
        self.to_delete = []

        for gen in self.generations[count:]:
            self.to_delete.append(gen.id)


class Store:
    def __init__(self):
        self.clusters = dict()

        proc = subprocess.run(
            ["nixos-rebuild", "list-generations", "--json"],
            capture_output=True,
            shell=False,
            check=True,
            text=True,
            encoding="utf-8",
        )

        for record in json.loads(proc.stdout):
            generation = Generation(record)
            key = generation.cluster_key()

            if key in self.clusters:
                self.clusters[key].append(generation)
            else:
                cluster = Cluster(key)
                cluster.append(generation)
                self.clusters[key] = cluster

    def keep(self, count=2):
        """
        Compute which generations need to be deleted.

        Returns the names of the clusters that will be kept.

        The `count` parameter is the number of clusters to keep
        (prevent from deleting).  When there is only a single cluster
        then the `count` newest generations in the cluster will be
        kept.
        """
        names = sorted(self.clusters, reverse=True)
        first_n = names[0:count]

        if len(first_n) == 0:
            sys.exit("ERROR: there are no generations!")
        elif len(first_n) == 1:
            self.clusters[first_n[0]].keep(count)
        else:
            for key, cluster in self.clusters.items():
                if key in first_n:
                    cluster.keep(1)
                else:
                    cluster.keep(0)

        return first_n

    def to_delete(self):
        """
        Return a list of generations that will be deleted.

        NOTE: You must call `keep` first.
        """
        to_delete = []

        for cluster in self.clusters.values():
            to_delete.extend(cluster.to_delete)

        to_delete.sort()
        return to_delete

    def delete(self):
        """
        Delete all generations that have been marked for deletion.

        NOTE: You must call `keep` first.
        """
        gens = self.to_delete()

        if len(gens) == 0:
            return

        cmd = [
            "nix-env",
            "--delete-generations",
            "--profile",
            "/nix/var/nix/profiles/system",
        ]

        cmd.extend(map(str, gens))
        subprocess.run(cmd)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="nixos-generations-delete",
        description="Delete clusters of NixOS system generations",
    )

    parser.add_argument("-d", "--dry-run", action="store_true")
    parser.add_argument("-k", "--keep", type=int, default=2)

    args = parser.parse_args()

    store = Store()
    store.keep(args.keep)

    if args.dry_run:
        to_delete = store.to_delete()

        if len(to_delete) == 0:
            print("DRY RUN: no genreations need to be deleted.")
        else:
            print("DRY RUN: the following generations would be deleted:")
            print("\t- " + "\n\t- ".join(map(str, to_delete)))
    else:
        store.delete()
