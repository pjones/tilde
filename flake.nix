{
  description = "Peter's NixOS and Home Manager Configuration";

  inputs =
    {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      nur.url = "github:nix-community/NUR";

      home-manager.url = "github:nix-community/home-manager/master";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";

      bashrc.url = "github:pjones/bashrc";
      bashrc.inputs.nixpkgs.follows = "nixpkgs";

      emacsrc.url = "github:pjones/emacsrc/pjones/nixos-22.05";
      emacsrc.inputs.nixpkgs.follows = "nixpkgs";
      emacsrc.inputs.home-manager.follows = "home-manager";

      encryption-utils.url = "github:pjones/encryption-utils";
      encryption-utils.inputs.nixpkgs.follows = "nixpkgs";

      hlwmrc.url = "github:pjones/hlwmrc/pjones/nixos-22.05";
      hlwmrc.inputs.nixpkgs.follows = "nixpkgs";

      image-scripts.url = "github:pjones/image-scripts";
      image-scripts.inputs.nixpkgs.follows = "nixpkgs";

      inhibit-screensaver.url = "github:pjones/inhibit-screensaver";

      kmonad.url = "github:kmonad/kmonad?dir=nix";

      maintenance-scripts.url = "github:pjones/maintenance-scripts";
      maintenance-scripts.inputs.nixpkgs.follows = "nixpkgs";

      network-scripts.url = "github:pjones/network-scripts";
      network-scripts.inputs.nixpkgs.follows = "nixpkgs";

      oled-display.url = "github:pjones/oled-display";

      rofirc.url = "github:pjones/rofirc";
      rofirc.inputs.nixpkgs.follows = "nixpkgs";

      tmuxrc.url = "github:pjones/tmuxrc";
      tmuxrc.inputs.nixpkgs.follows = "nixpkgs";

      zshrc.url = "github:pjones/zshrc";
      zshrc.inputs.nixpkgs.follows = "nixpkgs";
    };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"

        # OpenJDK prevents this from working:
        # "armv7l-linux"
      ];

      # Function to generate a set based on supported systems:
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Like `forAllSystems` except just those that are Linux:
      forLinuxSystems = f: builtins.listToAttrs
        (builtins.filter (set: set ? name)
          (builtins.map
            (system:
              let pkgs = nixpkgsFor.${system}; in
              nixpkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
                name = system;
                value = f system;
              })
            supportedSystems));

      # Package overlay:
      overlays = {
        bashrc = inputs.bashrc.overlay;
        oled-display = inputs.oled-display.overlay;
        encryption-utils = inputs.encryption-utils.overlay;
        hlwmrc = inputs.hlwmrc.overlay;
        image-scripts = inputs.image-scripts.overlay;
        inhibit-screensaver = inputs.inhibit-screensaver.overlay;
        kmonad = inputs.kmonad.overlay;
        maintenance-scripts = inputs.maintenance-scripts.overlay;
        network-scripts = inputs.network-scripts.overlay;
        nur = inputs.nur.overlay;
        rofirc = inputs.rofirc.overlay;
        tilde = import pkgs/overlay.nix;
        tmuxrc = inputs.tmuxrc.overlay;
        zshrc = inputs.zshrc.overlay;
      };

      # Attribute set of nixpkgs for each system:
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = builtins.attrValues overlays;
        });

      # A NixOS module that bootstraps the tilde home manager modules:
      nixosBootstrapHomeManager = { config, ... }: {
        home-manager = {
          backupFileExtension = "backup";
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${config.tilde.username} = { ... }: {
            imports = [
              ./home
              inputs.emacsrc.homeManagerModule
            ];
          };
        };
      };
    in
    {
      inherit overlays;

      ##########################################################################
      # NixOS module for importing into your system flake:
      nixosModules =
        let hostFrom = path: { ... }: {
          imports = [
            self.nixosModules.tilde
            path
          ];
        };
        in
        {
          # Base module:
          tilde = { ... }: {
            imports = [
              ./nixos
              { nixpkgs.overlays = builtins.attrValues overlays; }
              home-manager.nixosModules.home-manager
              nixosBootstrapHomeManager
            ];
          };

          # Host modules:
          elphaba = hostFrom devices/elphaba.nix;
          kilgrave = hostFrom devices/kilgrave.nix;
          medusa = hostFrom devices/medusa.nix;
          moriarty = hostFrom devices/moriarty.nix;
          ursula = hostFrom devices/ursula.nix;
        };

      ##########################################################################
      # A generic NixOS configuration that can be used as a demo:
      nixosConfigurations.demo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.tilde
          ./test/demo.nix
        ];
      };

      ##########################################################################
      packages = forLinuxSystems (system: {
        demo = self.nixosConfigurations.demo.config.system.build.vm;
        screenshot = self.checks.${system}.herbstluftwm;
      });

      ##########################################################################
      defaultPackage = forLinuxSystems (system:
        self.packages.${system}.screenshot);

      ##########################################################################
      apps = forLinuxSystems (system: {
        # Launch a VM running Pete's configuration:
        demo = {
          type = "app";
          program = "${self.packages.${system}.demo}/bin/run-tilde-demo-vm";
        };
      });

      ##########################################################################
      # Default app is to run the demo VM:
      defaultApp = forLinuxSystems (system:
        self.apps.${system}.demo);

      ##########################################################################
      checks = forLinuxSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          module = self.nixosModules.tilde;
          test = path: import path { inherit pkgs module; };

          machine = module:
            let machine = nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [
                test/vm.nix
                module
              ];
            };
            in machine.config.system.build.vm;
        in
        {
          # Tests:
          config = test test/config.nix;
          cron = test test/cron.nix;
          herbstluftwm = test test/herbstluftwm.nix;
          kmonad = test test/kmonad.nix;
          mandb = test test/mandb.nix;

          # Virtual Machines:
          elphaba = machine self.nixosModules.elphaba;
          kilgrave = machine self.nixosModules.kilgrave;
          medusa = machine self.nixosModules.medusa;
          moriarty = machine self.nixosModules.moriarty;
          ursula = machine self.nixosModules.ursula;
        });

      ##########################################################################
      devShell = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in
        pkgs.mkShell {
          NIX_PATH = "nixpkgs=${pkgs.path}";

          buildInputs = [
            inputs.home-manager.outputs.defaultPackage.${system}
          ];
        });
    };
}
