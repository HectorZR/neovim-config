return {
  {
    "3rd/image.nvim",
    build = false,
    cond = function()
      local has_ghostty = vim.env.GHOSTTY_RESOURCES_DIR ~= nil
      local has_kitty = vim.env.KITTY_WINDOW_ID ~= nil
      local has_ueberzug = vim.fn.executable("ueberzugpp") == 1
      local has_magick = vim.fn.executable("magick") == 1 or vim.fn.executable("convert") == 1
      return (has_ghostty or has_kitty or has_ueberzug) and has_magick
    end,
    opts = {
      backend = (function()
        if vim.env.GHOSTTY_RESOURCES_DIR or vim.env.KITTY_WINDOW_ID then
          return "kitty"
        end
        return "ueberzugpp"
      end)(),
      processor = "magick_cli",
      max_width = 80,
      max_height = 24,
      max_width_window_percentage = 50,
      max_height_window_percentage = 50,
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = false,
          only_render_image_at_cursor = false,
        },
      },
    },
  },
}
