{ pkgs, config, lib, ... }:

let
  cfg = config.tilde.programs.git;

  baseStatusDirectories = [
    "$HOME/src"
    "$HOME/notes"
    "$HOME/.password-store"
  ];

  mgs = pkgs.writeShellApplication {
    name = "mgs";
    runtimeInputs = [ pkgs.mgitstatus ];
    text = ''
      directories=()
    ''
    + lib.concatMapStringsSep "\n"
      (dir: ''if [ -d "${dir}" ]; then directories+=("${dir}"); fi'')
      (baseStatusDirectories ++ cfg.extraStatusDirectories)
    + "\n"
    + ''
      exec mgitstatus \
        --no-ok \
        --flatten \
        "$@" "''${directories[@]}"
    '';
  };
in
{
  options.tilde.programs.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.tilde.workstation.enable;
      description = "Enable Git configuration.";
    };

    extraStatusDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of directory to scan for Git repositories when checking
        global Git status.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      mgs
      pkgs.git-annex
      pkgs.mgitstatus
    ];

    programs.git = {
      enable = true;

      userName = "Peter J. Jones";
      userEmail = "peter@jonesbunch.com";

      signing = {
        key = config.programs.gpg.settings.default-key;
        signByDefault = true;
      };

      aliases = {
        b = "branch -vv";
        s = "status --short";
        ci = "commit";
        co = "checkout";
        ds = "describe --long --tags --dirty --always";
        lg = "log --pretty=format:'%Cgreen%h%Creset %Cred%cd%Creset %Cblue%ae%Creset %s %d'";
        sb = "submodule";
        sbu = "submodule update --init --recursive";
        sbp = "submodule update --remote --checkout";
        unstage = "reset head --";
      };

      attributes = [
        "*.el diff=lisp"
        "*.gpg diff=gpg"
        "*.lisp diff=lisp"
        "*.org diff=org"
      ];

      ignores = [
        "dist/"
        "dist-newstyle/"
        "/result"
        "TAGS"
        ".direnv/"
      ];

      extraConfig = {
        init.defaultBranch = "trunk";
        core.pager = "less -SRiJMWF";
        color.ui = "auto";
        column.ui = "auto";
        color.pager = true;
        branch.autoSetupRebase = "always";
        branch.sort = "-committerdate";
        gc.reflogExpire = "1 year";
        gc.rerereResolved = "1 year";
        log.date = "short";
        github.user = "pjones";

        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
          renames = true;

          "lisp".xfuncname = "^\\((def\\S+\\s+\\S+)";
          "gpg".textconv = "${pkgs.gnupg}/bin/gpg2 --no-tty --decrypt --use-agent";
          "org".xfuncname = "^\\*+ +(.*)$";
        };

        fetch = {
          all = true;
          prune = true;
          pruneTags = true;
        };

        push = {
          autoSetupRemote = true;
          default = "simple";
          followTags = true;
        };

        rerere = {
          enable = true;
          autoupdate = true;
        };

        url."git@github.com:".pushInsteadOf = "https://github.com/";
      };
    };

    home.activation = {
      remote-obsolete-git-config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        [ -e "$HOME/.gitconfig" ] && rm -f "$HOME/.gitconfig"
        [ -e "$HOME/.gitignore" ] && rm -f "$HOME/.gitignore"
      '';
    };
  };
}
