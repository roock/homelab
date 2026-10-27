# Home Manager configuration for user roock, shared by all servers.
{ pkgs, ... }:

let
  # Powerline glyphs (Nerd Font), written as escapes to keep this file ASCII.
  capLeft = builtins.fromJSON ''"\uE0B6"'';
  separator = builtins.fromJSON ''"\uE0B0"'';
  capRight = builtins.fromJSON ''"\uE0B4"'';
in
{
  home.username = "roock";
  home.homeDirectory = "/home/roock";

  home.packages = [
    pkgs.httpie
    pkgs.fortune
  ];

  programs.git = {
    enable = true;
    settings.user.email = "roman.pertl@a1.at";
    settings.user.name = "Roman Pertl";
    ignores = [
      "*~"
      "*.swp"
      ".vscode/"
      "__OLD__/"
      ".envrc"
      # Devenv
      ".devenv*"
      "devenv.nix"
      "devenv.lock"
      "devenv.local.nix"
      "devenv.yaml"
      # direnv
      ".direnv"
      # pre-commit
      ".pre-commit-config.yaml"
      ".env"
    ];
  };

  home.sessionVariables = let editor = "vim";
  in {
    VISUAL = editor;
    EDITOR = editor;
    GIT_EDITOR = editor;
  };

  programs.direnv.enable = true;
  programs.dircolors.enable = true;
  programs.fzf.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # defaultKeymap = "vicmd";
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch";
    };
    history = {
      share = true;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      size = 100000;
    };

    initContent = ''
      # Set up nix paths
      #if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

      eval "$(devenv hook zsh)"

      ## Source local extra (private) settings specific to machine if it exists
      [ -f ~/.zsh.local ] && source ~/.zsh.local
    '';
  };

  programs.zsh.prezto = {
    enable = true;
    pmodules = [
      #"age"
      "environment"
      "terminal"
      "editor"
      "history"
      "directory"
      "spectrum"
      "utility"
      "node"
      #"sops"
      "archive"
      "completion"
      "syntax-highlighting"
      "history-substring-search"
      "autosuggestions"
      "prompt"
    ];
    editor = {
      # Expand ... -> ../.. recursively
      dotExpansion = true;
    };
  };

  programs.starship = {
    enable = true;
    presets = [
      #"pastel-powerline"
      "gruvbox-rainbow"
    ];
    settings = {
      add_newline = false;

      format = builtins.concatStringsSep "" [
        "[${capLeft}](color_orange)"
        "$os"
        "$username"
        "$hostname"
        "[${separator}](bg:color_yellow fg:color_orange)"
        "$directory"
        "[${separator}](fg:color_yellow bg:color_aqua)"
        "$git_branch"
        "$git_status"
        "[${separator}](fg:color_aqua bg:color_blue)"
        "$c"
        "$cpp"
        "$rust"
        "$golang"
        "$nodejs"
        "$bun"
        "$php"
        "$java"
        "$kotlin"
        "$haskell"
        "$python"
        "[${separator}](fg:color_blue bg:color_bg3)"
        "$docker_context"
        "$conda"
        "$pixi"
        "[${separator}](fg:color_bg3 bg:color_bg1)"
        "$time"
        "$cmd_duration"
        "[${capRight} ](fg:color_bg1)"
      ];
      # Make the duration visually fit into the preset's final dark segment.
      cmd_duration = {
        format = "[ $duration ](fg:color_fg0 bg:color_bg1)";
      };
      # Make the hostname visually fit into the preset's orange segment.
      hostname = {
        style = "bg:color_orange fg:color_fg0";
        format = "[$ssh_symbol$hostname ]($style)";
      };
    };
  };

  programs.vim = {
    enable = true;
    settings = {
      # Enable mouse navigation
      mouse = "a";
      # tabs are spaces
      expandtab = true;
      # number of spaces when reindinting
      shiftwidth = 2;
      # number of visual spaces per TAB
      tabstop = 2;
      ignorecase = true;
      smartcase = true;
      # Allow hiding unsaved buffers
      hidden = true;
    };
    plugins = with pkgs.vimPlugins; [
      vim-commentary
      vim-repeat
      vim-surround
    ];
    extraConfig = ''
      set nocompatible              " be iMproved
      :let mapleader = ","

      set splitbelow
      set splitright

      set encoding=utf-8
      set autoindent

      " Indent Settings
      set softtabstop=2       " number of spaces in tab when editing

      " Search Settings
      set incsearch           " search as characters are entered
      set hlsearch            " highlight matches
      " turn off search highlight
      nnoremap <leader><space> :nohlsearch<CR>

      inoremap <C-c> <Esc>

      set t_Co=256            " Use 256 colours always

      " Theme choice, with optimizations for gruvbox
      set termguicolors
      set background=dark

      " Use hybrid line numbers while editing file, and absolute otherwise
      " NOTE: disabled to improve performance
      set number " relativenumber
      " augroup numbertoggle
      "   autocmd!
      "   autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
      "   autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
      " augroup END
    '';
  };

  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
