-- ============================================================================
-- Campañas de Guerra - Panel principal y tarjeta de objetivo
-- ============================================================================
local CdG = CdG
local C, rgba = CdG.C, CdG.rgba
local MEDIA = CdG.MEDIA

local PW, PH = 330, 600       -- panel principal
local CW, CH = 256, 600       -- tarjeta lateral
local selectedFront           -- frente elegido en el selector (si no estás en ninguno)

local function db() return CdG.db end

-- ---------------------------------------------------------------------------
-- Imagen de la zona: las 12 losetas del mapa del mundo, recortadas a 1002x668
-- ---------------------------------------------------------------------------
function CdG.ZoneImage(parent, w, h)
    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(w); f:SetHeight(h)
    f.tiles = {}
    local tw, th = w * 256 / 1002, h * 256 / 668
    for row = 0, 2 do
        for col = 0, 3 do
            local t = f:CreateTexture(nil, "ARTWORK")
            local cw = col == 3 and (1002 - 768) / 256 or 1
            local ch = row == 2 and (668 - 512) / 256 or 1
            t:SetWidth(tw * cw); t:SetHeight(th * ch)
            t:SetPoint("TOPLEFT", col * tw, -row * th)
            t:SetTexCoord(0, cw, 0, ch)
            table.insert(f.tiles, t)
        end
    end
    f.dots = {}
    function f:SetMap(map)
        if self.map == map then return end
        self.map = map
        for i, t in ipairs(self.tiles) do t:SetTexture("Interface\\WorldMap\\" .. map .. "\\" .. map .. i) end
    end
    function f:Dot(i)
        local d = self.dots[i]
        if not d then
            d = self:CreateTexture(nil, "OVERLAY"); d:SetTexture(MEDIA .. "dot")
            self.dots[i] = d
        end
        return d
    end
    function f:ClearDots() for _, d in ipairs(self.dots) do d:Hide() end end
    return f
end

-- ---------------------------------------------------------------------------
-- Panel principal
-- ---------------------------------------------------------------------------
local P = CreateFrame("Frame", "CdGPanel", UIParent)
CdG.Panel = P
P:SetWidth(PW); P:SetHeight(PH)
P:SetPoint("RIGHT", UIParent, "RIGHT", -40, 40)
P:SetFrameStrata("HIGH")
P:SetToplevel(true); P:SetClampedToScreen(true)
P:SetMovable(true); P:EnableMouse(true)
P:RegisterForDrag("LeftButton")
-- se puede mover siempre; junto al mapa guarda una posición aparte
P:SetScript("OnDragStart", function(self) self:StartMoving() end)
P:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    if self.docked then db().mappos = { p, rp, x, y } else db().panelpos = { p, rp, x, y } end
end)
CdG.Ornate(P)
P:Hide()
table.insert(UISpecialFrames, "CdGPanel")

-- cabecera: banderolas y emblema
local drapeA = CdG.Drape(P, 120, 26, C.alliance); drapeA:SetPoint("TOPLEFT", 10, -8)
local drapeH = CdG.Drape(P, 120, 26, C.horde); drapeH:SetPoint("TOPRIGHT", -10, -8)
local emblem = CreateFrame("Frame", nil, P); emblem:SetWidth(54); emblem:SetHeight(54)
emblem:SetPoint("TOP", 0, 22)
emblem.bg = emblem:CreateTexture(nil, "BACKGROUND"); emblem.bg:SetTexture(MEDIA .. "circle"); emblem.bg:SetAllPoints()
emblem.bg:SetVertexColor(0.12, 0.09, 0.05, 1)
emblem.icon = emblem:CreateTexture(nil, "ARTWORK"); emblem.icon:SetTexture(MEDIA .. "swords")
emblem.icon:SetPoint("TOPLEFT", 9, -9); emblem.icon:SetPoint("BOTTOMRIGHT", -9, 9); emblem.icon:SetVertexColor(rgba(C.gold))
emblem.ring = emblem:CreateTexture(nil, "OVERLAY"); emblem.ring:SetTexture(MEDIA .. "ring"); emblem.ring:SetAllPoints()
emblem.ring:SetVertexColor(rgba(C.gold))

local close = CdG.WarButton(P, "X", nil, 24, 22); close:SetPoint("TOPRIGHT", -12, -38)
close:SetScript("OnClick", function() P:Hide() end)

-- red
local net = CreateFrame("Frame", nil, P); net:SetWidth(90); net:SetHeight(14); net:SetPoint("TOPLEFT", 16, -40)
net.dot = net:CreateTexture(nil, "ARTWORK"); net.dot:SetTexture(MEDIA .. "dot"); net.dot:SetWidth(10); net.dot:SetHeight(10); net.dot:SetPoint("LEFT")
net.text = CdG.Text(net, 9, "muted"); net.text:SetPoint("LEFT", net.dot, "RIGHT", 4, 0)
net:EnableMouse(true)
net:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddLine("Red de Campañas de Guerra", 1, 0.82, 0.3)
    GameTooltip:AddLine(format("%d jugadores con el addon en los últimos 10 min.", CdG.Peers()), 1, 1, 1, true)
    GameTooltip:AddLine(CdG.SyncChannelId() and "Canal oculto conectado." or "Canal oculto sin conectar (solo hermandad y grupo).", 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end)
net:SetScript("OnLeave", function() GameTooltip:Hide() end)

local title = CdG.Title(P, 21); title:SetPoint("TOP", 0, -40); title:SetText("Campañas de Guerra")
local version = CdG.Text(P, 9, "muted"); version:SetPoint("TOP", title, "BOTTOM", 0, -1)
version:SetText("v" .. (GetAddOnMetadata("CampanasDeGuerra", "Version") or "?") .. "  ·  /campanas")

-- selector de frente
local selBtn = CdG.WarButton(P, "Frente", "Interface\\Icons\\INV_Misc_Map_01", 118, 26)
selBtn:SetPoint("TOPLEFT", 16, -82)
selBtn.arrow = CdG.Text(selBtn, 10, "gold"); selBtn.arrow:SetPoint("RIGHT", -6, 0); selBtn.arrow:SetText(">")
selBtn.label:SetPoint("RIGHT", -16, 0)

-- retratos
local function Portrait(parent)
    local f = CreateFrame("Frame", nil, parent); f:SetWidth(44); f:SetHeight(44)
    f.tex = f:CreateTexture(nil, "ARTWORK"); f.tex:SetPoint("TOPLEFT", 3, -3); f.tex:SetPoint("BOTTOMRIGHT", -3, 3)
    f.ring = f:CreateTexture(nil, "OVERLAY"); f.ring:SetTexture(MEDIA .. "ring"); f.ring:SetAllPoints()
    return f
end
local portA, portH = Portrait(P), Portrait(P)
portA:SetPoint("TOPLEFT", 160, -74); portH:SetPoint("LEFT", portA, "RIGHT", 10, 0)
portA.ring:SetVertexColor(rgba(C.alliance)); portH.ring:SetVertexColor(rgba(C.horde))
local nearby = CdG.Text(P, 10); nearby:SetPoint("TOP", portA, "BOTTOM", 27, -2)

-- dominación
local domLabel = CdG.Text(P, 10, "gold"); domLabel:SetPoint("TOP", 0, -138); domLabel:SetText("Dominación territorial semanal")
local dom = CdG.Progress(P, 14); dom:SetPoint("TOPLEFT", 16, -152); dom:SetPoint("TOPRIGHT", -16, -152)

-- zonas de control
local zonesBox = CreateFrame("Frame", nil, P); CdG.Inset(zonesBox)
zonesBox:SetPoint("TOPLEFT", 12, -172); zonesBox:SetPoint("TOPRIGHT", -12, -172); zonesBox:SetHeight(174)
local zonesHdr = CdG.Header(zonesBox, "ZONAS DE CONTROL"); zonesHdr:SetPoint("TOPLEFT", 4, -6); zonesHdr:SetPoint("TOPRIGHT", -4, -6)
local cells = {}
local CELLW = (PW - 24 - 12) / 2
for i = 1, 14 do
    local c = CreateFrame("Button", nil, zonesBox)
    c:SetWidth(CELLW); c:SetHeight(21)
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    c:SetPoint("TOPLEFT", 6 + col * CELLW, -22 - row * 21)
    c.icon = c:CreateTexture(nil, "ARTWORK"); c.icon:SetWidth(14); c.icon:SetHeight(14); c.icon:SetPoint("LEFT", 2, 0)
    c.name = CdG.Text(c, 10); c.name:SetPoint("LEFT", c.icon, "RIGHT", 3, 0); c.name:SetJustifyH("LEFT")
    c.state = CdG.Text(c, 8, "muted"); c.state:SetPoint("RIGHT", -3, 0); c.state:SetJustifyH("RIGHT")
    c.name:SetPoint("RIGHT", c.state, "LEFT", -2, 0)
    c.bar = CdG.Progress(c, 4); c.bar:SetPoint("BOTTOMLEFT", 20, 0); c.bar:SetPoint("BOTTOMRIGHT", -3, 0); c.bar:Hide()
    c.hl = c:CreateTexture(nil, "HIGHLIGHT"); c.hl:SetTexture(CdG.FLAT); c.hl:SetAllPoints(); c.hl:SetVertexColor(1, 0.85, 0.4, 0.08)
    c:SetScript("OnEnter", function(self)
        if not self.node then return end
        local n = self.node
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(n.name, 1, 0.82, 0.3)
        GameTooltip:AddLine(CdG.KIND[n.kind].label .. (n.front and (" · " .. n.front.name) or ""), 0.8, 0.8, 0.8)
        local o, t, who, g = CdG.GetOwner(n.id)
        if o then
            local col = CdG.FactionColor(o)
            GameTooltip:AddLine("Controlado por la " .. CdG.FactionName(o), col[1], col[2], col[3])
            if who then GameTooltip:AddLine(format("%s%s · %s", who, g and (" <" .. g .. ">") or "", CdG.Ago(t)), 0.7, 0.7, 0.7) end
        else
            GameTooltip:AddLine("Neutral", 0.7, 0.7, 0.7)
        end
        if CdG.WAR[n.kind] then
            local rf = CdG.Reinforcements(n.id)
            if rf > 0 then GameTooltip:AddLine(format("Reforzado: +%d min para el atacante", rf), 0.4, 0.8, 1) end
            if CdG.CanAttack(n, CdG.myFK) then
                GameTooltip:AddLine(format("¡Puedes atacarlo! Captura: %s", CdG.Clock(CdG.CaptureTime(n, CdG.myFK, true))), 0.3, 1, 0.3)
            elseif o ~= CdG.myFK then
                GameTooltip:AddLine("Bloqueado: necesitas un punto conectado", 0.6, 0.6, 0.6)
            end
        end
        if self.bgbar then GameTooltip:ClearLines(); GameTooltip:AddLine(self.bgbar, 1, 0.82, 0.3) end
        GameTooltip:Show()
    end)
    c:SetScript("OnLeave", function() GameTooltip:Hide() end)
    c:SetScript("OnClick", function(self)
        if self.node and self.node.map then
            ShowUIPanel(WorldMapFrame)
            if CdG.ShowMapFor then CdG.ShowMapFor(self.node.map) end
        end
    end)
    cells[i] = c
end
local zonesEmpty = CdG.Text(zonesBox, 10, "muted"); zonesEmpty:SetPoint("CENTER", 0, -6); zonesEmpty:SetWidth(PW - 60)

-- zona activa
local active = CreateFrame("Frame", nil, P); CdG.Inset(active)
active:SetPoint("TOPLEFT", zonesBox, "BOTTOMLEFT", 0, -6); active:SetPoint("TOPRIGHT", zonesBox, "BOTTOMRIGHT", 0, -6); active:SetHeight(70)
local activeHdr = CdG.Header(active, "ZONA ACTIVA"); activeHdr:SetPoint("TOPLEFT", 4, -6); activeHdr:SetPoint("TOPRIGHT", -4, -6)
local activeName = CdG.Text(active, 12); activeName:SetPoint("TOP", 0, -21)
local activeMode = CdG.Text(active, 10); activeMode:SetPoint("TOPLEFT", 10, -37)
local activeTime = CdG.Text(active, 10); activeTime:SetPoint("TOPRIGHT", -10, -37)
local activeBar = CdG.Progress(active, 12); activeBar:SetPoint("BOTTOMLEFT", 10, 8); activeBar:SetPoint("BOTTOMRIGHT", -10, 8)

-- recursos
local res = CreateFrame("Frame", nil, P); res:SetHeight(18)
res:SetPoint("TOPLEFT", active, "BOTTOMLEFT", 4, -5); res:SetPoint("TOPRIGHT", active, "BOTTOMRIGHT", -4, -5)
local coinTxt = CdG.Text(res, 10); coinTxt:SetPoint("LEFT", 0, 0)
local woodTxt = CdG.Text(res, 10); woodTxt:SetPoint("CENTER", 10, 0)
local rankTxt = CdG.Text(res, 10, "gold"); rankTxt:SetPoint("RIGHT", 0, 0)
res:EnableMouse(true)
res:SetScript("OnEnter", function(self)
    local ch = CdG.char
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Recursos y rango", 1, 0.82, 0.3)
    GameTooltip:AddLine("Monedas de guerra: quédate dentro de una mina (1 cada 20 s), mina mineral allí (+2) o abate enemigos (+1, +2 en el frente destacado).", 1, 1, 1, true)
    GameTooltip:AddLine("Madera: quédate en un aserradero (10 cada 10 s). Con 500 puedes donar +1% de dominación.", 1, 1, 1, true)
    local idx, name, nextAt = CdG.RankFor(ch.glory or 0)
    GameTooltip:AddLine(format("Gloria: %d  ·  Rango %d: %s", ch.glory or 0, ch.rank or 1, CdG.RANKS[ch.rank or 1][2]), 1, 0.82, 0.3)
    if nextAt then GameTooltip:AddLine(format("Siguiente rango con %d de gloria", nextAt), 0.7, 0.7, 0.7) end
    GameTooltip:Show()
end)
res:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- botones
local BTNW = (PW - 24 - 8) / 2
local buttons = {}
local BUTTONS = {
    { "board", "Clasificación", "Interface\\Icons\\INV_Misc_Book_09", function() CdG.ShowLeaderboard() end, "Jugadores, hermandades, fortalezas y avanzadas de la semana." },
    { "fame", "Salón de la Fama", "Interface\\Icons\\Achievement_PVP_A_A", function() CdG.ShowFame() end, "Campeones de las semanas anteriores y tu hoja de servicio." },
    { "guide", "Guía", "Interface\\Icons\\INV_Misc_Note_01", function() CdG.ShowGuide() end, "Cómo funciona cada sistema." },
    { "call", "Llamada a las armas", "Interface\\Icons\\Ability_Warrior_BattleShout", function() CdG.CallToArms() end,
        function() local cd = CdG.CallCooldown(); return cd > 0 and ("Tu facción podrá volver a llamar en " .. CdG.Clock(cd)) or "Avisa a todos los jugadores de tu facción con el addon. Una llamada por facción cada 4 horas." end },
    { "general", "Tomar el mando", "Interface\\Icons\\INV_Sword_27", function() CdG.ToggleGeneral() end, "Si eres líder de grupo o banda, conviértete en el General de tu facción en este frente." },
    { "control", "Mando de control", "Interface\\Icons\\INV_Misc_Gear_01", function() CdG.ToggleCommand() end, "Configuración del addon, de las campañas y de las barras de campos de batalla." },
    { "donate", "Donar madera", "Interface\\Icons\\INV_TradeskillItem_01", function() CdG.DonateWood() end, "500 de madera = +1% de dominación semanal para tu facción." },
    { "sync", "Sincronizar", "Interface\\Icons\\Spell_Arcane_PortalDalaran", function() CdG.RequestSync(); CdG.Print("Pidiendo el estado de la campaña a otros jugadores…") end, "Pide el estado de la campaña a los demás jugadores con el addon." },
    { "export", "Exportar", "Interface\\Icons\\INV_Scroll_03", function() CdG.ShowExport() end, "Texto con tus estadísticas para copiar." },
    { "card", "Tarjeta de objetivo", "Interface\\Icons\\INV_Misc_Spyglass_03", function() CdG.ToggleCard() end, "Muestra u oculta la tarjeta lateral." },
}
for i, d in ipairs(BUTTONS) do
    local b = CdG.WarButton(P, d[2], d[3], BTNW, 26)
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    b:SetPoint("TOPLEFT", res, "BOTTOMLEFT", -4 + col * (BTNW + 8), -6 - row * 30)
    b:SetScript("OnClick", d[4])
    b.tip = d[5]
    buttons[d[1]] = b
end

-- ---------------------------------------------------------------------------
-- Tarjeta lateral (siguiente objetivo / frente destacado)
-- ---------------------------------------------------------------------------
local K = CreateFrame("Frame", "CdGCard", P)
CdG.Card = K
K:SetWidth(CW); K:SetHeight(CH)
K:SetPoint("TOPRIGHT", P, "TOPLEFT", 4, 0)
CdG.Ornate(K)
local crest = CdG.Crest(K, 64); crest:SetPoint("TOP", 0, 30)
local plate = CdG.Plate(K, CW - 40, 34); plate:SetPoint("TOP", 0, -40)
local kFront = CdG.Title(K, 17); kFront:SetPoint("TOP", plate, "BOTTOM", 0, -8)
local imgBox = CreateFrame("Frame", nil, K); CdG.Inset(imgBox, 1)
imgBox:SetWidth(CW - 28); imgBox:SetHeight((CW - 36) * 668 / 1002 + 8); imgBox:SetPoint("TOP", kFront, "BOTTOM", 0, -6)
local img = CdG.ZoneImage(imgBox, CW - 36, (CW - 36) * 668 / 1002); img:SetPoint("CENTER")
local kObj = CdG.Text(K, 13); kObj:SetPoint("TOP", imgBox, "BOTTOM", 0, -8); kObj:SetWidth(CW - 30)
local kInfo = CdG.Text(K, 10); kInfo:SetPoint("TOP", kObj, "BOTTOM", 0, -4); kInfo:SetWidth(CW - 34); kInfo:SetJustifyH("CENTER")
local actBox = CreateFrame("Frame", nil, K); CdG.Inset(actBox)
actBox:SetPoint("TOPLEFT", 14, -360); actBox:SetPoint("TOPRIGHT", -14, -360); actBox:SetHeight(128)
local actHdr = CdG.Text(actBox, 10, "gold"); actHdr:SetPoint("TOP", 0, -7); actHdr:SetText("Actividad reciente (últimos 5 min)")
local actRows = {}
for i = 1, 6 do
    local r = CreateFrame("Frame", nil, actBox); r:SetHeight(17)
    r:SetPoint("TOPLEFT", 8, -22 - (i - 1) * 17); r:SetPoint("TOPRIGHT", -8, -22 - (i - 1) * 17)
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetTexture(MEDIA .. "banner"); r.icon:SetWidth(12); r.icon:SetHeight(12); r.icon:SetPoint("LEFT")
    r.name = CdG.Text(r, 10); r.name:SetPoint("LEFT", r.icon, "RIGHT", 5, 0)
    r.val = CdG.Text(r, 10, "muted"); r.val:SetPoint("RIGHT")
    actRows[i] = r
end
-- arrastrar la tarjeta mueve todo el conjunto
K:EnableMouse(true)
K:RegisterForDrag("LeftButton")
K:SetScript("OnDragStart", function() P:StartMoving() end)
K:SetScript("OnDragStop", function() P:GetScript("OnDragStop")(P) end)
local kCoins = CdG.Text(K, 11); kCoins:SetPoint("TOP", actBox, "BOTTOM", 0, -10)
local bReinf = CdG.WarButton(K, format("Reforzar  %d", CdG.COST), "Interface\\Icons\\INV_Misc_Coin_02", (CW - 40) / 2, 26)
bReinf:SetPoint("TOPLEFT", actBox, "BOTTOMLEFT", 0, -30)
bReinf:SetScript("OnClick", function() CdG.BuyReinforce() end)
bReinf.tip = "La próxima captura enemiga en tu punto propio más cercano tardará un minuto más (máx. 3)."
local bAttack = CdG.WarButton(K, format("Atacar  %d", CdG.COST), "Interface\\Icons\\INV_Misc_Coin_02", (CW - 40) / 2, 26)
bAttack:SetPoint("TOPRIGHT", actBox, "BOTTOMRIGHT", 0, -30)
bAttack:SetScript("OnClick", function() CdG.BuyAttack() end)
bAttack.tip = "Tu próxima captura será un minuto más corta. No funciona en capitales con menos de un minuto."
local bOk = CdG.WarButton(K, "Entendido", nil, CW - 80, 26); bOk:SetPoint("BOTTOM", 0, 16)
bOk:SetScript("OnClick", function() db().featseen = CdG.Featured().key; CdG.Changed() end)
local cardToggle = CdG.WarButton(P, "<", nil, 18, 40); cardToggle:SetPoint("RIGHT", P, "LEFT", 6, 120)
cardToggle:SetScript("OnClick", function() CdG.ToggleCard() end)

function CdG.ToggleCard()
    db().cardhidden = not db().cardhidden
    CdG.Changed()
end

-- ---------------------------------------------------------------------------
-- Selector de frentes (ventana emergente por continentes)
-- ---------------------------------------------------------------------------
local pick = CreateFrame("Frame", "CdGFrontPicker", P)
pick:SetFrameStrata("FULLSCREEN_DIALOG")
pick:SetWidth(440); pick:SetHeight(380)
pick:SetPoint("TOPLEFT", selBtn, "BOTTOMLEFT", 0, -4)
CdG.Ornate(pick)
pick:EnableMouse(true)
pick:Hide()
local pickConts = { "Reinos del Este", "Kalimdor", "Terrallende", "Rasganorte" }
pick.tabs, pick.rows, pick.cont = {}, {}, nil
for i, name in ipairs(pickConts) do
    local t = CdG.WarButton(pick, name, nil, 100, 22)
    t:SetPoint("TOPLEFT", 14 + (i - 1) * 104, -14)
    t:SetScript("OnClick", function() pick.cont = name; pick:Refresh() end)
    pick.tabs[i] = t
end
for i = 1, 30 do
    local r = CdG.WarButton(pick, "", nil, 200, 20)
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    r:SetPoint("TOPLEFT", 14 + col * 208, -44 - row * 22)
    r.score = CdG.Text(r, 9); r.score:SetPoint("RIGHT", -6, 0)
    r.label:SetPoint("RIGHT", -40, 0)
    r:SetScript("OnClick", function(self)
        selectedFront = self.front
        db().selected = self.front.key
        pick:Hide()
        CdG.Changed()
    end)
    pick.rows[i] = r
end
function pick:Refresh()
    for i, t in ipairs(self.tabs) do t:SetRed(pickConts[i] == self.cont) end
    local list = {}
    for _, f in ipairs(CdG.FRONTS) do if f.continent == self.cont then table.insert(list, f) end end
    table.sort(list, function(a, b) return a.name < b.name end)
    local feat = CdG.Featured()
    for i, r in ipairs(self.rows) do
        local f = list[i]
        if f then
            r.front = f
            r:SetLabel((f == feat and "|cffffcc55*|r " or "") .. f.name)
            local a, h = CdG.FrontScore(f)
            local w = CdG.FrontWinner(f)
            r.score:SetText(w and ("|cff" .. (w == "A" and "4a8cff" or "ff4033") .. "Ganado|r") or format("|cff4a8cff%d|r-|cffff4033%d|r", a, h))
            r.tip = f.desc
            r:Show()
        else
            r:Hide()
        end
    end
end
selBtn:SetScript("OnClick", function()
    if pick:IsShown() then pick:Hide() return end
    local f = CdG.current or selectedFront or CdG.Featured()
    pick.cont = f.continent
    pick:Refresh()
    pick:Show()
end)
selBtn.tip = "Elige qué frente quieres ver en el panel y en la tarjeta."

-- ---------------------------------------------------------------------------
-- Refresco
-- ---------------------------------------------------------------------------
local STATE_TXT = { A = "Alianza", H = "Horda" }
local function ViewFront()
    if CdG.current then return CdG.current end
    if not selectedFront and db().selected then selectedFront = CdG.FRONT_BY_KEY[db().selected] end
    return selectedFront or CdG.Featured()
end
CdG.ViewFront = ViewFront

local function NodeIcon(n)
    if n.kind == "outpost" then return MEDIA .. "tower" end
    if n.kind == "keep" or n.kind == "capital" then return MEDIA .. "keep" end
    return MEDIA .. "banner"
end

local function FillCell(c, n)
    c.node, c.bgbar = n, nil
    c.icon:SetTexture(NodeIcon(n))
    local o = CdG.GetOwner(n.id)
    local col = CdG.FactionColor(o)
    c.icon:SetVertexColor(rgba(col))
    c.name:SetText(n.name)
    local cf, cprog, ctotal = CdG.CaptureOn(n.id)
    if cf then
        c.state:SetText(CdG.Clock(ctotal - cprog)); c.state:SetTextColor(rgba(C.orange))
        c.bar:Show(); c.bar:SetValue(cprog / ctotal, CdG.FactionColor(cf))
    else
        c.bar:Hide()
        if o then
            c.state:SetText(STATE_TXT[o]); c.state:SetTextColor(col[1], col[2], col[3], 0.8)
        elseif CdG.CanAttack(n, CdG.myFK) then
            c.state:SetText("¡Ataca!"); c.state:SetTextColor(rgba(C.gold))
        else
            c.state:SetText("Neutral"); c.state:SetTextColor(rgba(C.muted))
        end
        if o and o ~= CdG.myFK and CdG.CanAttack(n, CdG.myFK) then c.state:SetText("¡Ataca!"); c.state:SetTextColor(rgba(C.gold)) end
    end
    c.name:SetTextColor(rgba((CdG.Engine.state.node == n) and C.gold or (o and col or C.text)))
    c:Show()
end

local function FillBGCell(c, bar)
    c.node = nil
    c.icon:SetTexture(bar.icon:GetTexture()); c.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93); c.icon:SetVertexColor(1, 1, 1)
    c.name:SetText(bar.displaytext:GetText() or bar.name); c.name:SetTextColor(1, 1, 1)
    c.state:SetText(CdG.Clock(bar.remaining or 0)); c.state:SetTextColor(rgba(C.gold))
    local col = CdG.BarColor and CdG.BarColor(bar) or C.gold
    c.bar:Show(); c.bar:SetValue((bar.remaining or 0) / (bar.duration or 1), col)
    c.bgbar = bar.displaytext:GetText()
    c:Show()
end

local function RefreshPanel()
    local d = db()
    local fk = CdG.myFK
    local front = ViewFront()
    -- red
    local peers = CdG.Peers()
    net.dot:SetVertexColor(rgba(peers > 0 and C.good or (CdG.SyncChannelId() and C.gold or C.horde)))
    net.text:SetText(peers > 0 and format("%d en red", peers) or (d.sync and "Buscando…" or "Sin sincronía"))
    -- selector y retratos
    selBtn:SetLabel(front.short or front.name)
    if not P.portraits then
        P.portraits = true
        if fk == "A" then SetPortraitTexture(portA.tex, "player"); portH.tex:SetTexture("Interface\\CharacterFrame\\TemporaryPortrait-Male-Orc")
        else SetPortraitTexture(portH.tex, "player"); portA.tex:SetTexture("Interface\\CharacterFrame\\TemporaryPortrait-Male-Human") end
    end
    local ne = CdG.CountEnemies()
    nearby:SetText(format("%d %s cerca", ne, fk == "A" and "Horda" or "Alianza"))
    nearby:SetTextColor(rgba(ne > 0 and C.horde or C.text))
    if fk == "H" then nearby:SetTextColor(rgba(ne > 0 and C.alliance or C.text)) end
    -- dominación
    local a, h = CdG.Domination()
    dom:SetSplit(a / 100, C.alliance, C.horde)
    dom.text:SetText(format("%.1f%%  —  %.1f%%", a, h))
    -- zonas de control (o barras del campo de batalla)
    local _, itype = IsInInstance()
    local bgBars = {}
    if (itype == "pvp" or itype == "arena") and Capping and Capping.bars then
        for _, b in ipairs(Capping.bars) do if b:IsShown() then table.insert(bgBars, b) end end
        table.sort(bgBars, function(x, y) return (x.remaining or 0) < (y.remaining or 0) end)
    end
    zonesEmpty:SetText("")
    if itype == "pvp" or itype == "arena" then
        zonesHdr:SetText(itype == "arena" and "ARENA" or ("CAMPO DE BATALLA: " .. (GetRealZoneText() or ""):upper()))
        for i, c in ipairs(cells) do if bgBars[i] then FillBGCell(c, bgBars[i]) else c:Hide() end end
        if #bgBars == 0 then zonesEmpty:SetText("Sin temporizadores activos todavía.") end
    else
        zonesHdr:SetText("ZONAS DE CONTROL · " .. (front.short or front.name):upper())
        local list = {}
        for _, n in ipairs(front.points) do table.insert(list, n) end
        if front.outpost then table.insert(list, front.outpost) end
        for i, c in ipairs(cells) do if list[i] then FillCell(c, list[i]) else c:Hide() end end
    end
    -- zona activa
    local S = CdG.Engine.state
    if S.node then
        activeName:SetText(S.node.name)
        local modes = {
            hold = { "Mantener", C.alliance }, capture = { "Capturando", C.gold }, locked = { "Bloqueado", C.muted },
            req = { "En espera", C.orange }, mine = { "Mina", C.mine }, lumber = { "Aserradero", C.lumber },
        }
        local m = modes[S.mode] or { "", C.text }
        activeMode:SetText(m[1]); activeMode:SetTextColor(rgba(m[2]))
        if S.mode == "hold" and fk == "H" then activeMode:SetTextColor(rgba(C.horde)) end
        if S.mode == "capture" or S.mode == "req" then
            activeTime:SetText(format("%s / %s", CdG.Clock(S.prog), CdG.Clock(S.total)))
            activeBar:SetValue(S.pct, CdG.FactionColor(fk))
            activeBar.text:SetText(format("%d%%", S.pct * 100))
        elseif S.mode == "mine" then
            activeTime:SetText(format("Reservas: %d / 100", S.prog)); activeBar:SetValue(S.pct, C.mine); activeBar.text:SetText(S.status)
        elseif S.mode == "lumber" then
            activeTime:SetText(format("%d / %d", S.prog, S.total)); activeBar:SetValue(S.pct, C.lumber); activeBar.text:SetText(S.status)
        else
            activeTime:SetText("")
            activeBar:SetValue(S.mode == "hold" and 1 or 0, CdG.FactionColor(S.mode == "hold" and fk or nil))
            activeBar.text:SetText(S.status)
        end
        if S.mode == "capture" or S.mode == "req" then activeMode:SetText(m[1] .. "  ·  " .. S.status) end
    else
        local caps = CdG.ActiveCaptures()
        local c = caps[1]
        if c and c.node then
            activeName:SetText(c.node.name)
            activeMode:SetText(format("%s capturando (%s)", CdG.FactionName(c.f), c.who or "?")); activeMode:SetTextColor(rgba(CdG.FactionColor(c.f)))
            activeTime:SetText(format("%s / %s", CdG.Clock(c.prog), CdG.Clock(c.total)))
            activeBar:SetValue(c.prog / c.total, CdG.FactionColor(c.f)); activeBar.text:SetText(format("%d%%", c.prog / c.total * 100))
        else
            activeName:SetText("|cff888888Ninguna|r")
            activeMode:SetText("Entra en un círculo de captura"); activeMode:SetTextColor(rgba(C.muted))
            activeTime:SetText("")
            activeBar:SetValue(0); activeBar.text:SetText("")
        end
    end
    -- recursos
    local ch = CdG.char
    coinTxt:SetText(format("|TInterface\\Icons\\INV_Misc_Coin_02:12:12:0:0:64:64:5:59:5:59|t %d/%d%s", ch.coins, CdG.MAX_COINS, ch.attack and " |cffff8800(Ataque)|r" or ""))
    woodTxt:SetText(format("|TInterface\\Icons\\INV_TradeskillItem_01:12:12:0:0:64:64:5:59:5:59|t %d/%d", ch.wood, CdG.MAX_WOOD))
    rankTxt:SetText(CdG.RANKS[ch.rank or 1][2])
    -- botones
    local cd = CdG.CallCooldown()
    buttons.call:SetLabel(cd > 0 and CdG.Clock(cd) or "Llamada a las armas")
    buttons.call:SetEnabledLook(cd == 0 and (CdG.current ~= nil))
    buttons.general:SetLabel(CdG.IsGeneral() and "Dejar el mando" or "Tomar el mando")
    buttons.general:SetEnabledLook(CdG.current ~= nil and (IsPartyLeader() or IsRaidLeader() or CdG.IsGeneral()))
    buttons.donate:SetEnabledLook(ch.wood >= 500)
    buttons.card:SetLabel(d.cardhidden and "Mostrar tarjeta" or "Ocultar tarjeta")
end

local function RefreshCard()
    local d = db()
    if d.cardhidden then K:Hide(); cardToggle:SetLabel(">") return end
    K:Show(); cardToggle:SetLabel("<")
    local fk = CdG.myFK
    crest:SetFaction(fk)
    local feat = CdG.Featured()
    local front = ViewFront()
    local showFeat = d.featseen ~= feat.key
    local f = showFeat and feat or front
    plate.text:SetText(showFeat and "Frente destacado" or "Siguiente objetivo")
    kFront:SetText(f.name)
    img:SetMap(f.map)
    -- puntos sobre la imagen
    img:ClearDots()
    local iw, ih = img:GetWidth(), img:GetHeight()
    local obj, dist = CdG.NextObjective(f)
    local i = 0
    for _, n in ipairs(CdG.BY_MAP[f.map] or {}) do
        i = i + 1
        local dot = img:Dot(i)
        local size = (n.kind == "capital" or n.kind == "keep") and 11 or 8
        if n == obj then size = 13 end
        dot:SetWidth(size); dot:SetHeight(size)
        dot:ClearAllPoints(); dot:SetPoint("CENTER", img, "TOPLEFT", n.x * iw, -n.y * ih)
        if n.kind == "mine" then dot:SetVertexColor(rgba(C.mine))
        elseif n.kind == "lumber" then dot:SetVertexColor(rgba(C.lumber))
        elseif n == obj then dot:SetVertexColor(rgba(C.gold))
        else dot:SetVertexColor(rgba(CdG.FactionColor(CdG.GetOwner(n.id)))) end
        dot:Show()
    end
    local map, px, py = CdG.PlayerPos()
    if map == f.map and px then
        i = i + 1
        local me = img:Dot(i); me:SetWidth(7); me:SetHeight(7); me:SetVertexColor(1, 1, 1)
        me:ClearAllPoints(); me:SetPoint("CENTER", img, "TOPLEFT", px * iw, -py * ih); me:Show()
    end
    if showFeat then
        kObj:SetText(f.desc or "")
        kInfo:SetText("El frente destacado de hoy da |cffffcc55crédito doble por baja|r y |cffffcc55+1 moneda|r por baja mientras estés en él.")
        bOk:Show(); bReinf:Hide(); bAttack:Hide(); kCoins:Hide()
    else
        bOk:Hide(); bReinf:Show(); bAttack:Show(); kCoins:Show()
        if obj then
            kObj:SetText(obj.name)
            local tt = CdG.Clock(CdG.CaptureTime(obj, fk, true))
            if dist then
                kInfo:SetText(format("Distancia: ~%d metros\nVe allí y quédate dentro del círculo para iniciar la captura (%s).", dist, tt))
            else
                kInfo:SetText(format("Viaja a %s y quédate dentro del círculo para capturarlo (%s).", f.name, tt))
            end
        else
            local w = CdG.FrontWinner(f)
            kObj:SetText(w and ("Frente ganado por la " .. CdG.FactionName(w)) or "Sin objetivos")
            kInfo:SetText(w == fk and "Defiende lo conquistado hasta el reinicio semanal." or "Recupera un punto conectado con tu capital para volver a avanzar.")
        end
    end
    -- actividad reciente
    local act = CdG.RecentActivity()
    local shown, seen = 0, {}
    for _, r in ipairs(act) do
        if shown >= #actRows then break end
        shown = shown + 1; seen[r.front] = true
        local row = actRows[shown]
        row.name:SetText(r.front.short or r.front.name)
        row.name:SetTextColor(rgba(r.front == feat and C.gold or C.text))
        row.val:SetText((r.a + r.h > 0) and format("|cff4a8cff%d|r-|cffff4033%d|r", r.a, r.h) or CdG.Ago(r.last))
        row.val:SetTextColor(rgba(time() - r.last < 60 and C.gold or C.text))
        row.icon:SetVertexColor(rgba(C.gold))
        row:Show()
    end
    for _, extra in ipairs({ feat, front }) do
        if shown < #actRows and not seen[extra] then
            shown = shown + 1; seen[extra] = true
            local row = actRows[shown]
            row.name:SetText(extra.short or extra.name); row.name:SetTextColor(rgba(extra == feat and C.gold or C.muted))
            row.val:SetText("—"); row.val:SetTextColor(rgba(C.muted)); row.icon:SetVertexColor(rgba(C.muted))
            row:Show()
        end
    end
    for j = shown + 1, #actRows do actRows[j]:Hide() end
    local ch = CdG.char
    kCoins:SetText(format("|TInterface\\Icons\\INV_Misc_Coin_02:14:14:0:0:64:64:5:59:5:59|t Monedas: %d / %d", ch.coins, CdG.MAX_COINS))
    bReinf:SetEnabledLook(ch.coins >= CdG.COST)
    bAttack:SetEnabledLook(ch.coins >= CdG.COST and not ch.attack)
end

local function Refresh()
    if not P:IsShown() or not CdG.db then return end
    RefreshPanel()
    RefreshCard()
end
CdG.OnChange(Refresh)
P:SetScript("OnShow", function(self)
    self.portraits = nil
    if not self.docked then self:SetScale(CdG.db.scale or 1) end
    Refresh()
end)
P:SetScript("OnHide", function() pick:Hide() end)

-- ---------------------------------------------------------------------------
-- Junto al mapa del mundo
-- ---------------------------------------------------------------------------
local function Place()
    P:ClearAllPoints()
    local pos = db().panelpos
    if pos then P:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else P:SetPoint("RIGHT", UIParent, "RIGHT", -40, 40) end
end

WorldMapFrame:HookScript("OnShow", function()
    if not CdG.db or not CdG.db.panelonmap or CdG.db.mapmode == "hidden" then return end
    P.wasShown = P:IsShown()
    P.docked = true
    P:SetParent(WorldMapFrame)
    P:SetFrameStrata("FULLSCREEN_DIALOG")
    P:SetScale(CdG.db.mapscale or 0.85)
    P:ClearAllPoints()
    local pos = CdG.db.mappos
    if pos then
        P:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        -- primera vez: a la derecha del mapa, con la tarjeta pegada al borde, sin taparlo
        P:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPRIGHT", CW + 10, 0)
    end
    P:Show()
end)
WorldMapFrame:HookScript("OnHide", function()
    if not P.docked then return end
    P.docked = nil
    P:SetParent(UIParent)
    P:SetFrameStrata("HIGH")
    P:SetScale(CdG.db.scale or 1)
    Place()
    if not P.wasShown then P:Hide() end
end)

function CdG.TogglePanel()
    if P:IsShown() then P:Hide() else P:Show() end
end

-- vuelve a colocar el panel (tras cambiar escala o restablecer posiciones)
function CdG.ResetPanelPositions()
    db().panelpos, db().mappos = nil, nil
    if P.docked then
        P:ClearAllPoints(); P:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPRIGHT", CW + 10, 0)
    else
        Place()
    end
end
function CdG.ApplyPanelScale()
    if P.docked then P:SetScale(db().mapscale or 0.85) else P:SetScale(db().scale or 1) end
end

CdG.OnLogin = function()
    Place()
end
