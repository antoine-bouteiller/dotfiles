-- Labels the tab containing rex.args.block with rex.args.name when that block is
-- the tab's first (top-left) pane.
local view, err = rex.session.view({})
if err ~= nil then
  error(err, 0)
end

local function first_block(node)
  while node and not node.block_id do
    node = node.split and node.split.before
  end
  return node and node.block_id
end

for _, window in ipairs(view.windows or {}) do
  for _, layer in ipairs(window.layers or {}) do
    if layer.kind == "tiled" and first_block(layer.layout) == rex.args.block then
      if window.label ~= rex.args.name then
        rex.session.set_window_label({ window_id = window.window_id, label = rex.args.name })
      end
      return
    end
  end
end
