{ config, lib, pkgs, ... }:

let
  cfg = config.tilde.workstation.kmonad;

  package = pkgs.callPackage ../../pkgs/kmonad.nix { };

  # Per-keyboard options:
  keyboard = { name, ... }: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        example = "laptop-internal";
        description = "Keyboard name.";
      };

      device = lib.mkOption {
        type = lib.types.path;
        example = "/dev/input/by-id/some-dev";
        description = "Path to the keyboard's device file.";
      };

      config = lib.mkOption {
        type = lib.types.lines;
        default = builtins.readFile ../../support/keyboard/us_60.kbd;
        description = ''
          Keyboard configuration excluding the defcfg block.
        '';
      };
    };

    config = {
      name = lib.mkDefault name;
    };
  };

  # Create a complete KMonad configuration file:
  mkCfg = keyboard:
    let defcfg = ''
      (defcfg
        input  (device-file "${keyboard.device}")
        output (uinput-sink "kmonad-${keyboard.name}")

        cmp-seq ralt    ;; Set the compose key to `RightAlt'
        cmp-seq-delay 5 ;; 5ms delay between each compose-key sequence press

        fallthrough true
        allow-cmd false
      )
    '';
    in
    pkgs.writeTextFile {
      name = "kmonad-${keyboard.name}.cfg";
      text = defcfg + "\n" + keyboard.config;
      checkPhase = "${cfg.package}/bin/kmonad -d $out";
    };

  # Build a systemd path config that starts the service below when a
  # keyboard device appears:
  mkPath = keyboard: rec {
    name = "kmonad-${keyboard.name}";
    value = {
      description = "KMonad trigger for ${keyboard.device}";
      wantedBy = [ "default.target" ];
      pathConfig.Unit = "${name}.service";
      pathConfig.PathExists = keyboard.device;
    };
  };

  # Build a systemd service that starts KMonad:
  mkService = keyboard: {
    name = "kmonad-${keyboard.name}";
    value = {
      description = "KMonad for ${keyboard.device}";
      script = "${cfg.package}/bin/kmonad ${mkCfg keyboard}";
      serviceConfig.Restart = "no";
    };
  };
in
{
  options.tilde.workstation.kmonad = {
    enable = lib.mkEnableOption "KMonad: An advanced keyboard manager.";

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      example = "pkgs.haskellPacakges.kmonad";
      description = "The KMonad package to use.";
    };

    keyboards = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule keyboard);
      default = { };
      description = "Keyboard configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.uinput = { };

    services.udev.extraRules = ''
      # KMonad user access to /dev/uinput
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';

    systemd.paths =
      builtins.listToAttrs
        (map mkPath (builtins.attrValues cfg.keyboards));

    systemd.services =
      builtins.listToAttrs
        (map mkService (builtins.attrValues cfg.keyboards));
  };
}
