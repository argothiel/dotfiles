return {
  -- disable trouble
  { "akinsho/bufferline.nvim", enabled = false },
  { "nvim-mini/mini.pairs", enabled = false },
  { "folke/noice.nvim", enabled = false },
  -- disable snippets
  { "rafamadriz/friendly-snippets", enabled = false },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = { "lsp", "path", "buffer" },
        per_filetype = {
          go = { "lsp" },
        },
      },
    },
  },
}
