---@return number[]
local function bufs()
  local buffers = vim.tbl_filter(function(buf)
    return vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())

  return buffers
end

local function bufname(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":~:.")
end

---@param spec wk.Spec[]
local function add_keys(spec)
  spec = vim.list_slice(spec, 1, 10)
  return spec
end

local function buf()
  local ret = {} ---@type wk.Spec[]
  local current = vim.api.nvim_get_current_buf()

  for i, buffer in ipairs(bufs()) do

    if current == buffer then
      goto continue
    end

    local name = bufname(buffer)
    ret[#ret + 1] = {
      tostring(i),
      function()
        -- vim.api.nvim_set_current_buf(buffer)
        vim.cmd("LualineBuffersJump " .. i)
      end,
      desc = name,
      icon = { cat = "file", name = name },
    }

    ::continue::
  end
  return add_keys(ret)
end
return {
  "folke/which-key.nvim",
  opts = {
    spec = {
      {
        "<leader>b",
        group = "buffer",
        expand = function()
          return buf()
        end,
      },
    },
  },
}
