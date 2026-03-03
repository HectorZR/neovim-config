return {
  "wakatime/vim-wakatime",
  lazy = false,
  cond = function()
    return vim.fn.filereadable(vim.fn.expand("~/.wakatime.cfg")) == 1
  end,
}
