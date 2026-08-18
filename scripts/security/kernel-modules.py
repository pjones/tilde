# A script to generate a JSON file of kernel modules used by the
# current system.  Can be used with NixOS like this:
#
# security.lockKernelModules = true;
# boot.kernelModules = (lib.importJSON ./mods.json).modules;

import json
import subprocess


class KernelMods:
    def __init__(self):
        self.modules = []

        proc = subprocess.run(
            ["lsmod"],
            capture_output=True,
            shell=False,
            check=True,
            text=True,
            encoding="utf-8",
        )

        names = []
        counts = dict()

        for index, line in enumerate(proc.stdout.split("\n")):
            if index == 0:
                continue

            cols = line.split()

            if len(cols) >= 3:
                names.append(cols[0])

                if len(cols) >= 4:
                    for dep in cols[3].split(","):
                        if dep in counts:
                            counts[dep] += 1
                        else:
                            counts[dep] = 1

        for name in names:
            if name in counts and counts[name] > 0:
                self.modules.append(name)
        self.modules.sort()

    def print(self):
        print(json.dumps({"modules": self.modules}))


if __name__ == "__main__":
    KernelMods().print()
