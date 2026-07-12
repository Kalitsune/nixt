local servers = {
  "html",
  "bashls",
  "cssls",
  "clangd",
  "ts_ls",
  "tailwindcss",
  "svelte",
  "lua_ls",
  "arduino_language_server",
  "rust_analyzer",
  "jdtls",
  "gopls",
  "tinymist",
  "tofu_ls",
  -- "qmlls",  -- uncomment alongside kdePackages.qtdeclarative in runtimePkgs
}

vim.lsp.config("qmlls", { cmd = { "qmlls", "-E" } })
vim.lsp.enable(servers)
