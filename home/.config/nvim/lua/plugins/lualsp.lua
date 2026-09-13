return {
  'neovim/nvim-lspconfig',
  opts = {
    inlay_hints = { enabled = false },
    servers = {
      lua_ls = {
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim'}
            }
          }
        }
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
      clangd = {
        mason = false, -- don't auto-install/manage clangd via Mason
        cmd = require('config.clangd').cmd,
        filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
        root_markers = {
          '.builddir',
          '.clangd',
          '.clang-tidy',
          '.clang-format',
          'configure.ac', -- AutoTools
          'SConstruct', -- SCons
          '.git',
          'compile_commands.json',
          'compile_flags.txt',
          'compile_commands.txt',
        },
        on_exit = require('config.clangd').on_exit,
        capabilities = {
          textDocument = { completion = { completionItem = { snippetSupport = false } } },
        },
      },
    },
  },
}
