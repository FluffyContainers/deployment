local plugins = {
    "nvim-treesitter/nvim-treesitter",
     opts = {
      highlight = {
          enable = true,
          use_languagetree = true,
      },
      indent = { enable = true },
      ensure_installed = { "python", "bash", "dockerfile", "json", "xml", "yaml" },
      auto_install = true,
    },
    {  -- To install plugins, execute :MasonInstallAll
      "williamboman/mason.nvim",
      opts = {
         ensure_installed = {
           "pyright",
           "lua-language-server",
           "bash-language-server",
           "shellcheck",
           "dockerfile-language-server",
           "docker-compose-language-service",
           "yaml-language-server",
           "json-lsp"
         },
       },
     },
    {
      "neovim/nvim-lspconfig",
      config = function()
        require "plugins.configs.lspconfig"
        require "custom.configs.lspconfig"
      end,
    },
  }
  
return plugins