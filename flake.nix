{
  description = "Peter's NixOS and Home Manager Configuration";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.zst";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nur.url = "github:nix-community/NUR"; # https://nur.nix-community.org/

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-on-droid.url = "github:nix-community/nix-on-droid/release-24.05";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";

    niri-autoselect-portal.url = "git+https://codeberg.org/debugloop/niri-autoselect-portal.git";

    backup-scripts.url = "github:pjones/backup-scripts";
    backup-scripts.inputs.nixpkgs.follows = "nixpkgs";

    bashrc.url = "github:pjones/bashrc";
    bashrc.inputs.nixpkgs.follows = "nixpkgs";

    emacsrc.url = "github:pjones/emacsrc/nixos-26.05";
    emacsrc.inputs.nixpkgs.follows = "nixpkgs";
    emacsrc.inputs.home-manager.follows = "home-manager";

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

    org-clock-dbus.url = "github:pjones/org-clock-dbus";

    tmuxrc.url = "github:pjones/tmuxrc";
    tmuxrc.inputs.nixpkgs.follows = "nixpkgs";

    zshrc.url = "github:pjones/zshrc";
    zshrc.inputs.nixpkgs.follows = "nixpkgs";

    # Anyrun launcher.
    anyrun.url = "github:anyrun-org/anyrun";
    anyrun.inputs.nixpkgs.follows = "nixpkgs";

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
