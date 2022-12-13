{
  description = "Peter's NixOS and Home Manager Configuration";

  inputs =
    {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
      nur.url = "github:nix-community/NUR";

      home-manager.url = "github:nix-community/home-manager/release-22.11";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";

      bashrc.url = "github:pjones/bashrc";
      bashrc.inputs.nixpkgs.follows = "nixpkgs";

      emacsrc.url = "github:pjones/emacsrc";
      emacsrc.inputs.nixpkgs.follows = "nixpkgs";
      emacsrc.inputs.home-manager.follows = "home-manager";

      encryption-utils.url = "github:pjones/encryption-utils";
      encryption-utils.inputs.nixpkgs.follows = "nixpkgs";

      haskellrc.url = "github:pjones/haskellrc";
      haskellrc.inputs.nixpkgs.follows = "nixpkgs";

      hlwmrc.url = "github:pjones/hlwmrc";
      hlwmrc.inputs.nixpkgs.follows = "nixpkgs";

      image-scripts.url = "github:pjones/image-scripts";
      image-scripts.inputs.nixpkgs.follows = "nixpkgs";

      kmonad.url = "github:kmonad/kmonad?dir=nix";

      maintenance-scripts.url = "github:pjones/maintenance-scripts";
      maintenance-scripts.inputs.nixpkgs.follows = "nixpkgs";

      network-scripts.url = "github:pjones/network-scripts";
      network-scripts.inputs.nixpkgs.follows = "nixpkgs";

      oled-display.url = "github:pjones/oled-display";

      plasma-manager.url = "github:pjones/plasma-manager";
      plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
      plasma-manager.inputs.home-manager.follows = "home-manager";

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

      hosts = [
        "elphaba"
        "jekyll"
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
        encryption-utils = inputs.encryption-utils.overlay;
        hlwmrc = inputs.hlwmrc.overlays.default;
        image-scripts = inputs.image-scripts.overlay;
        maintenance-scripts = inputs.maintenance-scripts.overlay;
        network-scripts = inputs.network-scripts.overlay;
        nur = inputs.nur.overlay;
        oled-display = inputs.oled-display.overlay;
        rofirc = inputs.rofirc.overlays.default;
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
              inputs.emacsrc.homeManagerModules.default
              inputs.haskellrc.homeManagerModules.default
              inputs.plasma-manager.homeManagerModules.plasma-manager
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
              inputs.kmonad.nixosModules.default
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
            let
              machine = nixpkgs.lib.nixosSystem {
                inherit system;
                modules = [
                  test/vm.nix
                  module
                ];
              };
            in
            machine.config.system.build.vm;

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
          emacs = inputs.emacsrc.checks.${system}.default;
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
