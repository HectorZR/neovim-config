-- GitHub PR reviews: comments from other reviewers, shown inline and sendable to Claude.
-- Local changes are reviewed with codediff (see plugins/review.lua).
return {
  "pwntester/octo.nvim",
  -- pinned: user.octo_inline wraps octo internals. Re-test inline comments before moving this.
  commit = "0ddca04c02aab8ba18d2072f9b855f3806adad54",
  cmd = "Octo",
  event = { { event = "BufReadCmd", pattern = "octo://*" } },
  dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim", "nvim-mini/mini.icons" },
  opts = {
    picker = "snacks",
    enable_builtin = true,
    -- the comment text is drawn inline by user.octo_inline
    reviews = { show_virtual_text = false },
  },
  config = function(_, opts)
    vim.treesitter.language.register("markdown", "octo")
    require("octo").setup(opts)
    require("user.octo_inline").setup()
  end,
  keys = {
    {
      "<leader>rp",
      function()
        vim.ui.input({ prompt = "PR number (empty: current branch): " }, function(number)
          if number == nil then
            return
          end
          require("octo")
          require("user.octo_inline").open(vim.trim(number))
        end)
      end,
      desc = "Review PR comments (Octo)",
    },
  },
}
