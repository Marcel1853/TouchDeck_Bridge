-- Kleines Befehlsfeld: TouchDeck öffnet es per Tastenkürzel, tippt den Befehl und drückt Enter.
local Gui = {}

local FRAME = "touchdeck_bridge_command"
local FIELD = "touchdeck_bridge_command_field"

---@param player LuaPlayer
function Gui.open(player)
  local screen = player.gui.screen
  if screen[FRAME] then
    screen[FRAME].destroy()
  end
  local frame = screen.add({ type = "frame", name = FRAME, caption = { "touchdeck-bridge.command-title" }, direction = "vertical" })
  frame.auto_center = true
  local field = frame.add({ type = "textfield", name = FIELD })
  field.style.width = 420
  field.focus()
  player.opened = frame
end

function Gui.close(player)
  local frame = player.gui.screen[FRAME]
  if frame then
    frame.destroy()
  end
end

--- Text aus dem Feld, wenn das Ereignis zu unserem Feld gehört, sonst nil.
---@param element LuaGuiElement?
function Gui.confirmed_text(element)
  if element and element.valid and element.name == FIELD then
    return element.text
  end
  return nil
end

---@param element LuaGuiElement?
function Gui.is_frame(element)
  return element ~= nil and element.valid and element.name == FRAME
end

return Gui
