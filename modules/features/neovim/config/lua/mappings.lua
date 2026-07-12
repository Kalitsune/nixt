local map = vim.keymap.set

map("n", "<leader>/", "gcc", { remap = true, silent = true, desc = "Toggle comment" })
map("v", "<leader>/", "gc", { remap = true, silent = true, desc = "Toggle comment" })

map("n", "<leader>df", function()
	vim.lsp.buf.code_action({
		filter = function(a)
			return a.isPreferred
		end,
		apply = true,
	})
end, { noremap = true, silent = true, desc = "Fix Diagnostics" })

map("n", "<leader>ds", vim.diagnostic.open_float, { noremap = true, silent = true, desc = "Show Diagnostics" })

map("n", "<Tab>",   "<cmd>bnext<cr>",     { noremap = true, silent = true, desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<cr>", { noremap = true, silent = true, desc = "Prev buffer" })
map("n", "<leader>x", function()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  if #bufs > 1 then
    vim.cmd("bprevious")
  end
  vim.cmd("bdelete #")
end, { noremap = true, silent = true, desc = "Close buffer" })
