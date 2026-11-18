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

--- Current line, or the visual selection's line range (leaves visual mode).
local function range()
  local mode = vim.fn.mode()
  if mode:match("[vV\22]") then
    local a, b = vim.fn.line("v"), vim.fn.line(".")
    vim.api.nvim_feedkeys(vim.keycode("<esc>"), "nx", false)
    return math.min(a, b), math.max(a, b)
  end
  local l = vim.fn.line(".")
  return l, l
end

local function review(fn)
  return function()
    require("user.review")[fn](range())
  end
end

return {
  {
    -- review comments + herdr bridge (local modules, hooked on a plugin that is always loaded)
    "folke/snacks.nvim",
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          require("user.review").setup()
        end,
      })
    end,
    keys = {
      { "<leader>rc", review("add"), mode = { "n", "x" }, desc = "Add review comment" },
      { "<leader>rd", review("delete_at_cursor"), desc = "Delete review comment" },
      {
        "<leader>rl",
        function()
          require("user.review").pick()
        end,
        desc = "List review comments",
      },
      {
        "<leader>as",
        function()
          require("user.review").send()
        end,
        desc = "Send review comments to Claude",
      },
      {
        "<leader>aS",
        function()
          require("user.review").send({ all = true })
        end,
        desc = "Re-send all open comments to Claude",
      },
      { "<leader>aq", review("ask"), mode = { "n", "x" }, desc = "Ask Claude about line/selection" },
      {
        "<leader>at",
        function()
          require("user.octo_inline").send_at_cursor()
        end,
        desc = "Send PR thread on this line to Claude",
      },
      {
        "<leader>aT",
        function()
          require("user.octo_inline").pick()
        end,
        desc = "Choose PR threads to send to Claude",
      },
      {
        "<leader>az",
        function()
          require("user.herdr").toggle_chat()
        end,
        desc = "Toggle Claude chat next to nvim",
      },
      {
        "<leader>aa",
        function()
          require("user.herdr").focus_agent(vim.fn.getcwd())
        end,
        desc = "Open/focus Claude for this worktree (herdr)",
      },
    },
  },
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    opts = {
      diff = {
        layout = "inline",
        compute_moves = true,
      },
      explorer = {
        view_mode = "tree",
        -- nested worktrees show up as untracked dirs; they are not changes to review
        file_filter = {
          ignore = { ".git/**", ".jj/**", ".claude/worktrees/**", ".worktrees/**" },
        },
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
        "<leader>rP",
        function()
          vim.ui.input({ prompt = "PR number: " }, function(n)
            if n and n:match("^%d+$") then
              vim.cmd("CodeDiff pr " .. n)
            end
          end)
        end,
        desc = "Diff pull request (codediff)",
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      -- keys defined on the snacks spec would otherwise show the snacks icon
      local review = { icon = " ", color = "orange" }
      local agent = { icon = "󰚩 ", color = "purple" }
      opts.spec = opts.spec or {}
      vim.list_extend(opts.spec, {
        { "<leader>r", group = "review", icon = review },
        { "<leader>rc", icon = review, mode = { "n", "x" } },
        { "<leader>rd", icon = review },
        { "<leader>rl", icon = review },
        { "<leader>rH", icon = review },
        { "<leader>rp", icon = review },
        { "<leader>rP", icon = review },
        { "<leader>a", group = "agent (claude)", icon = agent },
        { "<leader>aa", icon = agent },
        { "<leader>az", icon = agent },
        { "<leader>as", icon = agent },
        { "<leader>aS", icon = agent },
        { "<leader>aq", icon = agent, mode = { "n", "x" } },
        { "<leader>at", icon = agent },
        { "<leader>aT", icon = agent },
      })
    end,
  },
}
