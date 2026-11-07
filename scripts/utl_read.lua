-- Lesen der UTL-Daten für die Ausgabe (utl.json): Zahlen je Fläche, Netze, angeheftete Stationen.
-- Ändert nichts am Spielzustand; der Zwischenspeicher betrifft nur die Ausgabe.
-- Aufbau: require("scripts.utl_read")(Utl, data, call) → read, clear
local MOD = "UTLogistics"
local MINUTE = 3600
local HOUR_MINUTES = 60
local TOP_GOODS = 8
local READ_TICKS = 300           -- Zwischenspeicher für die Ausgabe

return function(Utl, data, call)


local cache = {}   -- [Team] = { tick, value } – nur für die Ausgabe

local function split(key)
  return string.match(tostring(key), "^(%a+)|([^|]+)")
end

local function top_goods(goods)
  local list = {}
  for key, amount in pairs(goods) do
    local kind, name = split(key)
    if kind then list[#list + 1] = { k = kind, n = name, hour = amount } end
  end
  table.sort(list, function(a, b)
    if a.hour ~= b.hour then return a.hour > b.hour end
    return a.n < b.n
  end)
  for i = #list, TOP_GOODS + 1, -1 do
    list[i] = nil
  end
  return list
end

local function new_block()
  return { stations = 0, idle = 0, deliveries = 0, networks = 0, hour = 0, goods = {}, alerts_recent = 0,
    unserved = {}, nets = {} }
end

local NET_FIELDS = { stations = true, idle = true, deliveries = true, hour = true }

--- Wichtigste Waren einer Station (Angebot/Bedarf) als Liste { k, n, amount }.
local function top_amounts(map, count)
  local list = {}
  for key, amount in pairs(type(map) == "table" and map or {}) do
    local kind, name = split(key)
    if kind and type(amount) == "number" and amount ~= 0 then
      list[#list + 1] = { k = kind, n = name, amount = math.abs(amount) }
    end
  end
  table.sort(list, function(a, b)
    if a.amount ~= b.amount then return a.amount > b.amount end
    return a.n < b.n
  end)
  for i = #list, count + 1, -1 do
    list[i] = nil
  end
  return list
end

--- Zahlen des Teams je Fläche und gesamt:
--- { active, version, api, utilization, total, all = Block, surfaces = { Block mit index }, }
---@param force LuaForce
local function read(force)
  if not Utl.available() then
    return { active = false }
  end
  local f = force.name
  local hit = cache[f]
  if hit and game.tick - hit.tick < READ_TICKS then return hit.value end

  local d = data()
  local blocks, all = {}, new_block()
  local function block(s)
    local b = blocks[s]
    if not b then
      b = new_block()
      blocks[s] = b
    end
    return b
  end
  local function add(field, s, n, net)
    local b = block(s)
    b[field] = b[field] + n
    all[field] = all[field] + n
    if net and NET_FIELDS[field] then
      local entry = b.nets[net] or { stations = 0, idle = 0, deliveries = 0, hour = 0 }
      b.nets[net] = entry
      entry[field] = entry[field] + n
    end
  end
  for _, at in pairs(d.stations) do
    if at.f == f then add("stations", at.s, 1, at.n) end
  end
  for _, at in pairs(d.idle) do
    if at.f == f then add("idle", at.s, 1, at.n) end
  end
  for _, at in pairs(d.active) do
    if at.f == f then add("deliveries", at.s, 1, at.n) end
  end
  for id, n in pairs(d.networks) do
    local team, s = string.match(id, "^(.*)|(%d+)$")
    if team == f and n then add("networks", tonumber(s), n) end
  end
  local now = math.floor(game.tick / MINUTE)
  local goods_all, goods_by = {}, {}
  for minute, bucket in pairs(d.minutes) do
    if minute > now - HOUR_MINUTES then
      for id, entry in pairs(bucket) do
        local team, s = string.match(id, "^(.*)|(%d+)$")
        s = tonumber(s)   -- %d+ im Muster: immer eine Zahl
        if team == f and s then
          add("hour", s, entry.count)
          for net, n in pairs(entry.nets or {}) do
            local b = block(s)
            local e = b.nets[net] or { stations = 0, idle = 0, deliveries = 0, hour = 0 }
            b.nets[net] = e
            e.hour = e.hour + n
          end
          goods_by[s] = goods_by[s] or {}
          for key, amount in pairs(entry.goods) do
            goods_by[s][key] = (goods_by[s][key] or 0) + amount
            goods_all[key] = (goods_all[key] or 0) + amount
          end
        end
      end
    end
  end
  for s, goods in pairs(goods_by) do block(s).goods = top_goods(goods) end
  all.goods = top_goods(goods_all)

  for _, a in ipairs(d.alerts[f] or {}) do
    local recent = game.tick - a.tick < 10 * MINUTE
    local short = { tick = a.tick, icon = a.icon, group = a.group }
    if a.surface then
      local b = block(a.surface)
      if recent then b.alerts_recent = b.alerts_recent + 1 end
      b.last_alert = b.last_alert or short
    end
    if recent then all.alerts_recent = all.alerts_recent + 1 end
    all.last_alert = all.last_alert or short
  end

  for _, u in pairs(d.unserved) do
    if u.f == nil or u.f == f then
      local kind, name = split(u.key)
      local entry = { k = kind, n = name, network = u.network, since = u.since, reason = u.reason }
      all.unserved[#all.unserved + 1] = entry
      if u.s then table.insert(block(u.s).unserved, entry) end
    end
  end
  local function oldest_first(list)
    table.sort(list, function(a, b) return (a.since or 0) < (b.since or 0) end)
    for i = #list, 6, -1 do
      list[i] = nil
    end
  end
  oldest_first(all.unserved)

  local surfaces = {}
  for s, b in pairs(blocks) do
    local surface = game.get_surface(s)
    if surface and b.stations > 0 then
      b.index, b.name = s, surface.name
      oldest_first(b.unserved)
      -- Netze als Liste, meiste Stationen zuerst (höchstens 20)
      local nets = {}
      for name, e in pairs(b.nets) do
        e.name = name
        nets[#nets + 1] = e
      end
      table.sort(nets, function(x, y)
        if x.stations ~= y.stations then return x.stations > y.stations end
        return x.name < y.name
      end)
      for i = #nets, 21, -1 do
        nets[i] = nil
      end
      b.nets = nets
      surfaces[#surfaces + 1] = b
    end
  end
  table.sort(surfaces, function(a, b) return a.index < b.index end)
  all.nets = nil

  -- Angeheftete Stationen (Platz 1–8) des Teams mit Zügen, Angebot und Bedarf
  local pins = {}
  for unit, slot in pairs(d.pins) do
    local at = d.stations[unit]
    if at and at.f == f then
      local info = call("get_station", unit)
      local trains = call("get_trains_at_station", unit)
      if type(info) == "table" then
        local roles = {}
        for role, on in pairs(type(info.config) == "table" and type(info.config.roles) == "table" and info.config.roles or {}) do
          if on then roles[#roles + 1] = role end
        end
        table.sort(roles)
        pins[#pins + 1] = {
          slot = slot, unit = unit, name = info.stop_name or "?", surface = at.s,
          network = type(info.config) == "table" and info.config.network or at.n, roles = roles,
          here = type(trains) == "table" and type(trains.here) == "table" and #trains.here or 0,
          coming = type(trains) == "table" and type(trains.coming) == "table" and #trains.coming or 0,
          provide = top_amounts(info.provide, 3), request = top_amounts(info.request, 3),
        }
      end
    end
  end
  table.sort(pins, function(a, b) return a.slot < b.slot end)

  local value = {
    active = true,
    version = script.active_mods[MOD],
    api = call("api_version"),
    utilization = d.utilization,
    total = d.total[f] or 0,
    all = all,
    surfaces = surfaces,
    pins = pins,
  }
  cache[f] = { tick = game.tick, value = value }
  return value
end


  local function clear()
    cache = {}
  end
  return read, clear
end
