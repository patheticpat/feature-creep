-- Run at build time via +luafile, after lazy.nvim has installed the plugins
-- on startup. LazyVim then installs the missing treesitter parsers,
-- asynchronously: wait until that stops making progress, retry what is still
-- missing once, then quit. Missing parsers only warn: LazyVim retries them on
-- the next start.
local want = LazyVim.opts("nvim-treesitter").ensure_installed or {}
local ts = require("nvim-treesitter")
local available = {}
for _, lang in ipairs(ts.get_available()) do
  available[lang] = true
end

local function missing()
  local have = {}
  for _, lang in ipairs(ts.get_installed()) do
    have[lang] = true
  end
  return vim.tbl_filter(function(lang)
    return available[lang] and not have[lang]
  end, want)
end

local stall_ms, poll_ms = 60000, 500
local left, idle = #missing(), 0
while left > 0 and idle < stall_ms do
  vim.wait(poll_ms)
  local now = #missing()
  idle = now < left and 0 or idle + poll_ms
  left = now
end

if left > 0 then
  -- Leftovers of a failed attempt make the next one fail too.
  for _, dir in ipairs(vim.fn.glob(vim.fn.stdpath("cache") .. "/tree-sitter-*", false, true)) do
    vim.fn.delete(dir, "rf")
  end
  pcall(function()
    ts.install(missing()):wait(600000)
  end)
end

local still = missing()
if #still > 0 then
  io.stderr:write("[feature-creep] WARNING: treesitter parsers not installed: " .. table.concat(still, ", ") .. "\n")
end
vim.cmd.qall()
