{ lib, pkgs, ... }:
{
  home.packages = [
    pkgs.nano
    pkgs.zellij
    pkgs.curl
    pkgs.yq
    pkgs.jq
    pkgs.openssl
    pkgs.unzip
    pkgs.htop
    pkgs.gitMinimal
    pkgs.mmv
    pkgs.file
    pkgs.dnsutils
    pkgs.doggo
    pkgs.parallel
    pkgs.just
    pkgs.diceware
    pkgs.xh
    pkgs.pv
    pkgs.croc
    pkgs.sd
    pkgs.fd
    pkgs.eza
    pkgs.bat
    pkgs.procs
    pkgs.ripgrep
    pkgs.ruplacer
    pkgs.dust
    pkgs.nh
    pkgs.nixfmt-rfc-style
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      __prompt_git_segment() {
        git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

        local branch
        branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"

        git diff --quiet --ignore-submodules HEAD 2>/dev/null
        local dirty=""
        [ $? -ne 0 ] && dirty="*"

        printf " %s(%s%s)%s" "$C_YLW" "$branch" "$dirty" "$C_RST"
      }

      C_RST='\[\e[0m\]'
      C_GRN='\[\e[32m\]'
      C_BLU='\[\e[34m\]'
      C_RED='\[\e[31m\]'
      C_YLW='\[\e[33m\]'

      PS1='$C_GRN\u@\h$C_RST $C_BLU\w$C_RST$(__prompt_git_segment)\n$C_RED\$$C_RST '
    '';
  };

  programs.git = {
    enable = true;

    package = pkgs.gitMinimal;

    ignores = [
      ".sync"
      ".DS_Store"
      "_research"
      "*~"
      ".#*"
      ".env"
    ];

    settings = {
      user.name = "Torsten Curdt";
      user.email = "tcurdt@vafer.org";

      alias = {
        p = "push";

        r = "pull --rebase";
        rf = "pull --rebase --force";

        st = "status -s";
        sha = "rev-parse --short HEAD";

        ci = "commit -v";
        co = "checkout";

        # go back to the pure branch and remove files that don't belong
        clean = "!git restore . && git clean -fdx";

        a = "add";
        au = "add -u";
        aa = "add --all";

        t = "tag";

        # delete a tag
        td = "!f() { git tag -d $1; git push --delete origin $1; }; f";

        # force a tag
        tf = "!f() { git tag -f $1; git push --force origin HEAD:refs/tags/$1; }; f";

        b = "branch -av";

        # delete a branch
        bd = "branch -D";

        # apply a branch as local changes
        ba = "!f() { git diff --binary HEAD...$1 | git apply; }; f";

        # only show the files changed
        df = "diff --name-only";

        l = "log --graph --decorate --no-merges --pretty=format:'%Cred%h %Cblue%cN %Cgreen%cd%C(yellow)%d%Creset - %s' --date='format:%F %a'";

        # like l, but across all refs/branches with full history
        la = "log --full-history --all --graph --abbrev-commit --pretty=format:'%Cred%h %Cblue%cN %Cgreen%cd%C(yellow)%d%Creset - %s' --date='format:%F %a'";

        # compact log with changed files per commit (name-status), no merges
        lf = "log --graph --decorate --no-merges --oneline --name-status --pretty=format:'%Cred%h %Cblue%cN %Cgreen%cd%C(yellow)%d%Creset - %s %n' --date='format:%F %a'";

        # log with full patch output (-p) and relative dates
        lp = "log --abbrev-commit --date=relative -p";

        # merge a feature branch
        m = "!f() { git merge --squash \"$1\" && git commit && git branch -d \"$1\"; }; f";

        standup = "!f() { git log --since=$1.days --author=tcurdt --pretty=format':%Cgreen%cd:%Creset %s' --date='format:%F %a' --all; }; f";
        standupr = "!f() { git log --reverse --since=$1.days --author=tcurdt --pretty=format':%Cgreen%cd:%Creset %s' --date='format:%F %a' --all; }; f";
        export = "archive -o latest.tar.gz -9 --prefix=latest/";
        setup = "!git init && git add . && git commit -m init";
      };

      github.user = "tcurdt";
      gpg.format = "ssh";
      init.defaultBranch = "main";
      branch.sort = "-committerdate";
      branch.autosetuprebase = "always";
      branch.autosetupmerge = "always";
      push.autosetupremote = true;
      push.default = "current";
      push.followTags = 1;
      remote.origin.tagopt = "--tags";
      remote.origin.prune = true;
      remote.origin.prunetags = true;
      pull.rebase = 1;
      pull.ff-only = 1;
      rerere.enabled = 1;
      rebase.updateRefs = true;
      merge.ff = "only";
      log.oneline = 1;
      gist.private = 1;
      gits.browse = 1;
    };
  };

  programs.bat = {
    enable = true;
    config = {
      color = "never";
      paging = "never";
    };
  };

  programs.lazygit.enable = true;

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    extraConfig = "";
    plugins = [ ];
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  home.shellAliases = {
    cat = "bat --style=plain";
    bat = "bat --style=numbers";
    ll = "eza -la --group --octal-permissions --no-permissions --time-style long-iso";
    ls = "eza";
    g = "git";
    lg = "lazygit";
    tssh = "ssh -A -o UserKnownHostsFile=/dev/null ";
    passphrase = "diceware --no-caps -n 7 -d -";
    p = "pnpm";
    k = "kubectl";
    kall = "kubectl get all -A";
    date_utc = "date -u -Iseconds";
    date_berlin = "TZ=Europe/Berlin date -Iseconds";
    dates = "echo -n 'UTC: ' && date_utc && echo -n 'BER: ' && date_berlin";
    systemtime = "chronyc makestep && chronyc tracking";
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = false;
    nix-direnv.enable = true;
    config = {
      global = {
        load_dotenv = false;
      };
    };
  };

  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.bin"
  ];

  home.sessionVariables = {
    PAGER = "less";
    EDITOR = "nano";
    CLICOLOR = 1;
  };

  home.stateVersion = lib.mkDefault "25.11";
}
