local map = vim.keymap.set

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function() MiniTrailspace.trim() end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "UIEnter", "OptionSet" }, {
  callback = function(args)
    local function check()
      vim.b.minitrailspace_disable = not vim.bo.modifiable or vim.bo.readonly
    end
    if args.event == "UIEnter" then vim.schedule(check) else check() end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern  = { "dashboard" },
  callback = function() vim.b.minitrailspace_disable = true end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  pattern  = { "*.typ" },
  callback = function(event)
    map("n", "<leader>oo", ":TypstPreviewToggle<cr>",     { buffer = event.buf, desc = "Typst: Open Preview" })
    map("n", "<leader>sc", ":TypstPreviewSyncCursor<cr>", { buffer = event.buf, desc = "Typst: Sync Cursor" })
  end,
})
