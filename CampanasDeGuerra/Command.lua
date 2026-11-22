-- ============================================================================
-- Campañas de Guerra - Mando de control (configuración)
-- ============================================================================
local CdG = CdG
local C, rgba = CdG.C, CdG.rgba
local Capping = Capping
local L = Capping.L
local media = LibStub("LibSharedMedia-3.0")
local MEDIA = CdG.MEDIA

local W, H, SIDE = 920, 620, 210
local f = CdG.Window("CdGCommandCenter", W, H, "Mando de control")
f.title:ClearAllPoints(); f.title:SetPoint("TOPLEFT", SIDE + 30, -20); f.title:SetFont(CdG.TITLE_FONT, 26)
CdG.Command = f

local sub = CdG.Text(f, 10, "muted"); sub:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 2, -2)
sub:SetText("Configura las campañas, el mapa, la interfaz y los temporizadores de los campos de batalla")

-- barra lateral
local side = CreateFrame("Frame", nil, f); CdG.Inset(side)
side:SetPoint("TOPLEFT", 14, -14); side:SetPoint("BOTTOMLEFT", 14, 14); side:SetWidth(SIDE)
local crest = CdG.Crest(side, 64); crest:SetPoint("TOP", 0, -12)
local sideName = CdG.Title(side, 15); sideName:SetPoint("TOP", crest, "BOTTOM", 0, -4)
local sideRank = CdG.Text(side, 10, "muted"); sideRank:SetPoint("TOP", sideName, "BOTTOM", 0, -2)

local content = CreateFrame("Frame", nil, f)
content:SetPoint("TOPLEFT", side, "TOPRIGHT", 16, -62)
content:SetPoint("BOTTOMRIGHT", -18, 16)
local CW = W - SIDE - 14 - 16 - 18
local COL = math.floor((CW - 24) / 2)

local pageTitle = CdG.Title(content, 17, "text"); pageTitle:SetPoint("TOPLEFT", 0, 0)
local pageDesc = CdG.Text(content, 10, "muted"); pageDesc:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", 0, -3)
pageDesc:SetWidth(CW); pageDesc:SetJustifyH("LEFT")

local pages, nav, current = {}, {}, "summary"
local ShowPage
local NAV = {
    { "summary", "Resumen", "Interface\\Icons\\INV_BannerPVP_02" },
    { "campaign", "Campaña", "Ability_Warrior_BattleShout" },
    { "fronts", "Frentes", "INV_Misc_Map_01" },
    { "map", "Mapa e interfaz", "INV_Misc_Spyglass_03" },
    { "bgs", "Campos de batalla", "Achievement_BG_winWSG" },
    { "bars", "Barras", "INV_Misc_PocketWatch_01" },
    { "bgmap", "Mapa de campo", "INV_Misc_Map02" },
    { "profile", "Perfil", "INV_Misc_Gear_01" },
}
for i, n in ipairs(NAV) do
    local key = n[1]
    local icon = n[3]:find("\\") and n[3] or ("Interface\\Icons\\" .. n[3])
    local b = CdG.WarButton(side, n[2], icon, SIDE - 20, 30)
    b:SetPoint("TOP", 0, -112 - (i - 1) * 34)
    b:SetScript("OnClick", function() ShowPage(key) end)
    nav[key] = b
end
local foot = CdG.Text(side, 9, "muted")
foot:SetPoint("BOTTOMLEFT", 12, 12); foot:SetPoint("BOTTOMRIGHT", -12, 12); foot:SetJustifyH("LEFT")
foot:SetText("Barras: clic derecho = menú, Mayús+clic = /decir, Ctrl+clic = campo de batalla.\n\n/campanas guia para la guía completa.\n\n|cffffcc55Hecho por Don Arequipa|r\nLíder de Comunidad Wargames")

local function NewPage(key, titleText, desc)
    local p = CreateFrame("Frame", nil, content)
    p:SetPoint("TOPLEFT", 0, -42); p:SetPoint("BOTTOMRIGHT")
    p:Hide()
    p.title, p.desc, p.controls = titleText, desc, {}
    pages[key] = p
    return p
end
local function Add(p, ctrl) table.insert(p.controls, ctrl); return ctrl end
local function Col(p, x) return { p = p, x = x, y = 0 } end
local function Place(col, ctrl, h)
    ctrl:ClearAllPoints()
    ctrl:SetPoint("TOPLEFT", col.p, "TOPLEFT", col.x, -col.y)
    if ctrl.SetWidth and not ctrl.keepWidth then ctrl:SetWidth(COL) end
    col.y = col.y + (h or 28)
    return Add(col.p, ctrl)
end
local function Header(col, text)
    local h = CdG.Header(col.p, text)
    h:SetPoint("TOPLEFT", col.p, "TOPLEFT", col.x - 6, -col.y - 2); h:SetWidth(COL + 12)
    h.text:SetJustifyH("CENTER")
    col.y = col.y + 24
    return h
end
local function Box(p, x, y, w, h)
    local b = CreateFrame("Frame", nil, p); CdG.Inset(b)
    b:SetPoint("TOPLEFT", x, -y); b:SetWidth(w); b:SetHeight(h)
    return b
end

-- Los controles se construyen al cargar el archivo, antes de que existan los
-- ajustes (CdG.db se crea al entrar al mundo y Capping.db al cargar el addon).
-- Mientras tanto leen de tablas vacías; al abrir el mando se refrescan con los reales.
local WHITE = { r = 1, g = 1, b = 1, a = 1 }
local EMPTY_C = {}
local EMPTY_B = { colors = setmetatable({}, { __index = function() return WHITE end }) }
local cdb = function() return CdG.db or EMPTY_C end
local bdb = function() return Capping.db or EMPTY_B end
local function CToggle(col, label, key, after, tip)
    return Place(col, CdG.Toggle(col.p, label, function() return cdb()[key] end,
        function(v) cdb()[key] = v; if after then after(v) end; CdG.Changed() end, tip), 24)
end
local function BToggle(col, label, key, after, tip)
    return Place(col, CdG.Toggle(col.p, label, function() return bdb()[key] end,
        function(v) bdb()[key] = v; if after then after(key) end end, tip), 24)
end
local function Look(k) Capping:ApplyLook(k); CdG.DockUpdate() end

-- ---------------------------------------------------------------------------
-- Resumen
-- ---------------------------------------------------------------------------
do
    local p = NewPage("summary", "Resumen", "Estado de la guerra, tus recursos y accesos rápidos.")
    local cw = math.floor((CW - 30) / 4)
    p.cards = {}
    for i, lbl in ipairs({ "DOMINACIÓN SEMANAL", "TU FRENTE", "RECURSOS", "RED" }) do
        local c = Box(p, (i - 1) * (cw + 10), 0, cw, 84)
        c.label = CdG.Text(c, 9, "gold"); c.label:SetPoint("TOPLEFT", 12, -10); c.label:SetText(lbl)
        c.value = CdG.Title(c, 17, "text"); c.value:SetPoint("TOPLEFT", c.label, "BOTTOMLEFT", 0, -6)
        c.sub = CdG.Text(c, 10, "muted"); c.sub:SetPoint("TOPLEFT", c.value, "BOTTOMLEFT", 0, -4); c.sub:SetWidth(cw - 20); c.sub:SetJustifyH("LEFT")
        p.cards[i] = c
    end
    p.dom = CdG.Progress(p.cards[1], 8); p.dom:SetPoint("BOTTOMLEFT", 12, 10); p.dom:SetPoint("BOTTOMRIGHT", -12, 10)
    local qh = CdG.Header(p, "ACCESOS RÁPIDOS"); qh:SetPoint("TOPLEFT", -6, -98); qh:SetWidth(CW + 12)
    local QUICK = {
        { "Panel de campaña", "Interface\\Icons\\INV_BannerPVP_02", function() CdG.TogglePanel() end },
        { "Clasificación", "Interface\\Icons\\INV_Misc_Book_09", function() CdG.ShowLeaderboard() end },
        { "Salón de la Fama", "Interface\\Icons\\Achievement_PVP_A_A", function() CdG.ShowFame() end },
        { "Guía", "Interface\\Icons\\INV_Misc_Note_01", function() CdG.ShowGuide() end },
        { "Probar barras", "Interface\\Icons\\INV_Misc_PocketWatch_01", function() Capping:TestBars() end },
        { "Mover temporizadores", "Interface\\Icons\\Ability_Rogue_Sprint", function() if cdb().dockbars then CdG.Print("Arrastra el marco «Temporizadores» por su cabecera (pulsa Probar barras para verlo).") else Capping.ToggleAnchor() end end },
        { "Sincronizar", "Interface\\Icons\\Spell_Arcane_PortalDalaran", function() CdG.RequestSync(); CdG.Print("Pidiendo el estado de la campaña…") end },
        { "Exportar", "Interface\\Icons\\INV_Scroll_03", function() CdG.ShowExport() end },
    }
    local qw = math.floor((CW - 30) / 4)
    for i, q in ipairs(QUICK) do
        local b = CdG.WarButton(p, q[1], q[2], qw, 30)
        local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
        b:SetPoint("TOPLEFT", col * (qw + 10), -122 - row * 36)
        b:SetScript("OnClick", q[3])
    end
    local lh = CdG.Header(p, "ÚLTIMOS SUCESOS"); lh:SetPoint("TOPLEFT", -6, -204); lh:SetWidth(CW + 12)
    local logBox = Box(p, 0, 226, CW, 262)
    p.log = {}
    for i = 1, 13 do
        local fs = CdG.Text(logBox, 10); fs:SetPoint("TOPLEFT", 12, -10 - (i - 1) * 19)
        fs:SetWidth(CW - 24); fs:SetJustifyH("LEFT")
        p.log[i] = fs
    end
    function p:Refresh()
        local a, h = CdG.Domination()
        self.cards[1].value:SetText(format("|cff4a8cff%.0f%%|r  ·  |cffff4033%.0f%%|r", a, h))
        self.cards[1].sub:SetText("Alianza  ·  Horda")
        self.dom:SetSplit(a / 100, C.alliance, C.horde)
        local fr = CdG.current
        if fr then
            local fa, fh, n = CdG.FrontScore(fr)
            self.cards[2].value:SetText(fr.short or fr.name)
            self.cards[2].sub:SetText(format("|cff4a8cff%d|r - |cffff4033%d|r de %d puntos", fa, fh, n))
        else
            local feat = CdG.Featured()
            self.cards[2].value:SetText("Ninguno")
            self.cards[2].sub:SetText("Destacado hoy: |cffffcc55" .. feat.name .. "|r")
        end
        local ch = CdG.char
        self.cards[3].value:SetText(format("%d monedas", ch.coins))
        self.cards[3].sub:SetText(format("%d madera  ·  %s", ch.wood, CdG.RANKS[ch.rank or 1][2]))
        local peers = CdG.Peers()
        self.cards[4].value:SetText(format("%d jugadores", peers))
        self.cards[4].sub:SetText(cdb().sync and (CdG.SyncChannelId() and "Canal oculto conectado" or "Conectando…") or "Sincronía desactivada")
        local log = cdb().log
        for i, fs in ipairs(self.log) do
            local e = log[i]
            if e then fs:SetText(format("|cff8a7a5a%s|r  %s", date("%d/%m %H:%M", e.t), e.text))
            else fs:SetText(i == 1 and "|cff888888Sin sucesos todavía. Ve a un frente y captura un punto.|r" or "") end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Campaña
-- ---------------------------------------------------------------------------
do
    local p = NewPage("campaign", "Campaña", "Reglas de captura, sincronización con otros jugadores y avisos.")
    local c1, c2 = Col(p, 6), Col(p, COL + 30)
    Header(c1, "CAPTURA")
    CToggle(c1, "Campañas activadas", "enabled", function() CdG.UpdateCurrentFront() end)
    CToggle(c1, "Exigir JcJ activado para capturar", "needpvp", nil, "Como en Overlord: activa el JcJ (/pvp) para que tus capturas cuenten.")
    CToggle(c1, "Exigir ir a pie (sin montura ni vuelo)", "needfoot")
    Place(c1, CdG.Slider(p, "Ritmo de captura (x tiempo)", 0.25, 2, 0.25, function() return cdb().speed end, function(v) cdb().speed = v end, "x%.2f"), 46)
    local note = CdG.Text(p, 10, "muted"); note:SetWidth(COL); note:SetJustifyH("LEFT")
    note:SetPoint("TOPLEFT", p, "TOPLEFT", c1.x, -c1.y)
    note:SetText("Normal: punto 2 min, capital 8 min, fortaleza 10 min, avanzada 5 min. Con x0,25 puedes probarlo todo en poco tiempo; para jugar con otros conviene que todos usen el mismo ritmo.")
    c1.y = c1.y + 56
    Header(c1, "SINCRONIZACIÓN")
    CToggle(c1, "Sincronizar con otros jugadores", "sync", function(v) CdG.SetSync(v) end,
        "Canal oculto (ambas facciones en UltimoWoW), hermandad y grupo. Necesario para ver la guerra en tiempo real.")
    local req = CdG.WarButton(p, "Pedir el estado ahora", "Interface\\Icons\\Spell_Arcane_PortalDalaran", COL, 26)
    req.keepWidth = true
    Place(c1, req, 32)
    req:SetScript("OnClick", function() CdG.RequestSync(); CdG.Print("Estado solicitado.") end)
    Header(c2, "AVISOS")
    CToggle(c2, "Avisos en pantalla", "alerts")
    CToggle(c2, "Sonidos", "sound")
    CToggle(c2, "Mensajes en el chat", "chat")
    CToggle(c2, "Avisar cuando un Némesis esté cerca", "nemesis")
    CToggle(c2, "Avisos de hermandades (fortalezas)", "guildalerts")
    CToggle(c2, "Rango, Némesis y recompensa en las fichas", "tooltip")
    Header(c2, "RECURSOS")
    local info = CdG.Text(p, 10); info:SetWidth(COL); info:SetJustifyH("LEFT")
    info:SetPoint("TOPLEFT", p, "TOPLEFT", c2.x, -c2.y)
    info:SetText("|cffffcc55Minas|r (amarillas): 1 moneda cada 20 s dentro, +2 al minar mineral, reservas compartidas de 100 que se recuperan solas.\n\n|cffffcc55Aserraderos|r (verdes): 10 de madera cada 10 s. Dona 500 para +1% de dominación.\n\n|cffffcc55Atacar|r y |cffffcc55Reforzar|r cuestan 25 monedas cada uno.")
end

-- ---------------------------------------------------------------------------
-- Frentes
-- ---------------------------------------------------------------------------
do
    local p = NewPage("fronts", "Frentes", "Todos los frentes de la 3.3.5: estado de cada punto y quién lo controla.")
    local conts = { "Reinos del Este", "Kalimdor", "Terrallende", "Rasganorte" }
    p.cont, p.sel = "Reinos del Este", nil
    p.tabs = {}
    for i, name in ipairs(conts) do
        local t = CdG.WarButton(p, name, nil, 120, 24)
        t:SetPoint("TOPLEFT", (i - 1) * 126, 0)
        t:SetScript("OnClick", function() p.cont = name; p.sel = nil; p:Refresh() end)
        p.tabs[i] = t
    end
    local list = Box(p, 0, 30, 300, 470)
    p.rows = {}
    for i = 1, 26 do
        local r = CreateFrame("Button", nil, list); r:SetHeight(17)
        r:SetPoint("TOPLEFT", 8, -8 - (i - 1) * 17.5); r:SetPoint("TOPRIGHT", -8, -8 - (i - 1) * 17.5)
        r.name = CdG.Text(r, 10); r.name:SetPoint("LEFT", 2, 0)
        r.score = CdG.Text(r, 10); r.score:SetPoint("RIGHT", -2, 0)
        r.hl = r:CreateTexture(nil, "HIGHLIGHT"); r.hl:SetTexture(CdG.FLAT); r.hl:SetAllPoints(); r.hl:SetVertexColor(1, 0.85, 0.4, 0.08)
        r:SetScript("OnClick", function(self) p.sel = self.front; p:Refresh() end)
        p.rows[i] = r
    end
    local det = Box(p, 310, 30, CW - 310, 470)
    p.dName = CdG.Title(det, 18); p.dName:SetPoint("TOPLEFT", 14, -12)
    p.dDesc = CdG.Text(det, 10, "muted"); p.dDesc:SetPoint("TOPLEFT", p.dName, "BOTTOMLEFT", 0, -4); p.dDesc:SetWidth(CW - 340); p.dDesc:SetJustifyH("LEFT")
    p.img = CdG.ZoneImage(det, 180, 120); p.img:SetPoint("TOPRIGHT", -12, -12)
    p.nodes = {}
    for i = 1, 16 do
        local r = CreateFrame("Frame", nil, det); r:SetHeight(18)
        r:SetPoint("TOPLEFT", 14, -140 - (i - 1) * 19); r:SetPoint("TOPRIGHT", -14, -140 - (i - 1) * 19)
        r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetWidth(14); r.icon:SetHeight(14); r.icon:SetPoint("LEFT")
        r.name = CdG.Text(r, 10); r.name:SetPoint("LEFT", 20, 0)
        r.state = CdG.Text(r, 10, "muted"); r.state:SetPoint("RIGHT")
        p.nodes[i] = r
    end
    local open = CdG.WarButton(det, "Ver en el mapa", "Interface\\Icons\\INV_Misc_Map_01", 150, 24)
    open:SetPoint("BOTTOMRIGHT", -12, 10)
    open:SetScript("OnClick", function() if p.sel then CdG.ShowMapFor(p.sel.map) end end)
    local ICONS = { point = "banner", capital = "keep", keep = "keep", outpost = "tower", mine = "mine", lumber = "lumber" }
    function p:Refresh()
        for i, t in ipairs(self.tabs) do t:SetRed(conts[i] == self.cont) end
        local fl = {}
        for _, fr in ipairs(CdG.FRONTS) do if fr.continent == self.cont then table.insert(fl, fr) end end
        table.sort(fl, function(a, b) return a.name < b.name end)
        self.sel = self.sel or (CdG.current and CdG.current.continent == self.cont and CdG.current) or fl[1]
        local feat = CdG.Featured()
        for i, r in ipairs(self.rows) do
            local fr = fl[i]
            if fr then
                r.front = fr
                r.name:SetText((fr == feat and "|cffffcc55*|r " or "") .. fr.name)
                r.name:SetTextColor(rgba(fr == self.sel and C.gold or (fr == CdG.current and C.good or C.text)))
                local a, h = CdG.FrontScore(fr)
                local w = CdG.FrontWinner(fr)
                r.score:SetText(w and ("|cff" .. (w == "A" and "4a8cff" or "ff4033") .. "Ganado|r") or format("|cff4a8cff%d|r - |cffff4033%d|r", a, h))
                r:Show()
            else r:Hide() end
        end
        local fr = self.sel
        if not fr then return end
        self.dName:SetText(fr.name)
        self.dDesc:SetText(fr.desc or "")
        self.img:SetMap(fr.map)
        local nodes = CdG.BY_MAP[fr.map] or {}
        for i, r in ipairs(self.nodes) do
            local n = nodes[i]
            if n then
                r.icon:SetTexture(MEDIA .. ICONS[n.kind])
                local o, t, who, g = CdG.GetOwner(n.id)
                local col = (n.kind == "mine" and C.mine) or (n.kind == "lumber" and C.lumber) or CdG.FactionColor(o)
                r.icon:SetVertexColor(rgba(col))
                r.name:SetText(n.name .. "  |cff8a7a5a" .. CdG.KIND[n.kind].label .. "|r")
                if CdG.WAR[n.kind] then
                    r.state:SetText(o and (CdG.FactionName(o) .. (g and (" <" .. g .. ">") or "") .. (t and t > 0 and (" · " .. CdG.Ago(t)) or "")) or "Neutral")
                else r.state:SetText("") end
                r:Show()
            else r:Hide() end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Mapa e interfaz
-- ---------------------------------------------------------------------------
do
    local p = NewPage("map", "Mapa e interfaz", "Qué se dibuja en el mapa del mundo y en el minimapa, y el tamaño de los paneles.")
    local c1, c2 = Col(p, 6), Col(p, COL + 30)
    Header(c1, "MAPA DEL MUNDO")
    CToggle(c1, "Mostrar la campaña en el mapa", "markers", function() CdG.UpdateMapPins() end)
    Place(c1, CdG.Cycle(p, "Modo del mapa", { { "full", "Completo" }, { "compact", "Compacto" }, { "hidden", "Oculto" } },
        function() return cdb().mapmode end, function(v) cdb().mapmode = v; CdG.UpdateMapPins() end), 30)
    CToggle(c1, "Nombres y estado sobre los círculos", "labels", function() CdG.UpdateMapPins() end)
    CToggle(c1, "Caminos entre puntos", "links", function() CdG.UpdateMapPins() end)
    CToggle(c1, "Frentes y fortalezas en el mapa del continente", "continent", function() CdG.UpdateMapPins() end)
    CToggle(c1, "Panel de campaña junto al mapa", "panelonmap")
    Place(c1, CdG.Slider(p, "Opacidad de los círculos", 0.2, 1, 0.05, function() return cdb().mapalpha end, function(v) cdb().mapalpha = v; CdG.UpdateMapPins() end), 46)
    Header(c2, "EN PANTALLA")
    CToggle(c2, "Objetivos en el minimapa", "minimap")
    CToggle(c2, "HUD de captura al entrar en un círculo", "hud")
    CToggle(c2, "Barras de campos de batalla en el marco temático", "dockbars", function() CdG.DockUpdate() end,
        "Las barras de Capping se colocan dentro del marco dorado «Temporizadores».")
    Place(c2, CdG.Slider(p, "Escala de los paneles", 0.6, 1.4, 0.05, function() return cdb().scale end, function(v)
        cdb().scale = v
        CdG.ApplyPanelScale()
        CdG.DockUpdate()
    end), 46)
    Place(c2, CdG.Slider(p, "Escala del panel junto al mapa", 0.5, 1.2, 0.05, function() return cdb().mapscale end, function(v)
        cdb().mapscale = v
        CdG.ApplyPanelScale()
    end), 46)
    local rs = CdG.WarButton(p, "Restablecer posiciones", "Interface\\Icons\\Ability_Rogue_Sprint", COL, 26)
    rs.keepWidth = true
    Place(c2, rs, 32)
    rs:SetScript("OnClick", function()
        cdb().hudpos, cdb().dockpos = nil, nil
        CdG.ResetPanelPositions()
        CdG.HUD:ClearAllPoints(); CdG.HUD:SetPoint("TOP", UIParent, "TOP", 0, -120)
        CdG.BarDock:ClearAllPoints(); CdG.BarDock:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200)
        CdG.Print("Posiciones restablecidas.")
    end)
end

-- ---------------------------------------------------------------------------
-- Campos de batalla
-- ---------------------------------------------------------------------------
do
    local p = NewPage("bgs", "Campos de batalla", "Temporizadores de cada campo de batalla y ayudas de cola. Se muestran en el marco «Temporizadores» y, dentro del campo, en el panel de campaña.")
    local c1, c2 = Col(p, 6), Col(p, COL + 30)
    Header(c1, "CAMPOS DE BATALLA")
    local function zone() Capping:ZONE_CHANGED_NEW_AREA() end
    BToggle(c1, L["Alterac Valley"], "av", zone)
    BToggle(c1, "   " .. L["Auto Quest Turnins"], "avquest")
    BToggle(c1, L["Arathi Basin"], "ab", zone)
    BToggle(c1, L["Eye of the Storm"], "eots", zone)
    BToggle(c1, L["Isle of Conquest"], "ioc", zone)
    BToggle(c1, L["Warsong Gulch"], "wsg", zone)
    BToggle(c1, L["Wintergrasp"], "winter", function() if not bdb().winter then Capping:StopBar(L["Wintergrasp"]) end end)
    BToggle(c1, "Arenas (tiempo de Visión de las Sombras)", "arena")
    Header(c2, "COLAS")
    BToggle(c2, L["Port Timer"], "port", nil, "Barra con el tiempo para entrar al campo de batalla cuando te llaman.")
    BToggle(c2, L["Wait Timer"], "wait", nil, "Barra con el tiempo estimado de espera en la cola.")
    Header(c2, "VALLE DE ALTERAC")
    local sync = CdG.WarButton(p, L["Request Sync"], "Interface\\Icons\\Spell_Arcane_PortalDalaran", COL, 26)
    sync.keepWidth = true
    Place(c2, sync, 34)
    sync:SetScript("OnClick", function() if GetRealZoneText() == L["Alterac Valley"] then Capping:SyncAV() else CdG.Print("Solo funciona dentro del Valle de Alterac.") end end)
    local note = CdG.Text(p, 10, "muted"); note:SetWidth(COL); note:SetJustifyH("LEFT")
    note:SetPoint("TOPLEFT", p, "TOPLEFT", c2.x, -c2.y - 6)
    note:SetText("Las barras de captura de bases y banderas se crean solas con los mensajes del campo de batalla, también en clientes en español.")
end

-- ---------------------------------------------------------------------------
-- Barras
-- ---------------------------------------------------------------------------
do
    local p = NewPage("bars", "Barras", "Aspecto de las barras de temporizador. Los cambios se aplican al momento: pulsa Probar para verlas.")
    local c1, c2 = Col(p, 6), Col(p, COL + 30)
    Header(c1, "TAMAÑO")
    local function sl(label, key, a, b, s, fmt)
        return Place(c1, CdG.Slider(p, label, a, b, s, function() return bdb()[key] end, function(v) bdb()[key] = v; Look(key) end, fmt), 44)
    end
    sl(L["Width"], "width", 100, 500, 2)
    sl(L["Height"], "height", 8, 40, 1)
    sl(L["Spacing"], "spacing", 0, 10, 1)
    sl("Tamaño de letra", "fontsize", 6, 24, 1)
    sl("Opacidad del fondo", "bgalpha", 0, 1, 0.05)
    Header(c1, "TEXTO E ICONO")
    local function list(kind) return function()
        local out = {}
        for _, n in ipairs(media:List(kind)) do table.insert(out, { n, n }) end
        return out
    end end
    local function cyc(label, key, l)
        return Place(c1, CdG.Cycle(p, label, l, function() return bdb()[key] end, function(v) bdb()[key] = v; Look(key) end), 28)
    end
    cyc(L["Texture"], "texture", list("statusbar"))
    cyc(L["Font"], "font", list("font"))
    cyc("Contorno", "fontflags", { { "", "Sin contorno" }, { "OUTLINE", "Fino" }, { "THICKOUTLINE", "Grueso" } })
    cyc("Icono", "iconpos", { { "<-", "Izquierda" }, { "->", "Derecha" }, { "X", "Oculto" } })
    cyc(L["Time Position"], "timepos", { { "<-", "Izquierda" }, { "->", "Derecha" } })
    Header(c2, "COMPORTAMIENTO")
    Place(c2, CdG.Toggle(p, "Dentro del marco «Temporizadores»", function() return cdb().dockbars end,
        function(v) cdb().dockbars = v; CdG.DockUpdate() end), 24)
    BToggle(c2, "Borde", "border", Look)
    BToggle(c2, L["Fill Grow"], "fill", Look)
    BToggle(c2, L["Fill Right"], "reverse", Look)
    BToggle(c2, L["Flip Growth"], "mainup", Look)
    BToggle(c2, "Barra fina (texto encima)", "altstyle", Look)
    BToggle(c2, "Bloquear (ignorar el ratón)", "lockbar", Look)
    Header(c2, "COLORES")
    local function sw(label, key)
        return Place(c2, CdG.Swatch(p, label, function() return bdb().colors[key] end, function() Look("colors") end), 24)
    end
    sw(FACTION_ALLIANCE, "alliance")
    sw(FACTION_HORDE, "horde")
    sw("Información", "info1")
    sw("Avisos", "info2")
    sw(L["Font"], "font")
    sw("Chispa", "spark")
    local test = CdG.WarButton(p, "Probar", "Interface\\Icons\\INV_Misc_PocketWatch_01", 120, 26)
    test:SetPoint("TOPLEFT", p, "TOPLEFT", c2.x, -c2.y - 8)
    test:SetScript("OnClick", function() Capping:TestBars() end)
    local anchor = CdG.WarButton(p, "Mostrar ancla", nil, 120, 26)
    anchor:SetPoint("LEFT", test, "RIGHT", 8, 0)
    anchor:SetScript("OnClick", function() Capping.ToggleAnchor() end)
end

-- ---------------------------------------------------------------------------
-- Mapa de campo
-- ---------------------------------------------------------------------------
do
    local p = NewPage("bgmap", "Mapa de campo", "El minimapa de campo de batalla que se abre dentro de los campos y en Conquista del Invierno.")
    local c1 = Col(p, 6)
    local function mm() Capping:ModMap() end
    BToggle(c1, L["Narrow Map Mode"], "narrow", mm)
    BToggle(c1, L["Narrow Anchor Left"], "narrowanchorleft", mm)
    BToggle(c1, L["Hide Border"], "hidemapborder", mm)
    Place(c1, CdG.Slider(p, L["Map Scale"], 0.5, 3, 0.05, function() return bdb().mapscale end, function(v) bdb().mapscale = v; Capping:ModMap() end), 48)
    local reset = CdG.WarButton(p, "Restablecer posición", nil, 180, 26)
    reset.keepWidth = true
    Place(c1, reset, 34)
    reset:SetScript("OnClick", function() Capping:ExecMover("resetmap") end)
end

-- ---------------------------------------------------------------------------
-- Perfil
-- ---------------------------------------------------------------------------
do
    local p = NewPage("profile", "Perfil", "Guardado por personaje y borrado de datos.")
    local c1, c2 = Col(p, 6), Col(p, COL + 30)
    Header(c1, "AJUSTES")
    Place(c1, CdG.Toggle(p, "Barras: ajustes por personaje (recarga)", function() return CampanasCharDB and true end, function()
        if CampanasCharDB then CampanasCharDB = nil else CampanasCharDB = Capping.db end
        ReloadUI()
    end), 26)
    Header(c2, "BORRAR DATOS")
    local rc = CdG.WarButton(p, "Borrar estado de la campaña (Mayús)", nil, COL, 26)
    rc.keepWidth = true; rc:SetRed(true)
    Place(c2, rc, 34)
    rc:SetScript("OnClick", function()
        if not IsShiftKeyDown() then return CdG.Print("Mantén pulsado Mayús para confirmar.") end
        cdb().st, cdb().mines = {}, {}
        CdG.Changed(); CdG.Print("Estado de la campaña borrado. Pulsa Sincronizar para recibir el de los demás.")
    end)
    local rs = CdG.WarButton(p, "Restablecer TODO (Mayús + clic)", nil, COL, 26)
    rs.keepWidth = true; rs:SetRed(true)
    Place(c2, rs, 34)
    rs:SetScript("OnClick", function() if IsShiftKeyDown() then CampanasDB = nil; ReloadUI() else CdG.Print("Mantén pulsado Mayús para confirmar.") end end)
    local info = CdG.Text(p, 10, "muted"); info:SetWidth(CW - 12); info:SetJustifyH("LEFT")
    info:SetPoint("TOPLEFT", 6, -120)
    info:SetText("Campañas de Guerra incluye los temporizadores de campos de batalla de Capping (TotalPackage), traducidos e integrados en la nueva interfaz, y un sistema propio de campañas del mundo abierto inspirado en las ideas de Overlord, con código propio para la 3.3.5.\n\nTu rango y tus estadísticas de toda la vida se guardan solo en este ordenador, por personaje.\n\n|cffffcc55Hecho por Don Arequipa - Líder de Comunidad Wargames.|r")
end

-- ---------------------------------------------------------------------------
-- Navegación
-- ---------------------------------------------------------------------------
function ShowPage(key)
    if not Capping.db or not CdG.db then return end
    current = key
    for k, pg in pairs(pages) do if k == key then pg:Show() else pg:Hide() end end
    local pg = pages[key]
    pageTitle:SetText(pg.title); pageDesc:SetText(pg.desc)
    for _, c in ipairs(pg.controls) do if c.Refresh then c:Refresh() end end
    if pg.Refresh then pg:Refresh() end
    for k, b in pairs(nav) do b:SetRed(k == key) end
    crest:SetFaction(CdG.myFK)
    sideName:SetText(CdG.myName or "")
    sideRank:SetText(CdG.char and CdG.RANKS[CdG.char.rank or 1][2] or "")
end

f:SetScript("OnShow", function() ShowPage(current) end)
f:SetScript("OnUpdate", function(self, e)
    self.t = (self.t or 0) + e
    if self.t > 1 then
        self.t = 0
        if (current == "summary" or current == "fronts") and pages[current].Refresh then pages[current]:Refresh() end
    end
end)

function CdG.ToggleCommand()
    if f:IsShown() then f:Hide() else f:Show() end
end
-- abre el mando de control en una sección concreta
function CdG.OpenCommand(key)
    if pages[key] then current = key end
    if f:IsShown() then ShowPage(current) else f:Show() end
end
function CdG.RefreshCommand()
    if f:IsShown() and pages[current] and pages[current].Refresh then pages[current]:Refresh() end
end

-- ---------------------------------------------------------------------------
-- Botón del minimapa
-- ---------------------------------------------------------------------------
local mm = CreateFrame("Button", "CdGMinimapButton", Minimap)
mm:SetWidth(31); mm:SetHeight(31)
mm:SetFrameStrata("MEDIUM"); mm:SetFrameLevel(8)
mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mm:RegisterForDrag("LeftButton")
mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local mmIcon = mm:CreateTexture(nil, "BACKGROUND")
mmIcon:SetTexture("Interface\\Icons\\INV_BannerPVP_02"); mmIcon:SetWidth(20); mmIcon:SetHeight(20)
mmIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92); mmIcon:SetPoint("CENTER", 0, 1)
local mmBorder = mm:CreateTexture(nil, "OVERLAY")
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mmBorder:SetWidth(53); mmBorder:SetHeight(53); mmBorder:SetPoint("TOPLEFT")
local function PlaceMM()
    local a = math.rad((CampanasDB and CampanasDB.mmangle) or 200)
    mm:ClearAllPoints()
    mm:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 80, math.sin(a) * 80)
end
mm:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local s = Minimap:GetEffectiveScale()
        CampanasDB.mmangle = math.deg(math.atan2(cy / s - my, cx / s - mx))
        PlaceMM()
    end)
end)
mm:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
mm:SetScript("OnClick", function(self, button)
    if button == "RightButton" then CdG.ToggleCommand() else CdG.TogglePanel() end
end)
mm:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cffdc3337Campañas de Guerra|r")
    GameTooltip:AddLine("Clic: panel de campaña", 1, 1, 1)
    GameTooltip:AddLine("Clic derecho: mando de control", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Arrastrar: mover el botón", 0.6, 0.6, 0.6)
    if CdG.db then
        local a, h = CdG.Domination()
        GameTooltip:AddLine(format("Dominación: |cff4a8cff%.0f%%|r - |cffff4033%.0f%%|r", a, h), 1, 1, 1)
    end
    GameTooltip:Show()
end)
mm:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ---------------------------------------------------------------------------
-- Comandos
-- ---------------------------------------------------------------------------
local function Status()
    local fr = CdG.current
    if not fr then
        local feat = CdG.Featured()
        return CdG.Print("No estás en ningún frente. Frente destacado de hoy: |cffffcc55" .. feat.name .. "|r.")
    end
    local a, h, n = CdG.FrontScore(fr)
    local obj, dist = CdG.NextObjective(fr)
    CdG.Print(format("%s: |cff4a8cff%d Alianza|r · |cffff4033%d Horda|r · %d puntos.", fr.name, a, h, n))
    if obj then CdG.Print(format("Siguiente objetivo: |cffffcc55%s|r%s", obj.name, dist and format(" (~%d metros)", dist) or "")) end
    local S = CdG.Engine.state
    if S.node then CdG.Print(format("Estás en %s: %s", S.node.name, S.status)) end
end

local function Slash(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local cmd = msg:match("^(%S*)")
    if cmd == "" or cmd == "show" or cmd == "panel" then CdG.TogglePanel()
    elseif cmd == "mando" or cmd == "ajustes" or cmd == "config" or cmd == "opciones" then CdG.ToggleCommand()
    elseif cmd == "lb" or cmd == "clasificacion" or cmd == "clasificación" then CdG.ShowLeaderboard()
    elseif cmd == "guia" or cmd == "guía" or cmd == "guide" then CdG.ShowGuide()
    elseif cmd == "fama" then CdG.ShowFame()
    elseif cmd == "exportar" or cmd == "export" then CdG.ShowExport()
    elseif cmd == "estado" or cmd == "status" then Status()
    elseif cmd == "sync" then CdG.RequestSync(); CdG.Print("Pidiendo el estado de la campaña…")
    elseif cmd == "general" then CdG.ToggleGeneral()
    elseif cmd == "llamada" then CdG.CallToArms()
    elseif cmd == "barras" then Capping:TestBars()
    elseif cmd == "mapa" or cmd == "map" then
        local order = { full = "compact", compact = "hidden", hidden = "full" }
        CdG.db.mapmode = order[CdG.db.mapmode] or "full"
        local names = { full = "completo", compact = "compacto", hidden = "oculto" }
        CdG.Print("Mapa de campaña: " .. names[CdG.db.mapmode] .. ".")
        CdG.UpdateMapPins()
    elseif cmd == "pos" then
        local map, x, y = CdG.PlayerPos()
        if map and x then CdG.Print(format("Mapa |cffffcc55%s|r  x = %.3f  y = %.3f  (%s)", map, x, y, GetSubZoneText() ~= "" and GetSubZoneText() or GetZoneText()))
        else CdG.Print("Sin posición (¿estás en una instancia o con el mapa abierto en otra zona?).") end
    else
        CdG.Print("Comandos: |cffffcc55/campanas|r [mando | lb | guia | fama | estado | mapa | sync | general | llamada | barras | pos | exportar]")
    end
end

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
    PlaceMM()
    SlashCmdList.CAPPING = Slash
    SLASH_CAPPING1, SLASH_CAPPING2, SLASH_CAPPING3 = "/campanas", "/cdg", "/capping"
    SlashCmdList.CDGCAMPANAS = Slash
    SLASH_CDGCAMPANAS1 = "/ov"
    CdG.DockUpdate()
end)
