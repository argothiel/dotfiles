local M = {}

local cc_dirs = {}
local pending_restarts = {}

local default_cmd = {
  'clangd',
  '--log=verbose',
  '--limit-references=0',
  '--limit-results=0',
  '-j=8',
  '--background-index',
  '--all-scopes-completion',
  -- Wait for the parser instead of falling back to text-based (kind Text)
  -- identifier completion scraped from the buffer while it warms up.
  '--completion-parse=always',
  '--clang-tidy',
  '--header-insertion=never',
  '--pretty',
  '--pch-storage=memory',
  '--malloc-trim',
}

local function get_default_cc_dir(root_dir)
  local compile_commands_dir = os.getenv('BUILDDIR')
  if compile_commands_dir then
    return compile_commands_dir ~= '' and compile_commands_dir or nil
  end

  local build_dir_file = vim.fs.joinpath(root_dir, '.builddir')
  local file, open_error, error_code = io.open(build_dir_file, 'r')
  if not file then
    assert(error_code == 2, open_error)
    return nil
  end

  local line, read_error = file:read('*l')
  assert(file:close())
  assert(line and vim.trim(line) ~= '', read_error or build_dir_file .. ' is empty')
  return vim.trim(line)
end

function M.cmd(dispatchers, config)
  config.cmd_cwd = config.cmd_cwd or config.root_dir or assert(vim.uv.cwd())
  local root_dir = config.root_dir or config.cmd_cwd
  local compile_commands_dir = cc_dirs[root_dir] or get_default_cc_dir(root_dir)
  local cmd = vim.deepcopy(default_cmd)

  if compile_commands_dir then
    table.insert(cmd, '--compile-commands-dir=' .. vim.fs.abspath(compile_commands_dir, { cwd = root_dir }))
  end

  return vim.lsp.rpc.start(cmd, dispatchers, {
    cwd = config.cmd_cwd or config.root_dir,
    env = config.cmd_env,
    detached = config.detached,
  })
end

function M.on_exit(_, _, client_id)
  local client = pending_restarts[client_id]
  if not client then
    return
  end
  pending_restarts[client_id] = nil
  local buffers = vim.tbl_keys(client.attached_buffers)

  -- Wait for exit rather than reusing a client that is still shutting down.
  vim.schedule(function()
    if not vim.lsp.is_enabled('clangd') then
      return
    end
    for _, bufnr in ipairs(buffers) do
      if vim.api.nvim_buf_is_loaded(bufnr) then
        vim.lsp.start(client.config, { bufnr = bufnr })
      end
    end
  end)
end

vim.api.nvim_create_user_command('SetCcDir', function(opts)
  local compile_commands_dir = vim.fs.abspath(opts.fargs[1])
  if vim.fn.isdirectory(compile_commands_dir) == 0 then
    vim.notify('Not a compilation database directory: ' .. compile_commands_dir, vim.log.levels.ERROR)
    return
  end

  local clients = vim.lsp.get_clients({ name = 'clangd', bufnr = 0 })
  local root_dir = clients[1] and (clients[1].root_dir or clients[1].config.cmd_cwd)
    or vim.fs.root(0, vim.lsp.config.clangd.root_markers)
    or assert(vim.uv.cwd())
  cc_dirs[root_dir] = compile_commands_dir

  local restarting = false
  for _, client in ipairs(vim.lsp.get_clients({ name = 'clangd' })) do
    if (client.root_dir or client.config.cmd_cwd) == root_dir then
      restarting = true
      if not pending_restarts[client.id] then
        pending_restarts[client.id] = client
        client:stop()
      end
    end
  end
  if not restarting then
    vim.lsp.enable('clangd')
  end
end, { nargs = 1, complete = 'dir' })

return M
