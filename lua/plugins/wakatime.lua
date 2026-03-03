return {
  "wakatime/vim-wakatime",
  lazy = false,
  cond = function()
    local cfg = vim.fn.expand("~/.wakatime.cfg")
    if vim.fn.filereadable(cfg) == 0 then
      return false
    end
    local content = table.concat(vim.fn.readfile(cfg), "\n")
    return content:find("api_key%s*=") ~= nil
  end,
}
