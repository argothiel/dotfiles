-- tree-sitter CLI is installed via Cargo (~/.cargo/bin/tree-sitter).
-- Ensure ~/.cargo/bin is in nvim's PATH so tree-sitter is always found,
-- preventing Mason from auto-installing an incompatible prebuilt binary.
local cargo_bin = vim.fn.expand("$HOME/.cargo/bin")
if vim.fn.isdirectory(cargo_bin) == 1 and not vim.env.PATH:find(cargo_bin, 1, true) then
  vim.env.PATH = cargo_bin .. ":" .. vim.env.PATH
end

return {}
