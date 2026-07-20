-- icons first so mock is available before neo-tree / dashboard load
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()

require("mini.tabline").setup()
require("mini.statusline").setup()
require("mini.surround").setup()
require("mini.pairs").setup()
require("mini.comment").setup()
require("mini.indentscope").setup()
require("mini.trailspace").setup()
require("mini.splitjoin").setup({ mappings = { toggle = "<leader>co" } })
require("mini.cursorword").setup()

require("mini.notify").setup()
vim.notify = require("mini.notify").make_notify()

local hi = require("mini.hipatterns")
hi.setup({
	highlighters = {
		hex_color = hi.gen_highlighter.hex_color(),
		fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
		hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
		todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
		note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
	},
})

require("mini.snippets").setup({
	snippets = {
		require("mini.snippets").gen_loader.from_lang(),
		require("mini.snippets").gen_loader.from_file(vim.fn.stdpath("config") .. "/snippets/typst.json"),
		require("mini.snippets").gen_loader.from_file(vim.fn.stdpath("config") .. "/snippets/package.json"),
	},
})
