local settings = require("configuration")
local dashboard_type = {}
local alpha_disabled = { "goolord/alpha-nvim", enabled = false }
local mini_disabled = { "echasnovski/mini.starter", enabled = false }
local startup_disabled = { "startup-nvim/startup.nvim", enabled = false }
local dashboard_disabled = { "glepnir/dashboard-nvim", enabled = false }

local session_restore = 'lua require("persistence").load()'
if settings.session_manager == "possession" then
  session_restore = 'lua require("possession").list()'
end

if settings.enable_alpha then
  alpha_disabled = {}
  dashboard_type = {
    "goolord/alpha-nvim",
    enabled = true,
    event = "VimEnter",
    keys = { { "<leader>ad", "<cmd>Alpha<CR>", "Alpha Dashboard" } },
    config = function()
      require("config.alpha.alpha")
    end
  }
elseif settings.enable_dashboard then
  dashboard_disabled = {}
  dashboard_type = {
    "glepnir/dashboard-nvim",
    enabled = true,
    event = "VimEnter",
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
    keys = { { "<leader>0", "<cmd>Dashboard<CR>", desc = "Dashboard" } },
    config = function()
      require("config.dashboard")
    end,
  }
elseif settings.enable_startup then
  startup_disabled = {}
  dashboard_type = {
    "startup-nvim/startup.nvim",
    enabled = true,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    event = "VimEnter",
    keys = { { "<leader>S", "<cmd>Startup display<CR>", "Startup Dashboard" } },
    config = function()
      vim.g.startup_disable_on_startup = false
      local startup_config = "config.startup." .. settings.startup_theme
      require("startup").setup(require(startup_config))
    end
  }
elseif settings.enable_mini_starter then
  mini_disabled = {}
  dashboard_type = {
    "echasnovski/mini.starter",
    version = "*",
    enabled = true,
    event = "VimEnter",
    opts = function()
      local pad = string.rep(" ", 10)
      local new_section = function(name, action, section)
        return { name = name, action = action, section = pad .. section }
      end

      local starter = require("mini.starter")
      --stylua: ignore
      local config = {
        evaluate_single = true,
        header = function()
          local hour = tonumber(vim.fn.strftime('%H'))
          local part_id = math.floor((hour + 4) / 8) + 1
          local day_part =
            ({ 'evening', 'morning', 'afternoon', 'evening' })[part_id]
          local username = vim.loop.os_get_passwd()['username'] or 'USERNAME'
          return ('  Greetings! Good %s, %s'):format(day_part, username)
        end,
        items = {
          new_section("Find file",          "Telescope find_files", "Telescope"),
          new_section("Recent files",       "Telescope oldfiles",   "Telescope"),
          new_section("Grep text",          "Telescope live_grep",  "Telescope"),
          new_section("Lazyman Menu",       "Lazyman",              "Config"),
          new_section("Configuration Menu", "Lazyconf",             "Config"),
          new_section("Manage Plugins",     "Lazy",                 "Config"),
          new_section("Package Manager",    "Mason",                "Config"),
          new_section("Help Cheatsheet",    "Cheatsheet",           "Config"),
          new_section("Session restore",    session_restore,        "Session"),
          new_section("New file",           "ene | startinsert",    "Built-in"),
          new_section("Quit",               "qa",                   "Built-in"),
        },
        content_hooks = {
          starter.gen_hook.adding_bullet(pad .. "» ", false),
          starter.gen_hook.aligning("center", "center"),
        },
      }
      return config
    end,
    config = function(_, config)
      -- close Lazy and re-open when starter is ready
      if vim.o.filetype == "lazy" then
        vim.cmd.close()
        vim.api.nvim_create_autocmd("User", {
          pattern = "MiniStarterOpened",
          callback = function()
            require("lazy").show()
          end,
        })
      end

      local starter = require("mini.starter")
      starter.setup(config)

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniStarterOpened",
        callback = function()
          local stats = require("lazy").stats()
          starter.config.footer = "⚡ Lazyman Neovim loaded " .. stats.count .. " plugins"
          pcall(starter.refresh)
        end,
      })
    end,
  }
  local mini_group = vim.api.nvim_create_augroup("Startup_mini", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniStarterOpened",
    group = mini_group,
    callback = function()
      require("lualine").hide({
        place = { "statusline", "tabline", "winbar" },
        unhide = false,
      })
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniStarterOpened",
    group = mini_group,
    callback = function()
      vim.cmd([[
        setlocal showtabline=0 | autocmd BufUnload <buffer> set showtabline=2
        setlocal laststatus=0 | autocmd BufUnload <buffer> set laststatus=3
      ]])
    end,
  })
end

return {
  dashboard_type,
  alpha_disabled,
  dashboard_disabled,
  mini_disabled,
  startup_disabled
}
