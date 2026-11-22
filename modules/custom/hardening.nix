{ self, lib, ... }:
{
  # https://wiki.nixos.org/wiki/NixOS_Hardening
  flake.nixosModules.hardening =
    { lib, ... }:
    {
      config = lib.mkMerge [

        ########################################################################
        # Modules:
        {
          boot.blacklistedKernelModules =
            (lib.importJSON ../../support/security/blacklisted-kernel-modules.json).modules;
        }

        ########################################################################
        # Kernel images:
        {
          # Prevents replacing the running kernel image.
          security.protectKernelImage = true;
        }

        ########################################################################
        # Kernel parameters, caching, and memory:
        {
          boot.kernelParams = [
            # Don't merge slabs
            "slab_nomerge"

            # Overwrite free'd pages
            "page_poison=1"

            # Enable page allocator randomization
            "page_alloc.shuffle=1"

            # Disable debugfs
            "debugfs=off"
          ];

          security.forcePageTableIsolation = true;

          # Would love this but it's to strict:
          # environment.memoryAllocator.provider = "graphene-hardened";
        }

        ########################################################################
        # Networking:
        {
          # Hide kptrs even for processes with CAP_SYSLOG
          boot.kernel.sysctl."kernel.kptr_restrict" = "2";

          # Disable bpf() JIT (to eliminate spray attacks)
          boot.kernel.sysctl."net.core.bpf_jit_enable" = false;

          # Disable ftrace debugging
          boot.kernel.sysctl."kernel.ftrace_enabled" = false;

          # Disable io_uring, a large source of security vulnerabilities
          # https://security.googleblog.com/2023/06/learnings-from-kctf-vrps-42-linux.html
          boot.kernel.sysctl."kernel.io_uring_disabled" = 2;

          # Enable strict reverse path filtering (that is, do not attempt to route
          # packets that "obviously" do not belong to the iface's network; dropped
          # packets are logged as martians).
          boot.kernel.sysctl."net.ipv4.conf.all.log_martians" = true;
          boot.kernel.sysctl."net.ipv4.conf.all.rp_filter" = "1";
          boot.kernel.sysctl."net.ipv4.conf.default.log_martians" = true;
          boot.kernel.sysctl."net.ipv4.conf.default.rp_filter" = "1";

          # Ignore broadcast ICMP (mitigate SMURF)
          boot.kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = true;

          # Ignore incoming ICMP redirects (note: default is needed to ensure that the
          # setting is applied to interfaces added after the sysctls are set)
          boot.kernel.sysctl."net.ipv4.conf.all.accept_redirects" = false;
          boot.kernel.sysctl."net.ipv4.conf.all.secure_redirects" = false;
          boot.kernel.sysctl."net.ipv4.conf.default.accept_redirects" = false;
          boot.kernel.sysctl."net.ipv4.conf.default.secure_redirects" = false;
          boot.kernel.sysctl."net.ipv6.conf.all.accept_redirects" = false;
          boot.kernel.sysctl."net.ipv6.conf.default.accept_redirects" = false;

          # Ignore outgoing ICMP redirects (this is ipv4 only)
          boot.kernel.sysctl."net.ipv4.conf.all.send_redirects" = false;
          boot.kernel.sysctl."net.ipv4.conf.default.send_redirects" = false;
        }
      ];
    };

  # Settings to harden things like services.
  flake.lib.hardening = {
    serviceConfig = {
      AmbientCapabilities = "";
      CapabilityBoundingSet = "";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateMounts = true;
      PrivateTmp = true;
      ProcSubset = "pid";
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallErrorNumber = "EPERM";
      SystemCallFilter = [
        "@system-service"
        (lib.concatStringsSep " " [
          "~@clock"
          "@cpu-emulation"
          "@debug"
          "@module"
          "@mount"
          "@obsolete"
          "@privileged"
          "@raw-io"
          "@reboot"
          "@swap"
        ])
      ];
    };
  };
}
