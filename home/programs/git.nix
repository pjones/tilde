{ pkgs, config, lib, ... }:

{
  config = lib.mkIf config.tilde.enable {
    programs.git = {
      enable = true;

      userName = "Peter Jones";
      userEmail = "pjones@devalot.com";

      signing = {
        key = "204284CB";
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
        "*.gpg diff=gpg"
      ];

      ignores = [
        "/dist/"
        "/dist-newstyle/"
        "/result"
        "/TAGS"
      ];

      extraConfig = {
        core.pager = "less -SRiJMWF";
        color.ui = "auto";
        color.pager = true;
        branch.autoSetupRebase = "always";
        push.default = "simple";
        rerere.enable = true;
        gc.reflogExpire = "1 year";
        gc.rerereResolved = "1 year";
        log.date = "short";
        github.user = "pjones";

        diff."gpg".textconv =
          "${pkgs.gnupg}/bin/gpg2 --no-tty --decrypt --use-agent";

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
