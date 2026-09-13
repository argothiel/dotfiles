do
  local log_file, log_error = io.open(vim.lsp.log.get_filename(), 'w')
  if log_file then
    local _, close_error = log_file:close()
    log_error = close_error
  end
  if log_error then
    vim.notify('Failed to clear the previous LSP log: ' .. log_error, vim.log.levels.WARN)
  end
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require('config.lazy')

-- Enable built-in LSP servers (configs loaded from lsp/*.lua)
vim.lsp.enable('pylsp')

-- Use Neovim's built-in LSP completion (no external completion plugins)

-- vim.lsp.completion feeds the popup through vim.fn.complete(), which runs in
-- CTRL_X_EVAL mode. ins_compl_bs() (insexpand.c) aborts unconditionally in that
-- mode, so <BS>, <C-w> and <C-u> end the completion session for good, and
-- autotrigger only fires on InsertCharPre for trigger characters. Re-request a
-- completion after a deletion so the menu comes back.
local completion_retrigger = (function()
  local pending = false
  local timer = assert(vim.uv.new_timer())
  local group = vim.api.nvim_create_augroup('lsp_completion_retrigger', {})

  local function is_trigger_char(bufnr, char)
    local clients = vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/completion' })
    for _, client in ipairs(clients) do
      local chars = vim.tbl_get(client.server_capabilities, 'completionProvider', 'triggerCharacters')
      if chars and vim.list_contains(chars, char) then
        return true
      end
    end
    return false
  end

  local function retrigger()
    if not vim.api.nvim_get_mode().mode:match('^i') or vim.fn.pumvisible() ~= 0 then
      return
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local char = vim.api.nvim_get_current_line():sub(1, col):sub(-1)
    if char ~= '' and (char:match('[%w_]') or is_trigger_char(bufnr, char)) then
      vim.lsp.completion.get()
    end
  end

  vim.api.nvim_create_autocmd('TextChangedI', {
    group = group,
    callback = function()
      if not pending then
        return
      end
      pending = false
      timer:stop()
      timer:start(60, 0, vim.schedule_wrap(retrigger))
    end,
  })

  vim.api.nvim_create_autocmd('InsertLeave', {
    group = group,
    callback = function()
      pending = false
      timer:stop()
    end,
  })

  return function(key)
    return function()
      pending = true
      return key
    end
  end
end)()

-- 'completeopt' has "noselect", so nothing is preselected. Make <C-y> take the
-- first item in that case instead of doing nothing, while keeping i_CTRL-Y
-- (copy the character above) when no menu is open.
vim.keymap.set('i', '<C-y>', function()
  if vim.fn.pumvisible() == 0 then
    return '<C-y>'
  end
  return vim.fn.complete_info({ 'selected' }).selected == -1 and '<C-n><C-y>' or '<C-y>'
end, { expr = true, desc = 'Accept completion, selecting the first item if none is selected' })

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    vim.bo[args.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
      for _, key in ipairs({ '<BS>', '<C-w>', '<C-u>' }) do
        vim.keymap.set('i', key, completion_retrigger(key), {
          buffer = args.buf,
          expr = true,
          desc = 'Delete, reopening the LSP completion menu',
        })
      end
    end
  end,
})

vim.cmd('colorscheme catppuccin')

-- vim.diagnostic.config({ update_in_insert = true })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "make",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 8
    vim.opt_local.shiftwidth = 8
    vim.opt_local.softtabstop = 0
  end,
})
