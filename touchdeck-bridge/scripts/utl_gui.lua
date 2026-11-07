-- UTL-Add-on-Teile (Wiki „Add-ons: Fenster“): Abschnitt „TouchDeck“ im Stationsfenster (Station auf
-- einen Platz 1–8 des TouchDeck heften) und Reiter „TouchDeck“ im UTL-Manager (angeheftete Stationen).
-- Aussehen wie bei UTL selbst: Abschnitt = Überschrift + Kasten (wie „Anbieter“), Reiter = Liste mit
-- Kopfzeile und einer hellen Box je Zeile (wie „Alarme“). Die Stile kommen von UTL bzw. flib (UTL hängt
-- von flib ab); fehlt einer, fällt der Bau auf Vanilla-Stile zurück.
-- UTL legt den Platz an und ruft die Bau-Funktionen über unsere Schnittstelle auf; Eingaben behandeln wir
-- selbst (on_gui_checked_state_changed, on_gui_selection_state_changed, on_gui_click).
local Utl = require("scripts.utl")

local UtlGui = {}

local PIN = "tdb_utl_pin"
local SLOT = "tdb_utl_slot"

-- Spalten des Manager-Reiters (Breiten für die Standardgröße des Managers, 880 px)
local COLUMNS = {
  { key = "slot", width = 50 },
  { key = "station", width = 250 },
  { key = "surface", width = 130 },
  { key = "network", width = 130 },
  { key = "trains", width = 130 },
  { key = "action", width = 100 },
}

--- Element mit Stil anlegen; gibt es den Stil nicht (andere UTL-/flib-Version), mit Ersatzstil.
local function add(parent, spec, fallback)
  local ok, element = pcall(parent.add, spec)
  if ok then return element end
  spec.style = fallback
  return parent.add(spec)
end

local function slot_items()
  local items = {}
  for i = 1, Utl.PIN_SLOTS do
    items[i] = { "touchdeck-bridge.utl-slot", i }
  end
  return items
end

--- Erster freier Platz des Teams (sonst 1).
local function free_slot(force_name)
  local used = {}
  for _, p in ipairs(Utl.pinned(force_name)) do used[p.slot] = true end
  for i = 1, Utl.PIN_SLOTS do
    if not used[i] then return i end
  end
  return 1
end

local function surface_caption(index)
  local surface = game.get_surface(index)
  if not surface then return "?" end
  if surface.platform then return surface.platform.name end
  if surface.planet then return surface.planet.prototype.localised_name end
  return surface.localised_name or surface.name
end

-- ---------------------------------------------------------------- Stationsfenster

--- Abschnitt im Stationsfenster (UTL ruft das beim Öffnen und Neuaufbau).
---@param flow LuaGuiElement
---@param unit uint32
---@param player_index uint32
function UtlGui.section(flow, unit, player_index)
  local player = game.get_player(player_index)
  if not (player and flow.valid) then return end
  local slot = Utl.pin_of(unit)
  add(flow, { type = "label", style = "utl_header_label", caption = { "touchdeck-bridge.utl-section" } },
    "caption_label")
  local box = add(flow, { type = "frame", style = "flib_shallow_frame_in_shallow_frame", direction = "vertical" },
    "inside_shallow_frame")
  box.style.padding = 6
  box.style.horizontally_stretchable = true
  local row = box.add({ type = "flow", direction = "horizontal" })
  row.style.vertical_align = "center"
  row.style.horizontal_spacing = 8
  row.add({ type = "checkbox", name = PIN, state = slot ~= nil, caption = { "touchdeck-bridge.utl-pin" },
    tooltip = { "touchdeck-bridge.utl-pin-tooltip" }, tags = { tdb_station = unit } })
  add(row, { type = "empty-widget", style = "flib_horizontal_pusher" }, "draggable_space")
  row.add({ type = "drop-down", name = SLOT, items = slot_items(),
    selected_index = slot or free_slot(player.force.name), tags = { tdb_station = unit } })
end

-- ---------------------------------------------------------------- UTL-Manager

local function cell(row, width, spec)
  local element = row.add(spec)
  element.style.width = width
  return element
end

--- Reiter im UTL-Manager (UTL ruft das beim Wählen des Reiters und bei ⟲).
---@param flow LuaGuiElement
---@param player_index uint32
function UtlGui.tab(flow, player_index)
  local player = game.get_player(player_index)
  if not (player and flow.valid) then return end
  local pinned = Utl.pinned(player.force.name)

  -- Leiste oben: Anzahl und Hinweis (wie die Leisten der UTL-Reiter)
  local bar = flow.add({ type = "flow", direction = "horizontal" })
  bar.style.vertical_align = "center"
  ---@diagnostic disable-next-line: assign-type-mismatch
  bar.add({ type = "label", caption = { "touchdeck-bridge.utl-tab-count", tostring(#pinned), tostring(Utl.PIN_SLOTS) } })
  add(bar, { type = "empty-widget", style = "flib_horizontal_pusher" }, "draggable_space")
  bar.add({ type = "label", caption = { "touchdeck-bridge.utl-tab-hint" } })

  -- Liste: Rahmen, Kopfzeile, Zeilen in hellen Boxen
  local outer = flow.add({ type = "frame", style = "inside_deep_frame", direction = "vertical" })
  outer.style.horizontally_stretchable = true
  outer.style.vertically_stretchable = true
  local header = outer.add({ type = "frame", style = "subheader_frame" })
  header.style.horizontally_stretchable = true
  local header_flow = header.add({ type = "flow", direction = "horizontal" })
  header_flow.style.horizontal_spacing = 8
  header_flow.style.left_padding = 8
  for _, column in ipairs(COLUMNS) do
    cell(header_flow, column.width, { type = "label", style = "subheader_caption_label",
      caption = { "touchdeck-bridge.utl-col-" .. column.key } })
  end
  local scroll = add(outer, { type = "scroll-pane", style = "flib_naked_scroll_pane_no_padding",
    horizontal_scroll_policy = "never" }, "scroll_pane")
  scroll.style.vertically_stretchable = true
  local rows = scroll.add({ type = "flow", direction = "vertical" })
  rows.style.vertical_spacing = 0
  rows.style.padding = 4

  if #pinned == 0 then
    local empty = rows.add({ type = "label", caption = { "touchdeck-bridge.utl-tab-empty" } })
    empty.style.padding = 8
    return
  end
  for _, p in ipairs(pinned) do
    local box = add(rows, { type = "frame", style = "flib_shallow_frame_in_shallow_frame" }, "inside_shallow_frame")
    box.style.horizontally_stretchable = true
    box.style.padding = 4
    local row = box.add({ type = "flow", direction = "horizontal" })
    row.style.vertical_align = "center"
    row.style.horizontal_spacing = 8
    local info = Utl.call("get_station", p.unit)
    local trains = Utl.call("get_trains_at_station", p.unit)
    local here = type(trains) == "table" and type(trains.here) == "table" and #trains.here or 0
    local coming = type(trains) == "table" and type(trains.coming) == "table" and #trains.coming or 0
    cell(row, COLUMNS[1].width, { type = "label", caption = tostring(p.slot) }).style.font = "default-bold"
    -- Name anklickbar: UTLs Manager öffnet dann die Fernsicht auf die Station (wie in seinen Reitern)
    local stop = Utl.stop_of(p.unit)
    local name = cell(row, COLUMNS[2].width, {
      type = "label",
      style = stop and "clickable_label" or "label",
      caption = type(info) == "table" and info.stop_name or "?",
      tooltip = stop and { "touchdeck-bridge.utl-goto" } or nil,
      tags = stop and { utl_mgr = "goto", surface = stop.surface_index, x = stop.position.x, y = stop.position.y } or nil,
    })
    name.style.font = "default-bold"
    cell(row, COLUMNS[3].width, { type = "label", caption = surface_caption(p.surface) })
    cell(row, COLUMNS[4].width, { type = "label", caption = p.network or "–" })
    cell(row, COLUMNS[5].width, { type = "label", caption = { "touchdeck-bridge.utl-trains", tostring(here), tostring(coming) } })
    cell(row, COLUMNS[6].width, { type = "button", caption = { "touchdeck-bridge.utl-unpin" },
      tags = { tdb_unpin = p.unit } })
  end
end

-- ---------------------------------------------------------------- Eingaben

---@param event EventData.on_gui_checked_state_changed
function UtlGui.on_checked(event)
  local element = event.element
  if not (element and element.valid and element.name == PIN) then return end
  local unit = element.tags.tdb_station --[[@as uint32]]
  local row = element.parent
  local dropdown = row and row[SLOT]
  local slot = dropdown and dropdown.selected_index or 1
  Utl.pin(unit, element.state and slot or nil)
end

---@param event EventData.on_gui_selection_state_changed
function UtlGui.on_selected(event)
  local element = event.element
  if not (element and element.valid and element.name == SLOT) then return end
  local checkbox = element.parent and element.parent[PIN]
  if checkbox and checkbox.state then
    Utl.pin(element.tags.tdb_station --[[@as uint32]], element.selected_index)
  end
end

--- Inhalt des Manager-Reiters zu einem Element darin (der Flow, den UTL übergeben hat).
local function tab_root(element)
  local node = element
  for _ = 1, 8 do
    node = node and node.parent
    if node and node.valid and node.type == "flow" and node.children[1] and node.children[2]
      and node.children[2].type == "frame" and node.children[2].style.name == "inside_deep_frame" then
      return node
    end
  end
  return nil
end

---@param event EventData.on_gui_click
function UtlGui.on_click(event)
  local element = event.element
  if not (element and element.valid and element.tags and element.tags.tdb_unpin) then return end
  local root = tab_root(element)
  Utl.pin(element.tags.tdb_unpin --[[@as uint32]], nil)
  if root then
    root.clear()
    UtlGui.tab(root, event.player_index)
  end
end

return UtlGui
