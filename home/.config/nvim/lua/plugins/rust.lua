local function has_project_file(filename)
  return vim.fs.root(filename, { 'Cargo.toml', 'rust-project.json' }) ~= nil
end

local standalone_rustc_namespace = vim.api.nvim_create_namespace('standalone-rustc')

local function rustc_severity(level)
  return ({
    error = vim.diagnostic.severity.ERROR,
    warning = vim.diagnostic.severity.WARN,
    note = vim.diagnostic.severity.INFO,
    help = vim.diagnostic.severity.HINT,
  })[level] or vim.diagnostic.severity.INFO
end

local function byte_column(line, character)
  return #vim.fn.strcharpart(line, 0, math.max(character - 1, 0))
end

local function rustc_diagnostics(bufnr, filename, output)
  local diagnostics = {}
  for _, line in ipairs(vim.split(output, '\n', { trimempty = true })) do
    local ok, message = pcall(vim.json.decode, line)
    if ok and message['$message_type'] == 'diagnostic' then
      for _, span in ipairs(message.spans or {}) do
        if span.is_primary and vim.fs.normalize(span.file_name) == filename then
          local source_line = vim.api.nvim_buf_get_lines(bufnr, span.line_start - 1, span.line_start, false)[1] or ''
          local end_source_line = vim.api.nvim_buf_get_lines(bufnr, span.line_end - 1, span.line_end, false)[1] or ''
          table.insert(diagnostics, {
            lnum = span.line_start - 1,
            col = byte_column(source_line, span.column_start),
            end_lnum = span.line_end - 1,
            end_col = byte_column(end_source_line, span.column_end),
            severity = rustc_severity(message.level),
            message = message.message,
            source = 'rustc',
            code = type(message.code) == 'table' and message.code.code or nil,
          })
          break
        end
      end
    end
  end
  return diagnostics
end

local function run_standalone_rustc(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == '' or has_project_file(filename) then
    return
  end

  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
  vim.diagnostic.reset(standalone_rustc_namespace, bufnr)
  vim.system({
    'rustc',
    '--edition=2024',
    '--error-format=json',
    '--emit=metadata',
    '-o',
    '/dev/null',
    filename,
  }, { text = true }, function(result)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_buf_get_changedtick(bufnr) ~= changedtick then
        return
      end
      vim.diagnostic.set(standalone_rustc_namespace, bufnr, rustc_diagnostics(bufnr, filename, result.stderr))
    end)
  end)
end

local function setup_standalone_rustc()
  local group = vim.api.nvim_create_augroup('StandaloneRustcDiagnostics', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*.rs',
    callback = function(args)
      run_standalone_rustc(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = group,
    pattern = '*.rs',
    callback = function(args)
      vim.diagnostic.reset(standalone_rustc_namespace, args.buf)
    end,
  })
end

local function standalone_root_dir(default_root_dir, standalone_files)
  return function(bufnr, on_dir)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    if has_project_file(filename) then
      default_root_dir(bufnr, on_dir)
      return
    end

    local file_dir = vim.fs.dirname(filename)
    standalone_files[file_dir] = filename
    on_dir(file_dir)
  end
end

local function standalone_before_init(default_before_init, standalone_files)
  return function(init_params, config)
    local standalone_file = standalone_files[config.root_dir]
    if standalone_file then
      config.settings['rust-analyzer'].linkedProjects = { standalone_file }
      config.settings['rust-analyzer'].check = {
        enable = false,
      }
    end
    default_before_init(init_params, config)
  end
end

local function standalone_on_attach(default_on_attach)
  return function(client, bufnr)
    if default_on_attach then
      default_on_attach(client, bufnr)
    end

    run_standalone_rustc(bufnr)
  end
end

return {
  {
    'neovim/nvim-lspconfig',
    opts = function(_, opts)
      local default_config = vim.lsp.config.rust_analyzer
      local standalone_files = {}
      setup_standalone_rustc()

      opts.servers = opts.servers or {}
      opts.servers.rust_analyzer = vim.tbl_deep_extend('force', opts.servers.rust_analyzer or {}, {
        -- Use the built-in Neovim LSP client instead of Mason's automatic setup.
        mason = false,
        root_dir = standalone_root_dir(default_config.root_dir, standalone_files),
        before_init = standalone_before_init(default_config.before_init, standalone_files),
        on_attach = standalone_on_attach(default_config.on_attach),
        settings = {
          ['rust-analyzer'] = {
            check = {
              command = 'clippy',
            },
            cargo = {
              allFeatures = true,
            },
          },
        },
      })
    end,
  },
}
