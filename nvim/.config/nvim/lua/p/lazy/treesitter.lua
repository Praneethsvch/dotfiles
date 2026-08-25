return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").install({
			"bash",
			"c",
			"cpp",
			"css",
			"cmake",
			"lua",
			"luadoc",
			"markdown",
			"markdown_inline",
			"devicetree",
			"ini",
			"yaml",
			"toml",
			"json",
			"python",
			"query",
			"vim",
			"vimdoc",
			"dockerfile",
			"gitignore",
			"go",
			"html",
		})

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local ft = vim.bo[args.buf].filetype
				local lang = vim.treesitter.language.get_lang(ft)
				if lang and pcall(vim.treesitter.start, args.buf, lang) then
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
