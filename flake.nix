{
  description = "Peter's NixOS and Home Manager Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nur.url = "github:nix-community/NUR"; # https://nur.nix-community.org/

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    bashrc.url = "github:pjones/bashrc";
    bashrc.inputs.nixpkgs.follows = "nixpkgs";

    desktop-scripts.url = "github:pjones/desktop-scripts";
    desktop-scripts.inputs.nixpkgs.follows = "nixpkgs";

    emacsrc.url = "github:pjones/emacsrc/nixos-24.05";
    emacsrc.inputs.nixpkgs.follows = "nixpkgs";
    emacsrc.inputs.home-manager.follows = "home-manager";
    emacsrc.inputs.desktop-scripts.follows = "desktop-scripts";

    superkey.url = "github:pjones/superkey";
    superkey.inputs.nixpkgs.follows = "nixpkgs";
    superkey.inputs.home-manager.follows = "home-manager";
    superkey.inputs.emacsrc.follows = "emacsrc";
    superkey.inputs.desktop-scripts.follows = "desktop-scripts";

    encryption-utils.url = "github:pjones/encryption-utils";
    encryption-utils.inputs.nixpkgs.follows = "nixpkgs";

    haskellrc.url = "github:pjones/haskellrc";
    haskellrc.inputs.nixpkgs.follows = "nixpkgs";

    image-scripts.url = "github:pjones/image-scripts";
    image-scripts.inputs.nixpkgs.follows = "nixpkgs";

    kmonad.url = "github:kmonad/kmonad?dir=nix";

    maintenance-scripts.url = "github:pjones/maintenance-scripts";
    maintenance-scripts.inputs.nixpkgs.follows = "nixpkgs";

    mediarc.url = "github:pjones/mediarc";
    mediarc.inputs.nixpkgs.follows = "nixpkgs";

    network-scripts.url = "github:pjones/network-scripts";
    network-scripts.inputs.nixpkgs.follows = "nixpkgs";

    oled-display.url = "github:pjones/oled-display";

    tmuxrc.url = "github:pjones/tmuxrc";
    tmuxrc.inputs.nixpkgs.follows = "nixpkgs";

    zshrc.url = "github:pjones/zshrc";
    zshrc.inputs.nixpkgs.follows = "nixpkgs";

    # For packages I'm building directly:
    firefox-csshacks = {
      url = "github:MrOtherGuy/firefox-csshacks";
      flake = false;
    };

    tridactyl_emacs_config = {
      url = "github:jumper047/tridactyl_emacs_config/5674d6bb38abbe639dd8caaf3d81f33fc06f59fd";
      flake = false;
    };
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
        "kilgrave"
        "sid"
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
        desktop-scripts = self.inputs.desktop-scripts.overlays.desktop-scripts;
        encryption-utils = inputs.encryption-utils.overlay;
        image-scripts = inputs.image-scripts.overlays.default;
        maintenance-scripts = inputs.maintenance-scripts.overlay;
        mediarc = inputs.mediarc.overlays.mediarc;
        network-scripts = inputs.network-scripts.overlay;
        nur = inputs.nur.overlay;
        oled-display = inputs.oled-display.overlay;
        superkey = self.inputs.superkey.overlays.superkey;
        tilde = import pkgs/overlay.nix { inherit inputs; };
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
              inputs.superkey.homeManagerModules.default
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
              (import path { inherit self; })
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
              home-manager.nixosModules.home-manager
              nixosBootstrapHomeManager
              inputs.kmonad.nixosModules.default
              inputs.superkey.nixosModules.default
            ];
          };
        } // hostModules;

      ##########################################################################
      # A generic NixOS configuration that can be used as a demo:
      nixosConfigurations = {
        demo = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            { nixpkgs.pkgs = nixpkgsFor.x86_64-linux; }
            self.nixosModules.tilde
            self.inputs.superkey.nixosModules.autologin
            self.inputs.superkey.nixosModules.qemu-sway
            ./test/demo.nix
          ];
        };
      };

      ##########################################################################
      packages = forLinuxSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          default = self.nixosConfigurations.demo.config.system.build.vm;

          screenshot = import test/screenshot.nix {
            inherit self pkgs;
            module = self.nixosModules.tilde;
          };
        } // self.overlays.tilde pkgs pkgs);

      ##########################################################################
      apps = forLinuxSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          # Launch a VM running Peter's configuration:
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/run-tilde-demo-vm";
          };

          # Run a VM then take a screenshot and store it locally:
          screenshot =
            let
              script = pkgs.writeShellScript "screenshot" ''
                cp --force \
                  ${self.packages.${system}.screenshot}/screen.png \
                  support/screenshot.png
              '';
            in
            {
              type = "app";
              program = "${script}";
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
                  { nixpkgs.pkgs = nixpkgsFor.${system}; }
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
          superkey-sway = inputs.superkey.checks.${system}.sway;
          superkey-greetd = inputs.superkey.checks.${system}.greetd;
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
              pkgs.nixpkgs-fmt
            ];
          };
        });
    };
}
