{
  description = "Peter's NixOS and Home Manager Configuration";

  inputs =
    {
      nixpkgs.url = "github:NixOS/nixpkgs/release-22.05";
      nur.url = "github:nix-community/NUR";

      home-manager.url = "github:nix-community/home-manager/master";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";

      bashrc.url = "github:pjones/bashrc";
      bashrc.inputs.nixpkgs.follows = "nixpkgs";

      emacsrc.url = "github:pjones/emacsrc/unstable";
      emacsrc.inputs.nixpkgs.follows = "nixpkgs";
      emacsrc.inputs.home-manager.follows = "home-manager";

      encryption-utils.url = "github:pjones/encryption-utils";
      encryption-utils.inputs.nixpkgs.follows = "nixpkgs";

      haskellrc.url = "github:pjones/haskellrc";
      haskellrc.inputs.nixpkgs.follows = "nixpkgs";

      image-scripts.url = "github:pjones/image-scripts";
      image-scripts.inputs.nixpkgs.follows = "nixpkgs";

      inhibit-screensaver.url = "github:pjones/inhibit-screensaver";

      kmonad.url = "path:pkgs/kmonad";

      maintenance-scripts.url = "github:pjones/maintenance-scripts";
      maintenance-scripts.inputs.nixpkgs.follows = "nixpkgs";

      network-scripts.url = "github:pjones/network-scripts";
      network-scripts.inputs.nixpkgs.follows = "nixpkgs";

      oled-display.url = "github:pjones/oled-display";

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

      hosts = [
        "elphaba"
        "kilgrave"
        "medusa"
        "moriarty"
        "ursula"
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
        image-scripts = inputs.image-scripts.overlay;
        inhibit-screensaver = inputs.inhibit-screensaver.overlay;
        kmonad = inputs.kmonad.overlay;
        maintenance-scripts = inputs.maintenance-scripts.overlay;
        network-scripts = inputs.network-scripts.overlay;
        nur = inputs.nur.overlay;
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
      nixosBootstrapHomeManager = { config, pkgs, ... }: {
        home-manager = {
          backupFileExtension = "backup";
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${config.tilde.username} = { ... }: {
            imports = [
              ./home
              inputs.emacsrc.homeManagerModule
              inputs.haskellrc.homeManagerModules.default
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
        let
          hostFrom = path: { ... }: {
            imports = [
              self.nixosModules.tilde
              path
            ];
          };
          hostModules = builtins.listToAttrs (map
            (host: {
              name = host;
              value = hostFrom ./devices/${host}.nix;
            })
            hosts);
        in
        {
          # Base module:
          tilde = { pkgs, ... }: {
            imports = [
              ./nixos
              { nixpkgs.overlays = builtins.attrValues overlays; }
              home-manager.nixosModules.home-manager
              nixosBootstrapHomeManager
            ];
          };
        } // hostModules;

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
        default = self.nixosConfigurations.demo.config.system.build.vm;
      });

      ##########################################################################
      apps = forLinuxSystems (system: {
        # Launch a VM running Peter's configuration:
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/run-tilde-demo-vm";
        };
      });

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

          hostChecks = builtins.listToAttrs (map
            (host: {
              name = host;
              value = machine self.nixosModules.${host};
            })
            hosts);
        in
        {
          # Tests:
          config = test test/config.nix;
          cron = test test/cron.nix;
          kmonad = test test/kmonad.nix;
          mandb = test test/mandb.nix;
        } // hostChecks);

      ##########################################################################
      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system}; in
        {
          default = pkgs.mkShell {
            NIX_PATH = "nixpkgs=${pkgs.path}";

            buildInputs = [
              inputs.home-manager.outputs.defaultPackage.${system}
              pkgs.neofetch
            ];
          };
        });
    };
}
