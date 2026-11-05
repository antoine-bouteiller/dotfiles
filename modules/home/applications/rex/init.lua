local terminal = "com.superlogical.terminal"
local shell = terminal .. ".shell"

local function check(result, err)
  if err ~= nil then
    error(err, 0)
  end
  return result
end

-- The focused pane of the active tab, its tab, and its processes.
-- ctx.block_id is absent when the action runs from the CLI.
local function focused(ctx)
  local view = check(rex.session.view({}))
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == view.active_window_id then
      local block_id = ctx.block_id or window.focused_block_id
      local process = block_id and rex.block.call(terminal, "process", { block_id = block_id })
      return window, block_id, process
    end
  end
end

-- Rex starts new tabs in $HOME; these follow the focused pane's directory instead.
local function cwd_of(process)
  return process and process.foreground and process.foreground.cwd
end

-- Opens a program over the focused tab; the layer closes when the program exits.
local function float(name, title, label, command)
  rex.action({
    name = name,
    title = title,
    run = function(ctx)
      local window, _, process = focused(ctx)
      check(rex.session.new_layer({
        window_id = window and window.window_id,
        bounds = { 0.05, 0.05, 0.9, 0.9 },
        focus = true,
        layout = rex.layout.block({
          flavor = shell,
          label = label,
          options = { cwd = cwd_of(process), command = command },
        }),
      }))
    end,
  })
end

float("nvim_float", "Open NeoVim", "NeoVim", { "nvim", "." })
float("git_float", "Open Lazygit", "Git", { "lazygit" })

rex.bind("cmd+shift+v", "nvim_float")
rex.bind("cmd+shift+g", "git_float")
