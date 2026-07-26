{ moduleWithSystem, ... }:
{
  flake.homeModules.git = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
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
        + lib.concatMapStringsSep "\n" (dir: ''if [ -d "${dir}" ]; then directories+=("${dir}"); fi'') (
          baseStatusDirectories ++ cfg.extraStatusDirectories
        )
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
        extraStatusDirectories = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            List of directory to scan for Git repositories when checking
            global Git status.
          '';
        };
      };

      config = {
        home.packages = [
          mgs
          pkgs.git-annex
          pkgs.mgitstatus
        ];

        # NOTE: Encryption settings are in gnupg.nix.
        programs.git = {
          enable = true;

          attributes = [
            "*.el diff=lisp"
            "*.lisp diff=lisp"
            "*.org diff=org"
          ];

          ignores = [
            "/result"
            "TAGS"
            "/.direnv/"
          ];

          settings = {
            branch.autoSetupRebase = "always";
            branch.sort = "-committerdate";
            color.pager = true;
            color.ui = "auto";
            column.ui = "auto";
            core.pager = "less -SRiJMWF";
            gc.reflogExpire = "1 year";
            gc.rerereResolved = "1 year";
            github.user = "pjones";
            init.defaultBranch = "trunk";
            log.date = "short";
            user.email = "peter@jonesbunch.com";
            user.name = "Peter J. Jones";
            merge.conflictStyle = "diff3";

            alias = {
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

            diff = {
              algorithm = "histogram";
              colorMoved = "plain";
              mnemonicPrefix = true;
              renames = true;

              "lisp".xfuncname = "^\\((def\\S+\\s+\\S+)";
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
      };
    }
  );
}
