return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	opts = {
		formatters_by_ft = {
			markdown = { "trim_whitespace", "trim_newlines" },
			-- or a full formatter: { "prettier" } / { "mdformat" }
			["_"] = { "trim_whitespace" }, -- any filetype without its own formatter
		},
		format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
	},
}
