-- ============================================================================
-- Campañas de Guerra - Clasificación, Salón de la Fama, Guía y Exportar
-- ============================================================================
local CdG = CdG
local C, rgba = CdG.C, CdG.rgba
local MEDIA = CdG.MEDIA

local RACE_TC = {
    Human = { 0, 0.125, 0, 0.25 }, Dwarf = { 0.125, 0.25, 0, 0.25 }, Gnome = { 0.25, 0.375, 0, 0.25 },
    NightElf = { 0.375, 0.5, 0, 0.25 }, Draenei = { 0.5, 0.625, 0, 0.25 },
    Tauren = { 0, 0.125, 0.25, 0.5 }, Scourge = { 0.125, 0.25, 0.25, 0.5 }, Troll = { 0.25, 0.375, 0.25, 0.5 },
    Orc = { 0.375, 0.5, 0.25, 0.5 }, BloodElf = { 0.5, 0.625, 0.25, 0.5 },
}
local function RaceIcon(tex, race, sex)
    local tc = RACE_TC[race or ""]
    if not tc then tex:Hide() return end
    local off = (sex == 3) and 0.5 or 0
    tex:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races")
    tex:SetTexCoord(tc[1], tc[2], tc[3] + off, tc[4] + off)
    tex:Show()
end
local function ClassIcon(tex, class)
    local tc = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if not tc then tex:Hide() return end
    tex:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
    tex:Show()
end
local function ClassColor(class, f)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return rgba(CdG.FactionColor(f))
end
local function Trunc(s, n) s = s or ""; if #s > n then return s:sub(1, n - 1) .. "…" end return s end

-- ---------------------------------------------------------------------------
-- Clasificación
-- ---------------------------------------------------------------------------
local LW, LH = 1180, 600
local L = CdG.Window("CdGLeaderboard", LW, LH, "Clasificación")
L.title:SetFont(CdG.TITLE_FONT, 30)
L.sub = CdG.Text(L, 11, "muted"); L.sub:SetPoint("TOP", L.title, "BOTTOM", 0, -2)

local search = CreateFrame("EditBox", "CdGLeaderboardSearch", L, "InputBoxTemplate")
search:SetWidth(180); search:SetHeight(20); search:SetPoint("TOPLEFT", 30, -26); search:SetAutoFocus(false)
local sLabel = CdG.Text(L, 10, "muted"); sLabel:SetPoint("BOTTOMLEFT", search, "TOPLEFT", -4, 2); sLabel:SetText("Buscar jugador u hermandad")
search:SetScript("OnTextChanged", function() if L:IsShown() then L:Refresh() end end)
search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
local lastWeek = CdG.WarButton(L, "Semana pasada", nil, 120, 22); lastWeek:SetPoint("TOPRIGHT", -46, -14)
lastWeek:SetScript("OnClick", function() CdG.ShowFame() end)

local function Column(x, w, titles)
    local f = CreateFrame("Frame", nil, L); CdG.Inset(f)
    f:SetPoint("TOPLEFT", x, -80); f:SetWidth(w); f:SetHeight(LH - 100)
    f.head = {}
    for _, t in ipairs(titles) do
        local fs = CdG.Text(f, 11, "gold"); fs:SetPoint("TOPLEFT", t[2], -8); fs:SetText(t[1])
        if t[3] then fs:SetWidth(t[3]); fs:SetJustifyH("CENTER") end
        table.insert(f.head, fs)
    end
    local line = f:CreateTexture(nil, "ARTWORK"); line:SetTexture(CdG.FLAT); line:SetHeight(1)
    line:SetPoint("TOPLEFT", 6, -26); line:SetPoint("TOPRIGHT", -6, -26); line:SetVertexColor(C.goldDark[1], C.goldDark[2], C.goldDark[3], 0.6)
    f.rows = {}
    return f
end
local function Row(col, i, h, y0)
    local r = CreateFrame("Frame", nil, col); r:SetHeight(h)
    r:SetPoint("TOPLEFT", 6, -(y0 or 30) - (i - 1) * h); r:SetPoint("TOPRIGHT", -6, -(y0 or 30) - (i - 1) * h)
    r.bg = r:CreateTexture(nil, "BACKGROUND"); r.bg:SetTexture(CdG.FLAT); r.bg:SetAllPoints()
    r.bg:SetVertexColor(1, 1, 1, i % 2 == 0 and 0.03 or 0)
    return r
end

-- jugadores (bajas) + capturas por facción
local colP = Column(14, 340, { { "#", 8 }, { "Raza", 30 }, { "Clase", 64 }, { "Jugador", 110, 150 }, { "Bajas", 285 } })
for i = 1, 10 do
    local r = Row(colP, i, 24)
    r.pos = CdG.Text(r, 12); r.pos:SetPoint("LEFT", 4, 0)
    r.race = r:CreateTexture(nil, "ARTWORK"); r.race:SetWidth(20); r.race:SetHeight(20); r.race:SetPoint("LEFT", 32, 0)
    r.class = r:CreateTexture(nil, "ARTWORK"); r.class:SetWidth(20); r.class:SetHeight(20); r.class:SetPoint("LEFT", 64, 0)
    r.name = CdG.Text(r, 12); r.name:SetPoint("LEFT", 100, 0); r.name:SetWidth(170)
    r.val = CdG.Text(r, 12); r.val:SetPoint("RIGHT", -18, 0)
    colP.rows[i] = r
end
local capA, capH = {}, {}
local capHdrA = CdG.Text(colP, 11, "gold"); capHdrA:SetPoint("TOPLEFT", 40, -282); capHdrA:SetText("Alianza · Capturas")
local capHdrH = CdG.Text(colP, 11, "gold"); capHdrH:SetPoint("TOPLEFT", 210, -282); capHdrH:SetText("Horda · Capturas")
for i = 1, 9 do
    for side, list in pairs({ A = capA, H = capH }) do
        local r = CreateFrame("Frame", nil, colP); r:SetHeight(21); r:SetWidth(160)
        r:SetPoint("TOPLEFT", side == "A" and 8 or 176, -300 - (i - 1) * 21)
        r.class = r:CreateTexture(nil, "ARTWORK"); r.class:SetWidth(18); r.class:SetHeight(18); r.class:SetPoint("LEFT")
        r.name = CdG.Text(r, 11); r.name:SetPoint("LEFT", 22, 0)
        r.val = CdG.Text(r, 11, "gold"); r.val:SetPoint("RIGHT", -4, 0)
        list[i] = r
    end
end

local colG = Column(362, 250, { { "#", 8 }, { "Hermandad", 40, 150 }, { "Puntos", 190 } })
for i = 1, 20 do
    local r = Row(colG, i, 23.5)
    r.pos = CdG.Text(r, 12); r.pos:SetPoint("LEFT", 4, 0)
    r.name = CdG.Text(r, 12); r.name:SetPoint("LEFT", 30, 0); r.name:SetWidth(160)
    r.val = CdG.Text(r, 12); r.val:SetPoint("RIGHT", -10, 0)
    colG.rows[i] = r
end

local function ObjColumn(x, w, t1, t3)
    local col = Column(x, w, { { t1, 40 }, { "Hermandad", 150, 120 }, { t3, w - 70 } })
    for i = 1, 20 do
        local r = Row(col, i, 23.5)
        r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetWidth(18); r.icon:SetHeight(18); r.icon:SetPoint("LEFT", 4, 0)
        r.name = CdG.Text(r, 11); r.name:SetPoint("LEFT", 26, 0); r.name:SetWidth(120); r.name:SetJustifyH("LEFT")
        r.guild = CdG.Text(r, 11); r.guild:SetPoint("LEFT", 146, 0); r.guild:SetWidth(130)
        r.val = CdG.Text(r, 11); r.val:SetPoint("RIGHT", -12, 0)
        col.rows[i] = r
    end
    return col
end
local colK = ObjColumn(620, 270, "Fortaleza", "Victorias")
local colO = ObjColumn(898, 268, "Avanzada", "Capturas")

local function Match(q, ...)
    if q == "" then return true end
    for i = 1, select("#", ...) do
        local s = select(i, ...)
        if s and s:lower():find(q, 1, true) then return true end
    end
end

function L:Refresh()
    local db = CdG.db
    local q = (search:GetText() or ""):lower()
    local ws = CdG.WeekStart(db.board.week)
    self.sub:SetText(format("Campaña del %s al %s  ·  la Fama se reinicia los miércoles", date("%d/%m/%Y", ws), date("%d/%m/%Y", ws + 6 * 86400)))
    local players = {}
    for name, e in pairs(db.board.players) do
        if Match(q, name, e.g) then table.insert(players, { name = name, e = e }) end
    end
    table.sort(players, function(a, b) return (a.e.k or 0) > (b.e.k or 0) end)
    for i, r in ipairs(colP.rows) do
        local p = players[i]
        if p and (p.e.k or 0) > 0 then
            r.pos:SetText(i); r.pos:SetTextColor(rgba(i <= 3 and C.gold or C.text))
            RaceIcon(r.race, p.e.r, p.e.x); ClassIcon(r.class, p.e.cl)
            r.name:SetText(p.name .. ((p.e.rk or 1) >= 11 and " |cffffcc55*|r" or "")); r.name:SetTextColor(ClassColor(p.e.cl, p.e.f))
            r.val:SetText(p.e.k); r.val:SetTextColor(rgba(i <= 3 and C.gold or C.text))
            r:Show()
        elseif i == 1 then
            r.pos:SetText(""); r.race:Hide(); r.class:Hide(); r.val:SetText("")
            r.name:SetText("|cff888888Nadie ha abatido a nadie esta semana|r"); r:Show()
        else r:Hide() end
    end
    for _, side in ipairs({ "A", "H" }) do
        local list = {}
        for _, p in ipairs(players) do if p.e.f == side and (p.e.c or 0) > 0 then table.insert(list, p) end end
        table.sort(list, function(a, b) return (a.e.c or 0) > (b.e.c or 0) end)
        for i, r in ipairs(side == "A" and capA or capH) do
            local p = list[i]
            if p then
                ClassIcon(r.class, p.e.cl)
                r.name:SetText(Trunc(p.name, 12)); r.name:SetTextColor(ClassColor(p.e.cl, p.e.f))
                r.val:SetText(p.e.c); r:Show()
            else r:Hide() end
        end
    end
    local guilds = {}
    for _, g in ipairs(CdG.GuildRanking()) do if Match(q, g.name) then table.insert(guilds, g) end end
    for i, r in ipairs(colG.rows) do
        local g = guilds[i]
        if g then
            r.pos:SetText(i); r.name:SetText(Trunc(g.name, 22)); r.name:SetTextColor(rgba(CdG.FactionColor(g.f)))
            r.val:SetText(g.score); r:Show()
            r:EnableMouse(true)
            r:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine("<" .. g.name .. ">", 1, 0.82, 0.3)
                GameTooltip:AddLine(format("%d bajas · %d capturas (x5)", g.k, g.c), 1, 1, 1); GameTooltip:Show()
            end)
            r:SetScript("OnLeave", function() GameTooltip:Hide() end)
        elseif i == 1 then
            r.pos:SetText(""); r.val:SetText(""); r.name:SetText("|cff888888Sin hermandades todavía|r"); r:Show()
        else r:Hide() end
    end
    for _, spec in ipairs({ { colK, db.board.keeps, "keep" }, { colO, db.board.outposts, "tower" } }) do
        local col, tbl, icon = spec[1], spec[2], spec[3]
        local list = {}
        for _, e in pairs(tbl) do
            local n = CdG.NODES[e.id]
            if n and Match(q, e.g, n.name) then table.insert(list, { n = n, e = e }) end
        end
        table.sort(list, function(a, b) return a.e.n > b.e.n end)
        for i, r in ipairs(col.rows) do
            local it = list[i]
            if it then
                local _, _, _, curG = CdG.GetOwner(it.n.id)
                local holds = curG == it.e.g
                r.icon:SetTexture(MEDIA .. icon); r.icon:SetVertexColor(rgba(CdG.FactionColor(it.e.f)))
                if holds then r.icon:Show() else r.icon:Hide() end
                r.name:SetText(Trunc(it.n.name, 18)); r.name:SetTextColor(rgba(holds and C.text or C.muted))
                r.guild:SetText(Trunc(it.e.g, 20)); r.guild:SetTextColor(rgba(CdG.FactionColor(it.e.f)))
                r.val:SetText(it.e.n); r:Show()
            elseif i == 1 then
                r.icon:Hide(); r.guild:SetText(""); r.val:SetText("")
                r.name:SetText("|cff888888Nadie todavía|r"); r:Show()
            else r:Hide() end
        end
    end
end
L:SetScript("OnShow", function(self) self:Refresh() end)
CdG.OnChange(function() if L:IsShown() and not L.throttle then L.throttle = true; L:Refresh() end end)
L:SetScript("OnUpdate", function(self, e) self.acc = (self.acc or 0) + e; if self.acc > 2 then self.acc = 0; self.throttle = nil end end)

function CdG.ShowLeaderboard() if L:IsShown() then L:Hide() else L:Show() end end

-- ---------------------------------------------------------------------------
-- Salón de la Fama y hoja de servicio
-- ---------------------------------------------------------------------------
local F = CdG.Window("CdGFame", 640, 470, "Salón de la Fama")
local sheet = CreateFrame("Frame", nil, F); CdG.Inset(sheet)
sheet:SetPoint("TOPLEFT", 16, -52); sheet:SetWidth(250); sheet:SetHeight(400)
local shHdr = CdG.Header(sheet, "HOJA DE SERVICIO"); shHdr:SetPoint("TOPLEFT", 4, -8); shHdr:SetPoint("TOPRIGHT", -4, -8)
local shRank = CdG.Title(sheet, 18); shRank:SetPoint("TOP", 0, -30)
local shBadge = CdG.Crest(sheet, 54); shBadge:SetPoint("TOP", shRank, "BOTTOM", 0, -6)
local shBar = CdG.Progress(sheet, 12); shBar:SetPoint("TOPLEFT", 16, -126); shBar:SetPoint("TOPRIGHT", -16, -126)
local shText = CdG.Text(sheet, 11); shText:SetPoint("TOPLEFT", 16, -148); shText:SetWidth(220); shText:SetJustifyH("LEFT")
local weeks = CreateFrame("Frame", nil, F); CdG.Inset(weeks)
weeks:SetPoint("TOPLEFT", sheet, "TOPRIGHT", 8, 0); weeks:SetPoint("BOTTOMRIGHT", -16, 18)
local wkHdr = CdG.Header(weeks, "CAMPEONES DE CADA SEMANA"); wkHdr:SetPoint("TOPLEFT", 4, -8); wkHdr:SetPoint("TOPRIGHT", -4, -8)
local wkRows = {}
for i = 1, 6 do
    local r = CreateFrame("Frame", nil, weeks); r:SetHeight(58)
    r:SetPoint("TOPLEFT", 8, -28 - (i - 1) * 60); r:SetPoint("TOPRIGHT", -8, -28 - (i - 1) * 60)
    r.bg = r:CreateTexture(nil, "BACKGROUND"); r.bg:SetTexture(CdG.FLAT); r.bg:SetAllPoints(); r.bg:SetVertexColor(1, 1, 1, 0.03)
    r.t = CdG.Text(r, 11, "gold"); r.t:SetPoint("TOPLEFT", 6, -4)
    r.d = CdG.Text(r, 10); r.d:SetPoint("TOPLEFT", 6, -20); r.d:SetWidth(330); r.d:SetJustifyH("LEFT")
    wkRows[i] = r
end
local wkEmpty = CdG.Text(weeks, 11, "muted"); wkEmpty:SetPoint("CENTER"); wkEmpty:SetWidth(300)
wkEmpty:SetText("Aún no ha terminado ninguna campaña. Los campeones de cada semana aparecerán aquí tras el reinicio del miércoles.")

local function FC(f, s) return "|cff" .. (f == "A" and "4a8cff" or (f == "H" and "ff4033" or "dddddd")) .. (s or "?") .. "|r" end
F:SetScript("OnShow", function()
    local ch = CdG.char
    local idx, name, nextAt = CdG.RankFor(ch.glory or 0)
    local rk = ch.rank or 1
    shRank:SetText(format("Rango %d · %s", rk, CdG.RANKS[rk][2]))
    shBadge:SetFaction(CdG.myFK)
    local cur = CdG.RANKS[idx][1]
    if nextAt then
        shBar:SetValue(((ch.glory or 0) - cur) / (nextAt - cur), C.gold)
        shBar.text:SetText(format("%d / %d de gloria", ch.glory or 0, nextAt))
    else shBar:SetValue(1, C.gold); shBar.text:SetText("Rango máximo") end
    local e = CdG.db.board.players[CdG.myName] or {}
    shText:SetText(format(
        "|cffffcc55Toda la vida|r\nBajas: %d\nCapturas: %d\nDefensas: %d\nFortalezas tomadas: %d\nAvanzadas tomadas: %d\nMejor racha: %d\nMuertes: %d\n\n|cffffcc55Esta semana|r\nBajas: %d\nCapturas: %d\n\n|cff888888El rango se guarda solo en este ordenador y nunca baja. Desde el rango 11 los demás lo ven en tu ficha.|r",
        ch.kills, ch.captures, ch.defends, ch.keeps, ch.outposts, ch.best, ch.deaths, e.k or 0, e.c or 0))
    local fame = CdG.db.fame
    for i, r in ipairs(wkRows) do
        local w = fame[i]
        if w then
            local ws = CdG.WeekStart(w.week)
            r.t:SetText(format("Semana del %s  ·  Dominación %d%% - %d%%", date("%d/%m", ws), w.domA or 50, w.domH or 50))
            r.d:SetText(format("Cazador: %s (%d bajas)\nConquistador: %s (%d capturas)\nHermandad: %s (%d puntos)",
                FC(w.pf, w.player or "—"), w.kills or 0, FC(w.cf, w.capturer or "—"), w.caps or 0, FC(w.gf, w.guild and ("<" .. w.guild .. ">") or "—"), w.gscore or 0))
            r:Show()
        else r:Hide() end
    end
    if fame[1] then wkEmpty:Hide() else wkEmpty:Show() end
end)
function CdG.ShowFame() if F:IsShown() then F:Hide() else F:Show() end end

-- ---------------------------------------------------------------------------
-- Guía
-- ---------------------------------------------------------------------------
local GUIDE = {
    { "Bienvenido a la guerra", "Campañas de Guerra convierte el mundo abierto en un campo de batalla persistente.\n\nCada zona de exterior de la 3.3.5 es un |cffffcc55frente|r: un camino de puntos de captura entre dos capitales, una de la Alianza y otra de la Horda. Toma un punto y los siguientes se abren.\n\nTodo lo que hagas se comparte al instante con los demás jugadores que llevan el addon, de las dos facciones.\n\n|cffffcc55Hecho por Don Arequipa - Líder de Comunidad Wargames.|r" },
    { "Capturar", "Activa el JcJ (|cffffcc55/pvp|r), desmonta y quédate dentro del círculo.\n\n· Punto normal: 2 min.  · Capital: 8 min.\n· Fortaleza de hermandad: 10 min.  · Avanzada: 5 min.\n\nMás aliados que enemigos: la barra avanza (hasta un 50% más rápido). Iguales: se congela. Más enemigos: retrocede. Si sales del círculo, el progreso decae poco a poco.\n\nSolo puedes atacar un punto |cffffcc55conectado|r a otro de tu facción. Tu capital siempre puedes recuperarla." },
    { "Ganar un frente", "La capital rival queda al final del camino. Tómala y ganas el frente: suma mucha dominación semanal para tu facción.\n\nLo conquistado sigue siendo tuyo, capital incluida, hasta que el otro bando lo recupere o llegue el reinicio del miércoles." },
    { "Fortalezas y avanzadas", "Cinco |cffffcc55fortalezas|r están siempre abiertas (Sierra Espolón, Los Humedales, Tierras Inhóspitas, Los Baldíos y Mulgore). Mantén una 10 minutos y pertenece a tu hermandad hasta que el enemigo la tome o acabe la semana.\n\nCada frente tiene además una |cffffcc55avanzada|r (5 min). Si tu facción controla la avanzada de un frente, el enemigo tarda 30 s más en cada punto normal de ese frente." },
    { "Monedas y madera", "|cffffcc55Monedas de guerra|r: quédate dentro de una mina (amarilla en el mapa) para ganar 1 cada 20 s mientras queden reservas. Minar mineral allí da +2. Cada baja da +1.\n\n· |cffffcc55Atacar (25)|r: tu próxima captura es 1 min más corta.\n· |cffffcc55Reforzar (25)|r: la próxima captura enemiga en tu punto tardará 1 min más (máx. 3).\n\n|cffffcc55Madera|r: quédate en un aserradero (verde). Con 500 puedes donar +1% de dominación semanal a tu facción." },
    { "Frente destacado y actividad", "Cada día hay un |cffffcc55frente destacado|r: las bajas allí cuentan doble en la clasificación y dan una moneda extra.\n\nLa tarjeta lateral muestra la actividad de los últimos 5 minutos en cada frente: ve a buscar la pelea en lugar de esperarla." },
    { "General y llamada a las armas", "Un líder de grupo o banda puede |cffffcc55tomar el mando|r y ser el General de su facción en un frente. Aparece en el mapa para los aliados. Si cae, todos se enteran.\n\nLa |cffffcc55llamada a las armas|r envía un aviso de banda a todos los jugadores de tu facción con el addon. La facción entera comparte una llamada cada 4 horas." },
    { "Recompensas y némesis", "Encadena |cffffcc5510 bajas sin morir|r y te conviertes en una recompensa: el enemigo te verá en el mapa, y quien te abata gana bajas y monedas extra.\n\nLos cinco mejores cazadores enemigos de la semana son tu |cffff3333Némesis|r: llevan una calavera en su ficha y el chat te avisa cuando aparece uno cerca." },
    { "Clasificación y rangos", "Cuenta cada muerte honorable en el mundo abierto, en cualquier nivel. Los campos de batalla, arenas, mazmorras y bandas no cuentan.\n\nLa clasificación muestra jugadores, hermandades (bajas + capturas x5), fortalezas y avanzadas. Cada miércoles empieza una campaña nueva y los campeones pasan al Salón de la Fama.\n\nTu |cffffcc55rango|r (15 niveles) se gana con gloria y sobrevive al reinicio." },
    { "Comandos", "|cffffcc55/campanas|r  panel principal\n|cffffcc55/campanas mando|r  mando de control (configuración)\n|cffffcc55/campanas lb|r  clasificación\n|cffffcc55/campanas guia|r  esta guía\n|cffffcc55/campanas estado|r  estado del frente actual\n|cffffcc55/campanas mapa|r  mapa completo, compacto u oculto\n|cffffcc55/campanas sync|r  pedir el estado a otros jugadores\n|cffffcc55/campanas general|r  tomar o dejar el mando\n|cffffcc55/campanas llamada|r  llamada a las armas\n|cffffcc55/campanas pos|r  tus coordenadas exactas (para corregir puntos)\n|cffffcc55/campanas exportar|r  exportar estadísticas" },
}
local G = CdG.Window("CdGGuide", 520, 400, "Guía de campaña")
local gTitle = CdG.Title(G, 18, "text"); gTitle:SetPoint("TOP", 0, -56)
local gBody = CdG.Text(G, 12); gBody:SetPoint("TOPLEFT", 30, -86); gBody:SetWidth(460); gBody:SetJustifyH("LEFT"); gBody:SetJustifyV("TOP"); gBody:SetSpacing(3)
local gPage = CdG.Text(G, 10, "muted"); gPage:SetPoint("BOTTOM", 0, 24)
local gPrev = CdG.WarButton(G, "< Anterior", nil, 110, 24); gPrev:SetPoint("BOTTOMLEFT", 20, 18)
local gNext = CdG.WarButton(G, "Siguiente >", nil, 110, 24); gNext:SetPoint("BOTTOMRIGHT", -20, 18)
G.page = 1
local function ShowGuidePage()
    local p = GUIDE[G.page]
    gTitle:SetText(p[1]); gBody:SetText(p[2]); gPage:SetText(format("%d / %d", G.page, #GUIDE))
end
gPrev:SetScript("OnClick", function() G.page = (G.page - 2) % #GUIDE + 1; ShowGuidePage() end)
gNext:SetScript("OnClick", function() G.page = G.page % #GUIDE + 1; ShowGuidePage() end)
G:SetScript("OnShow", ShowGuidePage)
function CdG.ShowGuide() if G:IsShown() then G:Hide() else G:Show() end end

-- ---------------------------------------------------------------------------
-- Exportar
-- ---------------------------------------------------------------------------
local X = CdG.Window("CdGExport", 460, 320, "Exportar estadísticas")
local xHint = CdG.Text(X, 10, "muted"); xHint:SetPoint("TOP", 0, -50); xHint:SetText("Ctrl+A para seleccionar todo y Ctrl+C para copiar")
local xBox = CreateFrame("Frame", nil, X); CdG.Inset(xBox); xBox:SetPoint("TOPLEFT", 18, -68); xBox:SetPoint("BOTTOMRIGHT", -18, 18)
local xEdit = CreateFrame("EditBox", nil, xBox)
xEdit:SetMultiLine(true); xEdit:SetAutoFocus(true); xEdit:SetFontObject(ChatFontNormal)
xEdit:SetPoint("TOPLEFT", 8, -8); xEdit:SetPoint("BOTTOMRIGHT", -8, 8); xEdit:SetWidth(400)
xEdit:SetScript("OnEscapePressed", function() X:Hide() end)
X:SetScript("OnShow", function()
    local ch, e = CdG.char, CdG.db.board.players[CdG.myName] or {}
    local a, h = CdG.Domination()
    local txt = format("Campañas de Guerra · %s (%s)\nRango %d: %s · Gloria %d\nToda la vida: %d bajas, %d capturas, %d defensas, %d fortalezas, %d avanzadas, mejor racha %d\nEsta semana: %d bajas, %d capturas\nDominación semanal: Alianza %.1f%% · Horda %.1f%%",
        CdG.myName, CdG.FactionName(CdG.myFK), ch.rank or 1, CdG.RANKS[ch.rank or 1][2], ch.glory or 0,
        ch.kills, ch.captures, ch.defends, ch.keeps, ch.outposts, ch.best, e.k or 0, e.c or 0, a, h)
    xEdit:SetText(txt); xEdit:HighlightText(); xEdit:SetFocus()
end)
function CdG.ShowExport() if X:IsShown() then X:Hide() else X:Show() end end
