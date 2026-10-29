local terminal = "com.superlogical.terminal"
local shell = terminal .. ".shell"

local function check(result, err)
  if err ~= nil then
    error(err, 0)
  end
  return result
end

local function term(options)
  return rex.layout.block({ flavor = shell, options = options })
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

-- herdr follows the focused pane's directory for new tabs; Rex starts them in $HOME.
local function cwd_of(process)
  return process and process.foreground and process.foreground.cwd
end

-- Empty: the tab's only pane is a shell with nothing running in it.
local function is_empty(window, block_id, process)
  local blocks = {}
  for _, layer in ipairs(window.layers or {}) do
    for _, block in ipairs(layer.blocks or {}) do
      table.insert(blocks, block)
    end
  end
  if process == nil or process.child == nil then
    return false
  end
  local ancestors = process.ancestors or {}
  return #blocks == 1
    and blocks[1].block_id == block_id
    and blocks[1].flavor == shell
    and #ancestors == 1
    and ancestors[1].pid == process.child.pid
end

rex.action({
  name = "dev_tab",
  title = "Open Dev Tab",
  description = "pi on the left, two shells stacked on the right. Reuses the current tab when it is empty.",
  run = function(ctx)
    local window, block_id, process = focused(ctx)
    local cwd = cwd_of(process)
    local right = rex.layout.vertical(0.85, term({ cwd = cwd }), term({ cwd = cwd }))

    if window ~= nil and is_empty(window, block_id, process) then
      check(rex.session.new_split({
        anchor_id = block_id,
        direction = "horizontal",
        side = "after",
        layout = right,
      }))
      check(rex.block.call(terminal, "write", { block_id = block_id, data = "pi\r" }))
      check(rex.session.set_window_label({ window_id = window.window_id, label = "Dev" }))
      return
    end

    check(rex.session.new_window({
      window_label = "Dev",
      layout = rex.layout.horizontal(0.5, term({ cwd = cwd, initial_input = "pi\n" }), right),
    }))
  end,
})

rex.action({
  name = "nvim_tab",
  title = "Open NeoVim Tab",
  run = function(ctx)
    local _, _, process = focused(ctx)
    check(rex.session.new_window({
      window_label = "NeoVim",
      layout = rex.layout.block({
        flavor = shell,
        label = "NeoVim",
        options = { cwd = cwd_of(process), initial_input = "nvim .\n" },
      }),
    }))
  end,
})

rex.bind("cmd+shift+d", "dev_tab")
rex.bind("cmd+shift+v", "nvim_tab")
