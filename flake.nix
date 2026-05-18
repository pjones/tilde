{
  description = "Peter's NixOS and Home Manager Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nur.url = "github:nix-community/NUR"; # https://nur.nix-community.org/

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-on-droid.url = "github:nix-community/nix-on-droid/release-24.05";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";

    bashrc.url = "github:pjones/bashrc";
    bashrc.inputs.nixpkgs.follows = "nixpkgs";

    emacsrc.url = "github:pjones/emacsrc/nixos-25.11";
    emacsrc.inputs.nixpkgs.follows = "nixpkgs";
    emacsrc.inputs.home-manager.follows = "home-manager";

    superkey.url = "github:pjones/superkey/nixos-25.11";
    superkey.inputs.nixpkgs.follows = "nixpkgs";
    superkey.inputs.home-manager.follows = "home-manager";
    superkey.inputs.emacsrc.follows = "emacsrc";

    encryption-utils.url = "github:pjones/encryption-utils";
    encryption-utils.inputs.nixpkgs.follows = "nixpkgs";

    image-scripts.url = "github:pjones/image-scripts";
    image-scripts.inputs.nixpkgs.follows = "nixpkgs";

    maintenance-scripts.url = "github:pjones/maintenance-scripts";
    maintenance-scripts.inputs.nixpkgs.follows = "nixpkgs";

    mediarc.url = "github:pjones/mediarc";
    mediarc.inputs.nixpkgs.follows = "nixpkgs";

    network-scripts.url = "github:pjones/network-scripts";
    network-scripts.inputs.nixpkgs.follows = "nixpkgs";

    tmuxrc.url = "github:pjones/tmuxrc";
    tmuxrc.inputs.nixpkgs.follows = "nixpkgs";

    zshrc.url = "github:pjones/zshrc";
    zshrc.inputs.nixpkgs.follows = "nixpkgs";

    # For packages I'm building directly:
    firefox-csshacks = {
      url = "github:MrOtherGuy/firefox-csshacks";
      flake = false;
    };

    peaclock = {
      url = "github:pjones/peaclock/pjones/hours";
      flake = false;
    };

    tridactyl_emacs_config = {
      url = "github:jumper047/tridactyl_emacs_config/5674d6bb38abbe639dd8caaf3d81f33fc06f59fd";
      flake = false;
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
