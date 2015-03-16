--
-- Tools Module.
-- [author] Valeriu Paloş <me@vpalos.com>
--
local tools = {}

--
-- Trim string from both ends.
--
tools.trim = function(text)
  return (text:gsub("^%s*(.-)%s*$", "%1"))
end

--
-- Iterate through string line by line.
--
tools.lines = function(text)
  return text:gmatch("[^\n\r]+")
end

--
-- Limit a given number x between two boundaries.
-- Either min or max can be nil, to fence on one side only.
--
tools.fence = function(x, min, max)
  return (min and x < min and min) or (max and x > max and max) or x
end

--
-- Export.
--
return tools