return {
  "ibhagwan/fzf-lua",
  cond = function()
    return vim.fn.executable("fzf") == 1
  end,
  opts = {
    files = {
      fd_opts = table.concat({
        "--color=never",
        "--type=f",
        "--hidden",
        "--follow",
        "--exclude=.git",
        "--exclude=node_modules",
        "--exclude=dist",
        "--exclude=build",
        "--exclude=.next",
        "--exclude=.nuxt",
        "--exclude=coverage",
        "--exclude=.cache",
        "--exclude=__pycache__",
        "--exclude=.venv",
        "--exclude=vendor",
      }, " "),
    },
    previewers = {
      builtin = {
        extensions = {
          ["png"] = { "chafa", "--format=symbols", "<file>" },
          ["jpg"] = { "chafa", "--format=symbols", "<file>" },
          ["jpeg"] = { "chafa", "--format=symbols", "<file>" },
          ["gif"] = { "chafa", "--format=symbols", "<file>" },
          ["webp"] = { "chafa", "--format=symbols", "<file>" },
          ["svg"] = { "chafa", "--format=symbols", "<file>" },
          ["ico"] = { "chafa", "--format=symbols", "<file>" },
        },
      },
    },
  },
}
