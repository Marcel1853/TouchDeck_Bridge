-- Kleine Hilfen für mehrere Module.
local Util = {}

--- Teile zu einer LocalisedString zusammensetzen. Höchstens 20 Teile je Ebene → verschachteln.
function Util.concat(parts)
  if #parts <= 19 then
    return { "", table.unpack(parts) }
  end
  local chunks = {}
  for i = 1, #parts, 19 do
    chunks[#chunks + 1] = Util.concat({ table.unpack(parts, i, math.min(i + 18, #parts)) })
  end
  return Util.concat(chunks)
end

return Util
