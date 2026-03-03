return {
  "ibhagwan/fzf-lua",
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
  },
}
