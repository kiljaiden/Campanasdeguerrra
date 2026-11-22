-- ============================================================================
-- Campañas de Guerra - Índices y geometría (se carga tras Data.lua y FrontsGen.lua)
-- ============================================================================
local CdG = CdG

-- ---------------------------------------------------------------------------
-- Índices
-- ---------------------------------------------------------------------------
CdG.NODES = {}          -- [id] = nodo
CdG.BY_MAP = {}         -- [map] = { nodos... }
CdG.FRONT_BY_MAP, CdG.FRONT_BY_KEY = {}, {}

local function AddNode(n)
    CdG.NODES[n.id] = n
    CdG.BY_MAP[n.map] = CdG.BY_MAP[n.map] or {}
    table.insert(CdG.BY_MAP[n.map], n)
    n.r = n.r or CdG.KIND[n.kind].r
    n.time = CdG.KIND[n.kind].time
end

for _, f in ipairs(CdG.FRONTS) do
    CdG.FRONT_BY_MAP[f.map] = f
    CdG.FRONT_BY_KEY[f.key] = f
    f.cont = CdG.ZONES[f.map] and CdG.ZONES[f.map][5] or 0
    f.continent = f.continent or CdG.CONTINENT_MAPS[f.cont] and CdG.CONTINENT_MAPS[f.cont].name or "?"
    f.byKey, f.points, f.caps, f.mines, f.lumbers = {}, {}, {}, {}, {}
    for _, d in ipairs(f.nodes) do
        local n = { key = d[1], name = d[2], x = d[3], y = d[4], kind = d[5] or "point", home = d[6],
            front = f, map = f.map, links = {} }
        n.id = f.key .. "." .. n.key
        f.byKey[n.key] = n
        if n.kind == "point" or n.kind == "capital" then table.insert(f.points, n) end
        if n.kind == "capital" then f.caps[n.home] = n end
        if n.kind == "outpost" then f.outpost = n end
        if n.kind == "mine" then table.insert(f.mines, n) end
        if n.kind == "lumber" then table.insert(f.lumbers, n) end
        AddNode(n)
    end
    for _, l in ipairs(f.links) do
        local a, b = strsplit("-", l)
        a, b = f.byKey[a], f.byKey[b]
        if a and b then table.insert(a.links, b); table.insert(b.links, a) end
    end
    -- centro aproximado del frente (para el mapa del continente)
    local sx, sy = 0, 0
    for _, n in ipairs(f.points) do sx, sy = sx + n.x, sy + n.y end
    f.cx, f.cy = sx / #f.points, sy / #f.points
end

CdG.KEEP_LIST, CdG.OUTPOST_LIST = {}, {}
for _, d in ipairs(CdG.KEEPS) do
    local n = { key = d[1], name = d[2], map = d[3], x = d[4], y = d[5], zone = d[6], kind = "keep", links = {} }
    n.id = "keep." .. n.key
    AddNode(n)
    table.insert(CdG.KEEP_LIST, n)
end
for _, f in ipairs(CdG.FRONTS) do
    if f.outpost then f.outpost.zone = f.name; table.insert(CdG.OUTPOST_LIST, f.outpost) end
end
for _, d in ipairs(CdG.EXTRA_OUTPOSTS) do
    local n = { key = d[1], name = d[2], map = d[3], x = d[4], y = d[5], zone = d[6], kind = "outpost", links = {} }
    n.id = "op." .. n.key
    AddNode(n)
    table.insert(CdG.OUTPOST_LIST, n)
end
CdG.MINE_LIST = {}
for _, f in ipairs(CdG.FRONTS) do
    for _, n in ipairs(f.mines) do n.zone = f.name; table.insert(CdG.MINE_LIST, n) end
end
for _, d in ipairs(CdG.EXTRA_MINES) do
    local n = { key = d[1], name = d[2], map = d[3], x = d[4], y = d[5], zone = d[6], kind = "mine", links = {} }
    n.id = "mine." .. n.key
    AddNode(n)
    table.insert(CdG.MINE_LIST, n)
end

-- ---------------------------------------------------------------------------
-- Geometría
-- ---------------------------------------------------------------------------
function CdG.ZoneYards(map)
    local z = CdG.ZONES[map]
    if not z then return nil end
    return z[1] - z[2], z[3] - z[4]
end

-- distancia en metros entre dos posiciones del mismo mapa de zona
function CdG.Yards(map, x1, y1, x2, y2)
    local w, h = CdG.ZoneYards(map)
    if not w then return 99999 end
    local dx, dy = (x1 - x2) * w, (y1 - y2) * h
    return math.sqrt(dx * dx + dy * dy)
end

-- posición de zona -> posición en el mapa de su continente
function CdG.ToContinent(map, x, y)
    local z = CdG.ZONES[map]
    if not z then return end
    local c = CdG.CONTINENT_MAPS[z[5]]
    local wy = z[1] - x * (z[1] - z[2])
    local wx = z[3] - y * (z[3] - z[4])
    return (c[1] - wy) / (c[1] - c[2]), (c[3] - wx) / (c[3] - c[4]), c.map
end

function CdG.RankFor(glory)
    local idx = 1
    for i, r in ipairs(CdG.RANKS) do if glory >= r[1] then idx = i end end
    return idx, CdG.RANKS[idx][2], CdG.RANKS[idx + 1] and CdG.RANKS[idx + 1][1]
end
