return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({
      -- Language servers
      ensure_installed = {
        "eslint",
        "jsonls",
        "lua_ls",
        "tailwindcss",
      },
    })
    require("mason-tool-installer").setup({
      -- Formatters
      ensure_installed = {
        "prettierd",
        "stylua",
      },
    })
  end,
}
