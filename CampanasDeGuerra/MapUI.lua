-- ============================================================================
-- Campañas de Guerra - Mapa del mundo, minimapa y HUD de captura
-- ============================================================================
local CdG = CdG
local C, rgba = CdG.C, CdG.rgba
local MEDIA = CdG.MEDIA

local MIN_D = { point = 34, capital = 54, keep = 56, outpost = 30, mine = 30, lumber = 30 }
local ICON = { point = "banner", capital = "keep", keep = "keep", outpost = "tower", mine = "mine", lumber = "lumber" }

local function db() return CdG.db end

local function NodeColor(n)
    if n.kind == "mine" then return C.mine end
    if n.kind == "lumber" then return C.lumber end
    if CdG.CaptureOn(n.id) then return C.orange end
    return CdG.FactionColor(CdG.GetOwner(n.id))
end

local function StatusText(n)
    if n.kind == "mine" then
        local m = db().mines[n.id]
        local v = m and m.v or 100
        if m then v = math.min(100, v + math.floor((time() - (m.t or time())) / 180)) end
        return format("Reservas: %d / 100", v), C.mine
    end
    if n.kind == "lumber" then return "Aserradero", C.lumber end
    local cf, prog, total = CdG.CaptureOn(n.id)
    if cf then return CdG.Clock(total - prog), C.orange end
    local o = CdG.GetOwner(n.id)
    if n.kind == "capital" then
        return (o and o ~= n.home) and ("Capital · " .. CdG.FactionName(o)) or "Capital", CdG.FactionColor(o)
    end
    if n.kind == "keep" or n.kind == "outpost" then
        local _, _, _, g = CdG.GetOwner(n.id)
        if g then return "<" .. g .. ">", CdG.FactionColor(o) end
    end
    if o then return CdG.FactionName(o), CdG.FactionColor(o) end
    if CdG.CanAttack(n, CdG.myFK) then return "¡Disponible!", C.gold end
    return "Neutral", C.muted
end

-- ---------------------------------------------------------------------------
-- Capa sobre el mapa
-- ---------------------------------------------------------------------------
local layer = CreateFrame("Frame", "CdGMapLayer", WorldMapButton)
layer:SetAllPoints()
layer:SetFrameLevel(WorldMapButton:GetFrameLevel() + 3)

local pins, dots, contPins = {}, {}, {}
local function GetPin(i)
    local p = pins[i]
    if p then return p end
    p = CreateFrame("Button", nil, layer)
    p:SetFrameLevel(layer:GetFrameLevel() + 1)
    p.circle = p:CreateTexture(nil, "BACKGROUND"); p.circle:SetTexture(MEDIA .. "circle"); p.circle:SetAllPoints()
    p.glow = p:CreateTexture(nil, "BORDER"); p.glow:SetTexture(MEDIA .. "glow"); p.glow:SetBlendMode("ADD")
    p.glow:SetPoint("CENTER"); p.glow:Hide()
    p.icon = p:CreateTexture(nil, "ARTWORK"); p.icon:SetPoint("CENTER", 0, -2)
    p.ribbon = p:CreateTexture(nil, "OVERLAY"); p.ribbon:SetTexture(MEDIA .. "ribbon"); p.ribbon:SetHeight(22)
    p.name = p:CreateFontString(nil, "OVERLAY")
    p.name:SetFont(CdG.TITLE_FONT, 13); p.name:SetShadowOffset(1, -1); p.name:SetTextColor(1, 0.92, 0.75)
    p.state = CdG.Text(p, 10)
    p:SetScript("OnEnter", function(self)
        local n = self.node
        WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT")
        WorldMapTooltip:AddLine(n.name, 1, 0.82, 0.3)
        WorldMapTooltip:AddLine(CdG.KIND[n.kind].label .. (n.front and (" · " .. n.front.name) or (n.zone and (" · " .. n.zone) or "")), 0.8, 0.8, 0.8)
        local o, t, who, g = CdG.GetOwner(n.id)
        if CdG.WAR[n.kind] then
            if o then
                local c = CdG.FactionColor(o)
                WorldMapTooltip:AddLine("Controlado por la " .. CdG.FactionName(o) .. (g and (" · <" .. g .. ">") or ""), c[1], c[2], c[3])
                if who then WorldMapTooltip:AddLine(who .. " · " .. CdG.Ago(t), 0.6, 0.6, 0.6) end
            else
                WorldMapTooltip:AddLine("Neutral", 0.7, 0.7, 0.7)
            end
            local cf, prog, total = CdG.CaptureOn(n.id)
            if cf then WorldMapTooltip:AddLine(format("¡La %s lo está capturando! %s / %s", CdG.FactionName(cf), CdG.Clock(prog), CdG.Clock(total)), 1, 0.55, 0.1) end
            local rf = CdG.Reinforcements(n.id)
            if rf > 0 then WorldMapTooltip:AddLine(format("Reforzado (+%d min)", rf), 0.4, 0.8, 1) end
            if CdG.CanAttack(n, CdG.myFK) then
                WorldMapTooltip:AddLine("Puedes atacarlo: " .. CdG.Clock(CdG.CaptureTime(n, CdG.myFK, true)) .. " dentro del círculo", 0.3, 1, 0.3, true)
            elseif o ~= CdG.myFK then
                WorldMapTooltip:AddLine("Bloqueado: toma antes un punto conectado", 0.6, 0.6, 0.6, true)
            end
        elseif n.kind == "mine" then
            WorldMapTooltip:AddLine("Quédate dentro para ganar monedas de guerra (1 cada 20 s). Minar mineral aquí da +2.", 1, 1, 1, true)
        else
            WorldMapTooltip:AddLine("Quédate dentro para reunir madera y donarla a la dominación de tu facción.", 1, 1, 1, true)
        end
        WorldMapTooltip:Show()
    end)
    p:SetScript("OnLeave", function() WorldMapTooltip:Hide() end)
    pins[i] = p
    return p
end

local function GetDot(i)
    local d = dots[i]
    if not d then
        d = layer:CreateTexture(nil, "ARTWORK"); d:SetTexture(MEDIA .. "dot"); d:SetWidth(4); d:SetHeight(4)
        dots[i] = d
    end
    return d
end

local function GetContPin(i)
    local p = contPins[i]
    if p then return p end
    p = CreateFrame("Button", nil, layer)
    p:SetFrameLevel(layer:GetFrameLevel() + 2)
    p.glow = p:CreateTexture(nil, "BACKGROUND"); p.glow:SetTexture(MEDIA .. "glow"); p.glow:SetBlendMode("ADD")
    p.glow:SetPoint("CENTER"); p.glow:SetVertexColor(rgba(C.gold))
    p.icon = p:CreateTexture(nil, "ARTWORK"); p.icon:SetAllPoints()
    p:SetScript("OnEnter", function(self)
        WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT")
        for _, l in ipairs(self.lines) do WorldMapTooltip:AddLine(l[1], l[2] or 1, l[3] or 1, l[4] or 1, true) end
        WorldMapTooltip:Show()
    end)
    p:SetScript("OnLeave", function() WorldMapTooltip:Hide() end)
    p:SetScript("OnClick", function(self) if self.map then CdG.ShowMapFor(self.map) end end)
    contPins[i] = p
    return p
end

-- cartel "Siguiente objetivo" arriba del mapa
local banner = CreateFrame("Frame", nil, layer)
banner:SetWidth(260); banner:SetHeight(50)
banner:SetPoint("TOP", layer, "TOP", 0, -6)
banner:SetFrameLevel(layer:GetFrameLevel() + 6)
banner.bg = banner:CreateTexture(nil, "BACKGROUND"); banner.bg:SetTexture(CdG.FLAT); banner.bg:SetAllPoints()
banner.bg:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0.05, 0.04, 0.03, 0.85)
banner.line = banner:CreateTexture(nil, "ARTWORK"); banner.line:SetTexture(CdG.FLAT); banner.line:SetHeight(1)
banner.line:SetPoint("BOTTOMLEFT", 20, 2); banner.line:SetPoint("BOTTOMRIGHT", -20, 2)
banner.line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0.3, 0, 1, 0.82, 0.3, 0.9)
banner.t1 = CdG.Title(banner, 18); banner.t1:SetPoint("TOP", 0, -4)
banner.t2 = CdG.Text(banner, 11); banner.t2:SetPoint("TOP", banner.t1, "BOTTOM", 0, -2)

local lastLayout, pulse = nil, 0
local function HideAll()
    for _, p in ipairs(pins) do p:Hide() end
    for _, d in ipairs(dots) do d:Hide() end
    for _, p in ipairs(contPins) do p:Hide() end
    banner:Hide()
end

local function DrawZone(map, nodes)
    local w, h = WorldMapButton:GetWidth(), WorldMapButton:GetHeight()
    local zw = CdG.ZoneYards(map)
    local compact = db().mapmode == "compact"
    local alpha = db().mapalpha or 0.8
    local front = CdG.FRONT_BY_MAP[map]
    local obj = front and CdG.NextObjective(front)
    -- caminos punteados
    local di = 0
    if front and db().links then
        for _, a in ipairs(front.points) do
            for _, b in ipairs(a.links) do
                if a.id < b.id then
                    local ax, ay, bx, by = a.x * w, -a.y * h, b.x * w, -b.y * h
                    local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
                    local oa, ob = CdG.GetOwner(a.id), CdG.GetOwner(b.id)
                    local col = (oa and oa == ob) and CdG.FactionColor(oa) or C.text
                    local steps = math.floor(len / 9)
                    for s = 2, steps - 2 do
                        di = di + 1
                        local d = GetDot(di)
                        local t = s / steps
                        d:ClearAllPoints(); d:SetPoint("CENTER", layer, "TOPLEFT", ax + (bx - ax) * t, ay + (by - ay) * t)
                        d:SetVertexColor(col[1], col[2], col[3], (oa and oa == ob) and 0.85 * alpha or 0.45 * alpha)
                        d:Show()
                    end
                end
            end
        end
    end
    for i = di + 1, #dots do dots[i]:Hide() end
    -- círculos
    for i, n in ipairs(nodes) do
        local p = GetPin(i)
        p.node = n
        local real = zw and (2 * n.r / zw * w) or 0
        local d = math.max(real, MIN_D[n.kind] * (compact and 0.7 or 1))
        p:SetWidth(d); p:SetHeight(d)
        p:ClearAllPoints(); p:SetPoint("CENTER", layer, "TOPLEFT", n.x * w, -n.y * h)
        local col = NodeColor(n)
        p.circle:SetVertexColor(col[1], col[2], col[3], 0.55 * alpha)
        local isz = (n.kind == "capital" or n.kind == "keep") and 22 or 17
        if compact then isz = isz * 0.8 end
        p.icon:SetTexture(MEDIA .. ICON[n.kind]); p.icon:SetWidth(isz); p.icon:SetHeight(isz)
        local ic = (n.kind == "mine" or n.kind == "lumber") and { 0.85, 0.85, 0.85 } or CdG.FactionColor(CdG.GetOwner(n.id))
        p.icon:SetVertexColor(ic[1], ic[2], ic[3], 1)
        if n == obj then
            p.glow:SetWidth(d * 1.9); p.glow:SetHeight(d * 1.9); p.glow:SetVertexColor(rgba(C.gold)); p.glow:Show()
        elseif CdG.CaptureOn(n.id) then
            p.glow:SetWidth(d * 1.7); p.glow:SetHeight(d * 1.7); p.glow:SetVertexColor(rgba(C.orange)); p.glow:Show()
        else p.glow:Hide() end
        if db().labels and not compact then
            p.name:SetText(n.name)
            p.name:ClearAllPoints(); p.name:SetPoint("BOTTOM", p, "TOP", 0, -d * 0.32)
            p.ribbon:ClearAllPoints(); p.ribbon:SetPoint("CENTER", p.name, "CENTER", 0, 0)
            p.ribbon:SetWidth(p.name:GetStringWidth() + 34)
            local st, sc = StatusText(n)
            p.state:SetText(st); p.state:SetTextColor(rgba(sc))
            p.state:ClearAllPoints(); p.state:SetPoint("TOP", p.ribbon, "BOTTOM", 0, 2)
            p.name:Show(); p.ribbon:Show(); p.state:Show()
        else
            p.name:Hide(); p.ribbon:Hide(); p.state:Hide()
        end
        p:Show()
    end
    for i = #nodes + 1, #pins do pins[i]:Hide() end
    -- generales y recompensas en este frente
    local ci = 0
    if front then
        for _, g in pairs(CdG.generals) do
            if g.fk == front.key and g.x and g.x > 0 then
                ci = ci + 1
                local p = GetContPin(ci)
                p:SetWidth(24); p:SetHeight(24); p.icon:SetTexture(MEDIA .. "swords"); p.icon:SetTexCoord(0, 1, 0, 1)
                p.icon:SetVertexColor(rgba(CdG.FactionColor(g.f))); p.glow:SetWidth(40); p.glow:SetHeight(40); p.glow:Show()
                p.map = nil
                p.lines = { { "General " .. g.name, 1, 0.82, 0.3 }, { "Punto de reunión de la " .. CdG.FactionName(g.f) } }
                p:ClearAllPoints(); p:SetPoint("CENTER", layer, "TOPLEFT", g.x * w, -g.y * h); p:Show()
            end
        end
        for name, b in pairs(CdG.bounties) do
            if b.fk == front.key and b.x and b.x > 0 then
                ci = ci + 1
                local p = GetContPin(ci)
                p:SetWidth(20); p:SetHeight(20)
                p.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons"); p.icon:SetTexCoord(0.75, 1, 0.25, 0.5)
                p.icon:SetVertexColor(1, 1, 1); p.glow:Hide(); p.map = nil
                p.lines = { { "Recompensa: " .. name, 1, 0.3, 0.3 }, { format("%d bajas seguidas (%s)", b.s, CdG.FactionName(b.f)) } }
                p:ClearAllPoints(); p:SetPoint("CENTER", layer, "TOPLEFT", b.x * w, -b.y * h); p:Show()
            end
        end
    end
    for i = ci + 1, #contPins do contPins[i]:Hide() end
    -- cartel
    if front then
        banner:Show()
        if obj then
            banner.t1:SetText("Siguiente objetivo"); banner.t2:SetText(obj.name)
        else
            local win = CdG.FrontWinner(front)
            banner.t1:SetText(front.name); banner.t2:SetText(win and ("Frente ganado por la " .. CdG.FactionName(win)) or "")
        end
        if CdG.Featured() == front then banner.t2:SetText(banner.t2:GetText() .. "  ·  |cffffcc55Frente destacado|r") end
        banner:SetWidth(math.max(220, banner.t2:GetStringWidth() + 60))
    else
        banner:Hide()
    end
end

local function DrawContinent(cont)
    local w, h = WorldMapButton:GetWidth(), WorldMapButton:GetHeight()
    local cmap = CdG.CONTINENT_MAPS[cont].map
    local feat = CdG.Featured()
    local i = 0
    local function Add(map, x, y)
        local cx, cy, which = CdG.ToContinent(map, x, y)
        if not cx or which ~= cmap or cx < 0 or cx > 1 or cy < 0 or cy > 1 then return end
        i = i + 1
        local p = GetContPin(i)
        p:ClearAllPoints(); p:SetPoint("CENTER", layer, "TOPLEFT", cx * w, -cy * h)
        p.icon:SetTexCoord(0, 1, 0, 1)
        p.map = map
        return p
    end
    for _, f in ipairs(CdG.FRONTS) do
        if not f.nocontinent then
            local p = Add(f.map, f.cx, f.cy)
            if p then
                local a, hh, n = CdG.FrontScore(f)
                local win = CdG.FrontWinner(f)
                local col = win and CdG.FactionColor(win) or (a > hh and CdG.FactionColor("A") or (hh > a and CdG.FactionColor("H") or C.neutral))
                p:SetWidth(26); p:SetHeight(26)
                p.icon:SetTexture(MEDIA .. "keep"); p.icon:SetVertexColor(col[1], col[2], col[3], (a + hh > 0 or win) and 1 or 0.6)
                if f == feat then p.glow:SetWidth(54); p.glow:SetHeight(54); p.glow:Show() else p.glow:Hide() end
                p.lines = { { f.name, 1, 0.82, 0.3 }, { f.desc, 0.8, 0.8, 0.8 },
                    { format("Puntos: |cff4a8cff%d Alianza|r · |cffff4033%d Horda|r · %d en total", a, hh, n) } }
                if win then table.insert(p.lines, { "Frente ganado por la " .. CdG.FactionName(win), rgba(CdG.FactionColor(win)) }) end
                if f == feat then table.insert(p.lines, { "Frente destacado de hoy: bajas dobles", 1, 0.82, 0.3 }) end
                local obj = CdG.NextObjective(f)
                if obj then table.insert(p.lines, { "Siguiente objetivo: " .. obj.name, 0.3, 1, 0.3 }) end
                table.insert(p.lines, { "Clic: abrir el mapa de la zona", 0.6, 0.6, 0.6 })
                p:Show()
            end
        end
    end
    for _, k in ipairs(CdG.KEEP_LIST) do
        local p = Add(k.map, k.x, k.y)
        if p then
            local o, t, who, g = CdG.GetOwner(k.id)
            p:SetWidth(30); p:SetHeight(30)
            p.icon:SetTexture(MEDIA .. "keep"); p.icon:SetVertexColor(rgba(o and CdG.FactionColor(o) or { 0.45, 0.45, 0.45, 1 }))
            p.glow:Hide()
            p.lines = { { k.name, 1, 0.82, 0.3 }, { "Fortaleza de hermandad · " .. (k.zone or ""), 0.8, 0.8, 0.8 },
                { g and ("<" .. g .. ">  (" .. CdG.FactionName(o) .. ")") or "Sin dueño: ¡tómala para tu hermandad!", rgba(CdG.FactionColor(o)) } }
            p:Show()
        end
    end
    for _, k in ipairs(CdG.OUTPOST_LIST) do
        if not (k.front and k.front.nocontinent) then
            local p = Add(k.map, k.x, k.y)
            if p then
                local o, _, _, g = CdG.GetOwner(k.id)
                p:SetWidth(16); p:SetHeight(16)
                p.icon:SetTexture(MEDIA .. "tower"); p.icon:SetVertexColor(rgba(o and CdG.FactionColor(o) or { 0.5, 0.5, 0.5, 1 }))
                p.glow:Hide()
                p.lines = { { k.name, 1, 0.82, 0.3 }, { "Avanzada de hermandad · " .. (k.zone or ""), 0.8, 0.8, 0.8 },
                    { g and ("<" .. g .. ">") or "Libre", rgba(CdG.FactionColor(o)) } }
                p:Show()
            end
        end
    end
    for _, g in pairs(CdG.generals) do
        local f = CdG.FRONT_BY_KEY[g.fk]
        if f and g.x and g.x > 0 then
            local p = Add(f.map, g.x, g.y)
            if p then
                p:SetWidth(22); p:SetHeight(22); p.icon:SetTexture(MEDIA .. "swords"); p.icon:SetVertexColor(rgba(CdG.FactionColor(g.f)))
                p.glow:Hide(); p.lines = { { "General " .. g.name, 1, 0.82, 0.3 }, { f.name } }
                p:Show()
            end
        end
    end
    for name, b in pairs(CdG.bounties) do
        local f = CdG.FRONT_BY_KEY[b.fk or ""]
        if f and b.x and b.x > 0 then
            local p = Add(f.map, b.x, b.y)
            if p then
                p:SetWidth(18); p:SetHeight(18)
                p.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons"); p.icon:SetTexCoord(0.75, 1, 0.25, 0.5); p.icon:SetVertexColor(1, 1, 1)
                p.glow:Hide(); p.lines = { { "Recompensa: " .. name, 1, 0.3, 0.3 }, { format("%d bajas seguidas · %s", b.s, f.name) } }
                p:Show()
            end
        end
    end
    for j = i + 1, #contPins do contPins[j]:Hide() end
end

local function UpdateMap()
    if not CdG.db or not WorldMapFrame:IsShown() then return end
    if not db().markers or db().mapmode == "hidden" then HideAll() return end
    local map = GetMapInfo()
    local level = GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel() or 0
    if not map or level > 0 then HideAll() return end
    local nodes = CdG.BY_MAP[map]
    if nodes then
        for _, p in ipairs(contPins) do p:Hide() end
        DrawZone(map, nodes)
    elseif CdG.CONT_BY_MAP[map] and db().continent then
        for _, p in ipairs(pins) do p:Hide() end
        for _, d in ipairs(dots) do d:Hide() end
        banner:Hide()
        DrawContinent(CdG.CONT_BY_MAP[map])
    else
        HideAll()
    end
end
CdG.UpdateMapPins = UpdateMap

local mapWatch = CreateFrame("Frame")
mapWatch:RegisterEvent("WORLD_MAP_UPDATE")
mapWatch:SetScript("OnEvent", UpdateMap)
WorldMapFrame:HookScript("OnShow", UpdateMap)
CdG.OnChange(UpdateMap)
-- latido del objetivo
layer:SetScript("OnUpdate", function(_, e)
    pulse = pulse + e
    local a = 0.55 + 0.45 * math.sin(pulse * 3)
    for _, p in ipairs(pins) do if p:IsShown() and p.glow:IsShown() then p.glow:SetAlpha(a) end end
end)

-- abrir el mapa de una zona por su nombre interno
function CdG.ShowMapFor(map)
    if not WorldMapFrame:IsShown() then ShowUIPanel(WorldMapFrame) end
    for c = 1, 4 do
        local zones = { GetMapZones(c) }
        for z = 1, #zones do
            SetMapZoom(c, z)
            if GetMapInfo() == map then UpdateMap() return end
        end
    end
    SetMapToCurrentZone()
end

-- ---------------------------------------------------------------------------
-- Minimapa
-- ---------------------------------------------------------------------------
local MM_OUT = { [0] = 466.6667, 400, 333.3333, 266.6667, 200, 133.3333 }
local MM_IN = { [0] = 300, 240, 180, 120, 80, 50 }
local mmPins = {}
local function MMPin(i)
    local p = mmPins[i]
    if p then return p end
    p = CreateFrame("Frame", nil, Minimap)
    p:SetFrameLevel(Minimap:GetFrameLevel() + 4)
    p:SetWidth(12); p:SetHeight(12)
    p.dot = p:CreateTexture(nil, "ARTWORK"); p.dot:SetTexture(MEDIA .. "circle"); p.dot:SetAllPoints()
    p.ring = p:CreateTexture(nil, "OVERLAY"); p.ring:SetTexture(MEDIA .. "ring"); p.ring:SetPoint("CENTER"); p.ring:SetWidth(18); p.ring:SetHeight(18)
    p.ring:SetVertexColor(rgba(C.gold))
    mmPins[i] = p
    return p
end

local mmAcc = 0
local mmFrame = CreateFrame("Frame")
mmFrame:SetScript("OnUpdate", function(_, e)
    mmAcc = mmAcc + e
    if mmAcc < 0.1 then return end
    mmAcc = 0
    local used = 0
    local map, px, py = CdG.PlayerPos()
    if CdG.db and db().minimap and map and px and CdG.BY_MAP[map] then
        local zw, zh = CdG.ZoneYards(map)
        local zoom = Minimap:GetZoom()
        local indoor = tonumber(GetCVar("minimapInsideZoom")) == zoom and tonumber(GetCVar("minimapZoom")) ~= zoom
        local radius = (indoor and MM_IN[zoom] or MM_OUT[zoom] or 466) / 2
        local half = Minimap:GetWidth() / 2
        local rot = GetCVar("rotateMinimap") == "1"
        local facing = rot and GetPlayerFacing() or 0
        local cs, sn = math.cos(facing), math.sin(facing)
        local obj = CdG.current and CdG.NextObjective(CdG.current)
        for _, n in ipairs(CdG.BY_MAP[map]) do
            local dx, dy = (n.x - px) * zw, (n.y - py) * zh
            if rot then dx, dy = dx * cs - dy * sn, dx * sn + dy * cs end
            local dist = math.sqrt(dx * dx + dy * dy)
            local edge = dist > radius * 0.92
            if not edge or n == obj then
                used = used + 1
                local p = MMPin(used)
                local k = edge and (radius * 0.92 / dist) or 1
                p:ClearAllPoints()
                p:SetPoint("CENTER", Minimap, "CENTER", dx * k / radius * half, -dy * k / radius * half)
                local col = NodeColor(n)
                p.dot:SetVertexColor(col[1], col[2], col[3], edge and 0.7 or 0.9)
                local sz = (n.kind == "capital" or n.kind == "keep") and 12 or 9
                p:SetWidth(sz); p:SetHeight(sz)
                if n == obj then p.ring:Show() else p.ring:Hide() end
                p:Show()
            end
        end
    end
    for i = used + 1, #mmPins do mmPins[i]:Hide() end
end)

-- ---------------------------------------------------------------------------
-- HUD de captura (aparece al entrar en un círculo)
-- ---------------------------------------------------------------------------
local hud = CreateFrame("Frame", "CdGCaptureHUD", UIParent)
hud:SetWidth(280); hud:SetHeight(74)
hud:SetPoint("TOP", UIParent, "TOP", 0, -120)
hud:SetMovable(true); hud:EnableMouse(true); hud:SetClampedToScreen(true)
hud:RegisterForDrag("LeftButton")
hud:SetScript("OnDragStart", hud.StartMoving)
hud:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    db().hudpos = { p, rp, x, y }
end)
CdG.Ornate(hud, 0.92)
hud:Hide()
hud.icon = hud:CreateTexture(nil, "ARTWORK"); hud.icon:SetWidth(30); hud.icon:SetHeight(30); hud.icon:SetPoint("TOPLEFT", 14, -12)
hud.name = CdG.Title(hud, 15); hud.name:SetPoint("TOPLEFT", hud.icon, "TOPRIGHT", 8, 0)
hud.time = CdG.Text(hud, 11); hud.time:SetPoint("TOPRIGHT", -14, -14)
hud.status = CdG.Text(hud, 10); hud.status:SetPoint("TOPLEFT", hud.name, "BOTTOMLEFT", 0, -2); hud.status:SetWidth(220); hud.status:SetJustifyH("LEFT")
hud.bar = CdG.Progress(hud, 12); hud.bar:SetPoint("BOTTOMLEFT", 14, 12); hud.bar:SetPoint("BOTTOMRIGHT", -14, 12)
CdG.HUD = hud

CdG.OnChange(function()
    if not CdG.db then return end
    local S = CdG.Engine.state
    if not db().hud or not S.node then hud:Hide() return end
    if not hud.placed then
        hud.placed = true
        local p = db().hudpos
        if p then hud:ClearAllPoints(); hud:SetPoint(p[1], UIParent, p[2], p[3], p[4]) end
    end
    local n = S.node
    hud.icon:SetTexture(MEDIA .. ICON[n.kind])
    local col = NodeColor(n)
    hud.icon:SetVertexColor(rgba((n.kind == "mine" or n.kind == "lumber") and col or CdG.FactionColor(CdG.GetOwner(n.id))))
    hud.name:SetText(n.name)
    hud.status:SetText(S.status)
    if S.mode == "capture" or S.mode == "req" then
        hud.time:SetText(format("%s / %s", CdG.Clock(S.prog), CdG.Clock(S.total)))
        hud.bar:SetValue(S.pct, S.mode == "req" and C.muted or CdG.FactionColor(CdG.myFK)); hud.bar.text:SetText(format("%d%%", S.pct * 100))
    elseif S.mode == "mine" then
        hud.time:SetText(format("%d / %d monedas", CdG.char.coins, CdG.MAX_COINS))
        hud.bar:SetValue(S.pct, C.mine); hud.bar.text:SetText(format("Reservas %d / 100", S.prog))
    elseif S.mode == "lumber" then
        hud.time:SetText("")
        hud.bar:SetValue(S.pct, C.lumber); hud.bar.text:SetText(format("Madera %d / %d", S.prog, S.total))
    elseif S.mode == "hold" then
        hud.time:SetText(CdG.FactionName(CdG.myFK))
        hud.bar:SetValue(1, CdG.FactionColor(CdG.myFK)); hud.bar.text:SetText("Bajo tu control")
    else
        hud.time:SetText("")
        hud.bar:SetValue(0); hud.bar.text:SetText("")
    end
    hud:SetScale(db().scale or 1)
    hud:Show()
end)
