-- Code review workflow: VSCode-style diffs that live-update while an agent works.
-- All review keymaps live under <leader>r.
local function default_branch()
  local ref = vim.fn.systemlist({ "git", "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" })[1]
  if vim.v.shell_error == 0 and ref and ref ~= "" then
    return (ref:gsub("^origin/", ""))
  end
  for _, b in ipairs({ "main", "master" }) do
    vim.fn.system({ "git", "rev-parse", "--verify", "--quiet", b })
    if vim.v.shell_error == 0 then
      return b
    end
  end
  return "HEAD"
end

return {
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    opts = {
      diff = {
        layout = "side-by-side",
        compute_moves = true,
      },
      explorer = {
        view_mode = "tree",
      },
      keymaps = {
        view = {
          -- `gf` jumps from the diff to the real file in the previous tab to edit it
          open_in_prev_tab = "gf",
        },
      },
    },
    keys = {
      { "<leader>rr", "<cmd>CodeDiff<cr>", desc = "Review working changes" },
      {
        "<leader>rb",
        function()
          vim.cmd("CodeDiff " .. default_branch() .. "...")
        end,
        desc = "Review branch vs base",
      },
      { "<leader>rs", "<cmd>CodeDiff --staged<cr>", desc = "Review staged changes" },
      { "<leader>rh", "<cmd>CodeDiff history<cr>", desc = "Review commit history" },
      { "<leader>rH", "<cmd>CodeDiff history %<cr>", desc = "Review file history" },
      {
        "<leader>rp",
        function()
          vim.ui.input({ prompt = "PR number: " }, function(n)
            if n and n:match("^%d+$") then
              vim.cmd("CodeDiff pr " .. n)
            end
          end)
        end,
        desc = "Review pull request",
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = { spec = { { "<leader>r", group = "review", icon = { icon = " ", color = "orange" } } } },
  },
}
