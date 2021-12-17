{
  description = "Peter's NixOS and Home Manager Configuration";

  inputs =
    {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
      nur.url = "github:nix-community/NUR";

      home-manager.url = "github:nix-community/home-manager/release-21.11";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";

      bashrc.url = "github:pjones/bashrc";
      bashrc.inputs.nixpkgs.follows = "nixpkgs";

      emacsrc.url = "github:pjones/emacsrc";
      emacsrc.inputs.nixpkgs.follows = "nixpkgs";
      emacsrc.inputs.home-manager.follows = "home-manager";

      encryption-utils.url = "github:pjones/encryption-utils";
      encryption-utils.inputs.nixpkgs.follows = "nixpkgs";

      hlwmrc.url = "github:pjones/hlwmrc";
      hlwmrc.inputs.nixpkgs.follows = "nixpkgs";

      image-scripts.url = "github:pjones/image-scripts";
      image-scripts.inputs.nixpkgs.follows = "nixpkgs";

      inhibit-screensaver.url = "github:pjones/inhibit-screensaver";

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
        "armv7l-linux"
        "i686-linux"
      ];

      # Function to generate a set based on supported systems:
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Package overlay:
      overlays = {
        bashrc = inputs.bashrc.overlay;
        oled-display = inputs.oled-display.overlay;
        encryption-utils = inputs.encryption-utils.overlay;
        hlwmrc = inputs.hlwmrc.overlay;
        image-scripts = inputs.image-scripts.overlay;
        inhibit-screensaver = inputs.inhibit-screensaver.overlay;
        maintenance-scripts = inputs.maintenance-scripts.overlay;
        network-scripts = inputs.network-scripts.overlay;
        nur = inputs.nur.overlay;
        rofirc = inputs.rofirc.overlay;
        tilde = import ./overlays;
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
      packages.x86_64-linux = {
        demo = self.nixosConfigurations.demo.config.system.build.vm;
        screenshot = self.checks.x86_64-linux.herbstluftwm;
      };

      ##########################################################################
      defaultPackage.x86_64-linux = self.packages.x86_64-linux.screenshot;

      ##########################################################################
      apps.x86_64-linux = {
        # Launch a VM running Pete's configuration:
        demo = {
          type = "app";
          program = "${self.packages.x86_64-linux.demo}/bin/run-tilde-demo-vm";
        };
      };

      ##########################################################################
      # Default app is to run the demo VM:
      defaultApp.x86_64-linux = self.apps.x86_64-linux.demo;

      ##########################################################################
      checks.x86_64-linux =
        let
          pkgs = nixpkgsFor.x86_64-linux;
          module = self.nixosModules.tilde;
          test = path: import path { inherit pkgs module; };

          machine = module:
            let machine = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
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
        };

      ##########################################################################
      devShell = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in
        pkgs.mkShell {
          buildInputs = [
            inputs.home-manager.outputs.defaultPackage.${system}
          ];
        });
    };
}
