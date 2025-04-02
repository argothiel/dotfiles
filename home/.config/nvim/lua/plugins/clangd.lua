local util = require('lspconfig.util')
local cc_flag = '--compile-commands-dir='

local function get_default_cc_dir(root_dir)
  assert(root_dir == nil or type(root_dir) == 'string')

  -- Try to read from the BUILDDIR env variable
  local compile_commands_dir = os.getenv('BUILDDIR')
  if compile_commands_dir then
    return compile_commands_dir ~= '' and compile_commands_dir or nil
  end

  -- Try to read from .builddir file
  local build_dir_file = root_dir and vim.fs.joinpath(root_dir, '.builddir') or '.builddir'
  local file = io.open(build_dir_file, 'r')
  if not file then
    return nil
  end
  compile_commands_dir = file:read('*l') -- Read the first line
  file:close()

  return compile_commands_dir
end

local function update_cc_dir_flag(cmd_table, compile_commands_dir)
  assert(type(cmd_table) == 'table')
  assert(type(compile_commands_dir) == 'string')

  -- Look for an existing compile-commands-dir parameter and update it
  for i, param in ipairs(cmd_table) do
    -- If param starts with flag
    if param:sub(1, #cc_flag) == cc_flag then
      cmd_table[i] = cc_flag .. compile_commands_dir
      return
    end
  end
  table.insert(cmd_table, cc_flag .. compile_commands_dir)
end

local function set_compile_commands_dir(opts)
  local clangd = require('lspconfig.configs')['clangd']
  local cmd_table = clangd.cmd

  update_cc_dir_flag(cmd_table, opts.args)
  vim.cmd('LspRestart')
end

-- TODO: Switch to neoconf.nvim
vim.api.nvim_create_user_command('SetCcDir', set_compile_commands_dir, { nargs = 1, complete = 'dir' })

return {
  'neovim/nvim-lspconfig',
  opts = {
    inlay_hints = { enabled = false },
    servers = {
      clangd = {
        cmd = {
          'clangd',
          '--log=verbose',
          '--limit-references=0',
          '--limit-results=0',
          '-j=8',
          '--background-index',
          '--all-scopes-completion',
          '--clang-tidy',
          '--header-insertion=never',
          '--pretty',
          '--pch-storage=memory',
          '--malloc-trim',
        },
        root_dir = function(fname)
          return util.root_pattern(
            '.builddir',
            '.clangd',
            '.clang-tidy',
            '.clang-format',
            'configure.ac', -- AutoTools
            'SConstruct' -- SCons
          )(fname) or util.root_pattern('.git')(fname) or util.root_pattern(
            'compile_commands.json',
            'compile_commands.txt'
          )(fname)
        end,
        on_new_config = function(new_config, new_root_dir)
          local compile_commands_dir = get_default_cc_dir(new_root_dir)
          if compile_commands_dir then
            update_cc_dir_flag(new_config.cmd, compile_commands_dir)
          end
        end,
        capabilities = {
          textDocument = { completion = { completionItem = { snippetSupport = false } } },
        },
      },
      pylsp = {
        settings = {
          pylsp = {
            plugins = {
              pycodestyle = {
                maxLineLength = 100,
              },
            },
          },
        },
      },
    },
  },
}
