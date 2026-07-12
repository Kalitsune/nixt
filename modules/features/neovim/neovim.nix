{inputs, ...}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: {
    packages.neovim = inputs.wrapper-modules.wrappers.neovim.wrap {
      inherit pkgs;

      settings.config_directory = ./config;

      runtimePkgs = with pkgs; [
        # Fonts
        nerd-fonts.jetbrains-mono

        # LSP servers
        lua-language-server
        typescript-language-server
        vscode-langservers-extracted # html, css, json
        tailwindcss-language-server
        svelte-language-server
        clang-tools # clangd for C/C++
        jdt-language-server
        tinymist # typst
        bash-language-server
        arduino-language-server
        # kdePackages.qtdeclarative         # qmlls — uncomment when Qt dev needed

        # Formatters
        stylua
        prettier
        typstyle

        # Formatters (cont.)
        alejandra # nix

        # Linters
        eslint

        # typst-preview websocket transport
        websocat
      ];

      specs = {
        # ── Theme ──────────────────────────────────────────────────────────────
        nightfox = {
          data = pkgs.vimPlugins.nightfox-nvim;
          config = ''vim.cmd.colorscheme("carbonfox")'';
        };
        # rosepine = pkgs.vimPlugins.rose-pine;

        # ── Mini ecosystem ─────────────────────────────────────────────────────
        # Replaces: nvchad statusline, vim-surround, nvim-autopairs,
        #           nvim-web-devicons, Comment.nvim, indent-blankline
        mini = {
          data = pkgs.vimPlugins.mini-nvim;
          config = "require('configs.mini')";
        };

        # ── Core UI ────────────────────────────────────────────────────────────
        nui = pkgs.vimPlugins.nui-nvim;
        plenary = pkgs.vimPlugins.plenary-nvim;

        "neo-tree" = {
          data = pkgs.vimPlugins.neo-tree-nvim;
          after = ["mini" "nui" "plenary"];
          config = ''
            require('neo-tree').setup({
              hide_root_node = true,
              filesystem = {
                follow_current_file = { enabled = true },
                bind_to_cwd = true,
                use_libuv_file_watcher = true,
              },
            })
            vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle reveal_force_cwd<cr>', { desc = 'Toggle file tree' })
          '';
        };

        dashboard = {
          data = pkgs.vimPlugins.dashboard-nvim;
          after = ["mini"];
          config = ''require('dashboard').setup({})'';
        };

        # Replaces NvChad's which-key integration
        "which-key" = {
          data = pkgs.vimPlugins.which-key-nvim;
          after = ["mini"];
          config = ''
            require('which-key').setup({ icons = { provider = "mini", group = "" } })
            require('which-key').add({
              { "<leader>d",  group = "Diagnostics", icon = " " },
              { "<leader>df", icon = "󰶯" },

              { "<leader>f",  group = "Format" },
              { "<leader>fo", icon = "󰗈" },

              { "<leader>s",  group = "Search" },
              { "<leader>sf", icon = { cat = "default", name = "file" } },
              { "<leader>sb", icon = "" },

              { "<leader>g",  group = "Version Control", icon = "" },
            })
          '';
        };

        # ── Fuzzy finder (replaces NvChad's telescope setup) ───────────────────
        "fzf-native" = pkgs.vimPlugins.telescope-fzf-native-nvim;

        telescope = {
          data = pkgs.vimPlugins.telescope-nvim;
          after = ["plenary" "fzf-native"];
          config = ''
            require('telescope').setup({})
            require('telescope').load_extension('fzf')
            local t = require('telescope.builtin')
            vim.keymap.set('n', '<leader>sf', t.find_files, { desc = 'Search files' })
            vim.keymap.set('n', '<leader>sg', t.live_grep,  { desc = 'Live grep' })
            vim.keymap.set('n', '<leader>sb', t.buffers,    { desc = 'Search buffers' })
          '';
        };

        # ── Git ────────────────────────────────────────────────────────────────
        gitsigns = {
          data = pkgs.vimPlugins.gitsigns-nvim;
          config = ''require('gitsigns').setup()'';
        };

        diffview = {
          data = pkgs.vimPlugins.diffview-nvim;
          after = ["plenary"];
          config = ''
            require('diffview').setup()
            vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen<cr>', { desc = 'Show git diff' })
          '';
        };

        # ── LSP ────────────────────────────────────────────────────────────────
        lspconfig = {
          data = pkgs.vimPlugins.nvim-lspconfig;
          config = "require('configs.lspconfig')";
        };

        # ── Syntax ─────────────────────────────────────────────────────────────
        "ts-autotag" = {
          data = pkgs.vimPlugins.nvim-ts-autotag;
          config = ''require('nvim-ts-autotag').setup()'';
        };

        treesitter = {
          data = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
          after = ["ts-autotag"];
          config = ''
            vim.api.nvim_create_autocmd('FileType', {
              callback = function() pcall(vim.treesitter.start) end,
            })
          '';
        };

        # ── Completion ─────────────────────────────────────────────────────────
        "blink-cmp" = {
          data = pkgs.vimPlugins.blink-cmp;
          after = ["mini"];
          config = ''
            require('blink.cmp').setup({
              keymap   = { preset = 'enter' },
              sources  = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
              snippets = { preset = 'mini_snippets' },
            })
          '';
        };

        # ── Formatting & linting ───────────────────────────────────────────────
        conform = {
          data = pkgs.vimPlugins.conform-nvim;
          config = "require('conform').setup(require('configs.conform'))";
        };

        "nvim-lint" = {
          data = pkgs.vimPlugins.nvim-lint;
          config = "require('configs.lint')";
        };

        # ── File-type support ──────────────────────────────────────────────────
        "render-markdown" = {
          data = pkgs.vimPlugins.render-markdown-nvim;
          config = ''
            require('render-markdown').setup({ file_types = { 'markdown' } })
          '';
        };

        "typst-preview" = {
          data = pkgs.vimPlugins.typst-preview-nvim;
          config = ''
            require('typst-preview').setup({
              open_cmd = 'google-chrome-stable --new-window "%s"',
            })
          '';
        };

        # ── Tools ──────────────────────────────────────────────────────────────
        wakatime = pkgs.vimPlugins.vim-wakatime;
      };
    };
  };
}
