-- ============================================================================
-- Campañas de Guerra - Barras de campos de batalla integradas en el nuevo estilo
-- Las barras de Capping se colocan dentro de un marco dorado "Temporizadores"
-- que crece con ellas y se oculta cuando no hay ninguna.
-- ============================================================================
local CdG = CdG
local C, rgba = CdG.C, CdG.rgba
local MEDIA = CdG.MEDIA
local L = Capping.L

local function capdb() return Capping and Capping.db end

function CdG.BarColor(bar)
    local d = capdb()
    local c = d and d.colors and (d.colors[bar.color] or d.colors.info1)
    if c then return { c.r, c.g, c.b, 1 } end
    return C.gold
end

-- aspecto de cada barra: borde dorado oscuro y separador del icono a juego
function CdG.StyleBar(f)
    if f.border then f.border:SetBackdropBorderColor(C.goldDark[1], C.goldDark[2], C.goldDark[3], 1) end
    if f.iconborder then f.iconborder:SetVertexColor(C.goldDark[1], C.goldDark[2], C.goldDark[3], 1) end
    if not f.cdgGloss and f.barback then
        f.cdgGloss = f:CreateTexture(nil, "OVERLAY")
        f.cdgGloss:SetTexture(CdG.FLAT)
        f.cdgGloss:SetPoint("TOPLEFT", f.barback, "TOPLEFT")
        f.cdgGloss:SetPoint("TOPRIGHT", f.barback, "TOPRIGHT")
        f.cdgGloss:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.12)
    end
    if f.cdgGloss then f.cdgGloss:SetHeight(math.max(1, (f:GetHeight() or 12) / 2)) end
end

-- ---------------------------------------------------------------------------
-- Marco "Temporizadores"
-- ---------------------------------------------------------------------------
local dock = CreateFrame("Frame", "CdGBarDock", UIParent)
CdG.BarDock = dock
dock:SetWidth(250); dock:SetHeight(60)
dock:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200)
dock:SetMovable(true); dock:EnableMouse(true); dock:SetClampedToScreen(true)
dock:RegisterForDrag("LeftButton")
dock:SetScript("OnDragStart", dock.StartMoving)
dock:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    CdG.db.dockpos = { p, rp, x, y }
end)
CdG.Ornate(dock, 0.9)
dock:Hide()
dock.crest = CdG.Crest(dock, 28); dock.crest:SetPoint("TOPLEFT", 10, -8)
dock.title = CdG.Title(dock, 14); dock.title:SetPoint("TOPLEFT", dock.crest, "TOPRIGHT", 6, -1)
dock.sub = CdG.Text(dock, 9, "muted"); dock.sub:SetPoint("TOPLEFT", dock.title, "BOTTOMLEFT", 0, -1)
dock.line = dock:CreateTexture(nil, "ARTWORK"); dock.line:SetTexture(CdG.FLAT); dock.line:SetHeight(1)
dock.line:SetPoint("TOPLEFT", 10, -40); dock.line:SetPoint("TOPRIGHT", -10, -40)
dock.line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0.3, 0.8, 1, 0.82, 0.3, 0)

local docked = false
local function Restore()
    local d = capdb()
    if not Capping or not d then return end
    Capping:SetParent(UIParent)
    Capping:ClearAllPoints()
    if d.x then Capping:SetPoint(d.p or "TOPLEFT", UIParent, d.rp or "TOPLEFT", d.x, d.y)
    else Capping:SetPoint("CENTER", UIParent, "CENTER", 200, -100) end
end

function CdG.DockUpdate()
    local d = capdb()
    if not d or not CdG.db then return end
    if not CdG.db.dockbars then
        if docked then docked = false; Restore() end
        dock:Hide()
        return
    end
    if not docked then
        docked = true
        if not dock.placed then
            dock.placed = true
            local p = CdG.db.dockpos
            if p then dock:ClearAllPoints(); dock:SetPoint(p[1], UIParent, p[2], p[3], p[4]) end
        end
        -- dentro del marco todas las barras crecen hacia abajo
        d.onegroup, d.mainup = true, false
        Capping:ClearAllPoints()
        Capping:SetPoint("TOPLEFT", dock, "TOPLEFT", 12, -44)
    end
    local n = 0
    for _, b in ipairs(Capping.bars or {}) do if b:IsShown() then n = n + 1; b.down = true end end
    dock:SetWidth((d.width or 220) + 24)
    if n == 0 then dock:Hide() return end
    dock:SetHeight(44 + n * ((d.height or 18) + (d.spacing or 2)) + 12)
    dock.crest:SetFaction(CdG.myFK)
    local _, itype = IsInInstance()
    if itype == "pvp" then dock.title:SetText(GetRealZoneText() or "Campo de batalla"); dock.sub:SetText("Temporizadores del campo de batalla")
    elseif itype == "arena" then dock.title:SetText("Arena"); dock.sub:SetText("Temporizadores de arena")
    else dock.title:SetText("Temporizadores"); dock.sub:SetText("Colas, Conquista del Invierno y avisos") end
    dock:SetScale(CdG.db.scale or 1)
    dock:Show()
end

-- ---------------------------------------------------------------------------
-- Menú de barra (clic derecho) con el estilo nuevo
-- ---------------------------------------------------------------------------
local menu = CreateFrame("Frame", "CdGBarMenu", UIParent)
menu:SetFrameStrata("FULLSCREEN_DIALOG")
menu:SetWidth(210); menu:SetHeight(100)
menu:SetClampedToScreen(true)
menu:EnableMouse(true)
CdG.Ornate(menu)
menu:Hide()
table.insert(UISpecialFrames, "CdGBarMenu")
menu.icon = menu:CreateTexture(nil, "ARTWORK"); menu.icon:SetWidth(22); menu.icon:SetHeight(22); menu.icon:SetPoint("TOPLEFT", 12, -12)
menu.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
menu.title = CdG.Title(menu, 13); menu.title:SetPoint("LEFT", menu.icon, "RIGHT", 6, 0); menu.title:SetPoint("RIGHT", -12, 0)
menu.title:SetJustifyH("LEFT")
menu.btns = {}
local function MenuButton(i)
    local b = menu.btns[i]
    if not b then
        b = CdG.WarButton(menu, "", nil, 186, 22)
        b:SetPoint("TOP", 0, -40 - (i - 1) * 25)
        menu.btns[i] = b
    end
    return b
end

function CdG.ShowBarMenu(id)
    local name, isWinter, isActive, bar = Capping:BarInfo(id)
    if not name then return end
    local items = {}
    local function add(label, icon, fn) table.insert(items, { label, icon, fn }) end
    if isWinter then
        add(L and L["Cancel Timer"] or "Cancelar", "Interface\\Icons\\Spell_ChargeNegative", function() Capping:BarAction("cancel", id) end)
    elseif not isActive then
        add(ENTER_BATTLE or "Entrar", "Interface\\Icons\\Ability_Warrior_Charge", function() Capping:BarAction("enterbattle", id) end)
        add(LEAVE_QUEUE or "Salir de la cola", "Interface\\Icons\\Spell_ChargeNegative", function() Capping:BarAction("cancel", id) end)
    else
        add("Avisar al campo de batalla", "Interface\\Icons\\Ability_Warrior_BattleShout", function() Capping:BarAction("reportbg", id) end)
        add("Avisar en /decir", "Interface\\Icons\\Spell_Holy_Silence", function() Capping:BarAction("reportsay", id) end)
        add("Cancelar temporizador", "Interface\\Icons\\Spell_ChargeNegative", function() Capping:BarAction("cancel", id) end)
    end
    add("Opciones de barras", "Interface\\Icons\\INV_Misc_PocketWatch_01", function() CdG.OpenCommand("bars") end)
    add("Campos de batalla", "Interface\\Icons\\Achievement_BG_winWSG", function() CdG.OpenCommand("bgs") end)
    if not CdG.db.dockbars then add("Mostrar u ocultar ancla", "Interface\\Icons\\Ability_Rogue_Sprint", function() Capping.ToggleAnchor() end) end
    menu.icon:SetTexture(bar.icon:GetTexture())
    menu.title:SetText(bar.displaytext:GetText() or name)
    for i, it in ipairs(items) do
        local b = MenuButton(i)
        b:SetLabel(it[1])
        b.icon:SetTexture(it[2]); b.icon:Show()
        b.label:ClearAllPoints(); b.label:SetPoint("LEFT", b.icon, "RIGHT", 6, 0); b.label:SetPoint("RIGHT", -6, 0)
        b.label:SetJustifyH("LEFT")
        b:SetScript("OnClick", function() menu:Hide(); it[3]() end)
        b:Show()
    end
    for i = #items + 1, #menu.btns do menu.btns[i]:Hide() end
    menu:SetHeight(48 + #items * 25)
    local x, y = GetCursorPosition()
    local s = UIParent:GetEffectiveScale()
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s + 4, y / s + 4)
    menu.idle = 0
    menu:Show()
end
-- se cierra solo si el ratón sale un rato
menu:SetScript("OnUpdate", function(self, e)
    if MouseIsOver(self) then self.idle = 0 else self.idle = (self.idle or 0) + e end
    if self.idle > 1.5 then self:Hide() end
end)

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:SetScript("OnEvent", function() if CdG.db then CdG.DockUpdate() end end)
