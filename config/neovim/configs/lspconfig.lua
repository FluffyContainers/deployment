local configs = require("plugins.configs.lspconfig")
local on_attach = configs.on_attach
local capabilities = configs.capabilities

--- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/pyright.lua
-- config samples: https://github.com/neovim/nvim-lspconfig/tree/master/lua/lspconfig/server_configurations


local lspconfig = require "lspconfig"


local root_files = {
  'pyproject.toml',
  'setup.py',
  'setup.cfg',
  'requirements.txt',
  'Pipfile',
  'pyrightconfig.json',
  '.git',
}
local util = require 'lspconfig.util'

lspconfig.pyright.setup {
  on_attach = on_attach,
  capabilities = capabilities,

  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_dir = function(fname)
    return util.root_pattern(unpack(root_files))(fname)
  end,
  single_file_support = true,
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
        typeCheckingMode = "basic"
      },
    },
  }
}

lspconfig.bashls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { 'bash-language-server', 'start' },
  settings = {
    bashIde = {
      globPattern = vim.env.GLOB_PATTERN or '*@(.sh|.inc|.bash|.command|.env|.config)',
    },
  },
  filetypes = { 'sh' },
  root_dir = util.find_git_ancestor,
  single_file_support = true,
}

lspconfig.dockerls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { 'docker-langserver', '--stdio' },
  filetypes = { 'dockerfile' },
  root_dir = util.root_pattern 'Dockerfile',
  single_file_support = true
}


lspconfig.docker_compose_language_service.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { 'yaml.docker-compose' },
  root_dir = util.root_pattern 'docker-compose.yaml',
  single_file_support = true
}


lspconfig.yamlls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { 'yaml-language-server', '--stdio' },
  filetypes = { 'yaml', 'yaml.docker-compose' },
  root_dir = util.find_git_ancestor,
  single_file_support = true,
  settings = {
    -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
    redhat = { telemetry = { enabled = false } },
  }
}

lspconfig.jsonls.setup {
  cmd = { 'vscode-json-language-server', '--stdio' },
  filetypes = { 'json', 'jsonc' },
  init_options = {
    provideFormatter = true,
  },
  root_dir = util.find_git_ancestor,
  single_file_support = true
}