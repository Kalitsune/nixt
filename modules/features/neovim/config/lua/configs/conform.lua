return {
  formatters_by_ft = {
    lua        = { "stylua" },
    css        = { "prettier" },
    html       = { "prettier" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    typst      = { "typstyle" },
    java       = { "clang-format" },
    c          = { "clang-format" },
    nix        = { "nixfmt" },
  },
  format_on_save = {
    timeout_ms   = 500,
    lsp_fallback = true,
  },
}
