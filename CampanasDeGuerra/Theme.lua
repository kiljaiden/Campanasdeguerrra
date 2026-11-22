-- ============================================================================
-- Campañas de Guerra - Tema visual y controles planos
-- ============================================================================
CdG = CdG or {}
local CdG = CdG

local FLAT = "Interface\\Buttons\\WHITE8X8"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
CdG.FLAT, CdG.FONT = FLAT, FONT

-- Paleta: oscuro con acento carmesí y dorado (estandarte de guerra)
local C = {
    bg     = {0.075, 0.060, 0.048, 0.97},
    panel  = {0.100, 0.082, 0.064, 1},
    card   = {0.060, 0.050, 0.042, 0.92},
    input  = {0.035, 0.030, 0.026, 1},
    button = {0.130, 0.105, 0.080, 1},
    border = {0.420, 0.340, 0.180, 1},
    accent = {0.86, 0.20, 0.22, 1},
    gold   = {0.98, 0.78, 0.30, 1},
    text   = {1, 1, 1, 1},
    muted  = {0.60, 0.58, 0.62, 1},
    good   = {0.30, 0.85, 0.45, 1},
    goodBg = {0.12, 0.34, 0.18, 1},
    red    = {0.45, 0.10, 0.10, 1},
    alliance = {0.25, 0.55, 1.00, 1},
    horde    = {1.00, 0.25, 0.20, 1},
    neutral  = {0.60, 0.60, 0.60, 1},
}
CdG.C = C
local function rgba(c) return c[1], c[2], c[3], c[4] or 1 end
CdG.rgba = rgba

function CdG.Flat(f, bg, border)
    f:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, tile = false, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    f:SetBackdropColor(rgba(type(bg) == "table" and bg or C[bg or "panel"]))
    f:SetBackdropBorderColor(rgba(type(border) == "table" and border or C[border or "border"]))
end

function CdG.Text(parent, size, role, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFont(FONT, size or 11)
    fs:SetShadowOffset(1, -1)
    fs:SetTextColor(rgba(C[role or "text"]))
    return fs
end

function CdG.AccentLine(parent, anchor, height)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(FLAT); t:SetHeight(height or 2)
    t:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT"); t:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT")
    t:SetGradientAlpha("HORIZONTAL", C.accent[1], C.accent[2], C.accent[3], 1, C.gold[1], C.gold[2], C.gold[3], 0.15)
    return t
end

function CdG.Button(parent, label, w, h, style)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(w or 120); b:SetHeight(h or 24)
    b.style = style or "button"
    CdG.Flat(b, b.style)
    b.label = CdG.Text(b, 11)
    b.label:SetPoint("CENTER")
    b.label:SetText(label or "")
    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(rgba(C.gold))
        if self.tip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(self.tip, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(rgba(C.border)); GameTooltip:Hide() end)
    b.SetLabel = function(self, t) self.label:SetText(t) end
    b.SetStyle = function(self, s) self.style = s; self:SetBackdropColor(rgba(C[s])) end
    return b
end

-- Interruptor (casilla plana con texto). get()/set(v)
function CdG.Toggle(parent, label, get, set, tip)
    local f = CreateFrame("Button", nil, parent)
    f:SetHeight(22); f:SetWidth(260)
    f.box = CreateFrame("Frame", nil, f)
    f.box:SetWidth(16); f.box:SetHeight(16); f.box:SetPoint("LEFT")
    CdG.Flat(f.box, "input")
    f.fill = f.box:CreateTexture(nil, "OVERLAY"); f.fill:SetTexture(FLAT)
    f.fill:SetPoint("TOPLEFT", 3, -3); f.fill:SetPoint("BOTTOMRIGHT", -3, 3)
    f.fill:SetVertexColor(rgba(C.accent))
    f.text = CdG.Text(f, 11); f.text:SetPoint("LEFT", f.box, "RIGHT", 8, 0); f.text:SetText(label)
    f.tip = tip
    function f:Refresh() if get() then self.fill:Show() else self.fill:Hide() end end
    f:SetScript("OnClick", function(self) set(not get()); self:Refresh() end)
    f:SetScript("OnEnter", function(self)
        self.box:SetBackdropBorderColor(rgba(C.gold))
        if self.tip then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine(self.tip, 1, 1, 1, true); GameTooltip:Show() end
    end)
    f:SetScript("OnLeave", function(self) self.box:SetBackdropBorderColor(rgba(C.border)); GameTooltip:Hide() end)
    f:Refresh()
    return f
end

-- Deslizador plano. get()/set(v)
local sliderCount = 0
function CdG.Slider(parent, label, minv, maxv, step, get, set, fmt)
    sliderCount = sliderCount + 1
    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(260); f:SetHeight(40)
    f.label = CdG.Text(f, 11); f.label:SetPoint("TOPLEFT", 0, 0); f.label:SetText(label)
    f.value = CdG.Text(f, 11, "gold"); f.value:SetPoint("TOPRIGHT", 0, 0)
    local s = CreateFrame("Slider", "CdGSlider" .. sliderCount, f)
    s:SetOrientation("HORIZONTAL")
    s:SetHeight(10)
    s:SetPoint("BOTTOMLEFT", 0, 6); s:SetPoint("BOTTOMRIGHT", 0, 6)
    CdG.Flat(s, "input")
    s:SetThumbTexture(FLAT)
    local thumb = s:GetThumbTexture()
    thumb:SetWidth(10); thumb:SetHeight(14); thumb:SetVertexColor(rgba(C.accent))
    s:SetMinMaxValues(minv, maxv)
    s:SetValueStep(step)
    s:EnableMouseWheel(true)
    f.slider = s
    local function show(v)
        f.value:SetText(fmt and format(fmt, v) or (step < 1 and format("%.2f", v) or tostring(math.floor(v + 0.5))))
    end
    s:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        show(v)
        if not f.lock then set(v) end
    end)
    s:SetScript("OnMouseWheel", function(self, d) self:SetValue(self:GetValue() + d * step) end)
    function f:Refresh() self.lock = true; local v = get() or minv; s:SetValue(v); show(v); self.lock = nil end
    f:Refresh()
    return f
end

-- Selector cíclico ( < valor > ). list = { {value, text}, ... }
function CdG.Cycle(parent, label, list, get, set)
    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(260); f:SetHeight(24)
    f.label = CdG.Text(f, 11); f.label:SetPoint("LEFT", 0, 0); f.label:SetText(label)
    f.next = CdG.Button(f, ">", 22, 22); f.next:SetPoint("RIGHT", 0, 0)
    f.box = CreateFrame("Frame", nil, f); f.box:SetHeight(22); f.box:SetWidth(120)
    f.box:SetPoint("RIGHT", f.next, "LEFT", -2, 0); CdG.Flat(f.box, "input")
    f.val = CdG.Text(f.box, 11, "gold"); f.val:SetPoint("CENTER")
    f.prev = CdG.Button(f, "<", 22, 22); f.prev:SetPoint("RIGHT", f.box, "LEFT", -2, 0)
    local function idx()
        local cur = get()
        for i, it in ipairs(type(list) == "function" and list() or list) do if it[1] == cur then return i end end
        return 1
    end
    function f:Refresh()
        local l = type(list) == "function" and list() or list
        local it = l[idx()]
        self.val:SetText(it and it[2] or "?")
    end
    local function step(d)
        local l = type(list) == "function" and list() or list
        if #l == 0 then return end
        local i = ((idx() - 1 + d) % #l) + 1
        set(l[i][1]); f:Refresh()
    end
    f.next:SetScript("OnClick", function() step(1) end)
    f.prev:SetScript("OnClick", function() step(-1) end)
    f:Refresh()
    return f
end

-- Muestra de color con selector de Blizzard. getc() -> {r,g,b,a}
function CdG.Swatch(parent, label, getc, onchange)
    local f = CreateFrame("Button", nil, parent)
    f:SetWidth(260); f:SetHeight(22)
    f.sw = CreateFrame("Frame", nil, f); f.sw:SetWidth(30); f.sw:SetHeight(16); f.sw:SetPoint("LEFT")
    CdG.Flat(f.sw, "input")
    f.col = f.sw:CreateTexture(nil, "OVERLAY"); f.col:SetTexture(FLAT)
    f.col:SetPoint("TOPLEFT", 2, -2); f.col:SetPoint("BOTTOMRIGHT", -2, 2)
    f.text = CdG.Text(f, 11); f.text:SetPoint("LEFT", f.sw, "RIGHT", 8, 0); f.text:SetText(label)
    function f:Refresh() local c = getc(); self.col:SetVertexColor(c.r, c.g, c.b, 1) end
    f:SetScript("OnClick", function(self)
        local c = getc()
        local prev = { r = c.r, g = c.g, b = c.b, a = c.a }
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacity = 1 - (c.a or 1)
        ColorPickerFrame.previousValues = prev
        ColorPickerFrame.func = function()
            c.r, c.g, c.b = ColorPickerFrame:GetColorRGB(); c.a = 1 - OpacitySliderFrame:GetValue()
            self:Refresh(); onchange()
        end
        ColorPickerFrame.opacityFunc = ColorPickerFrame.func
        ColorPickerFrame.cancelFunc = function()
            c.r, c.g, c.b, c.a = prev.r, prev.g, prev.b, prev.a
            self:Refresh(); onchange()
        end
        ColorPickerFrame:SetColorRGB(c.r, c.g, c.b)
        ShowUIPanel(ColorPickerFrame)
    end)
    f:Refresh()
    return f
end

function CdG.SectionLabel(parent, text, x, y)
    local fs = CdG.Text(parent, 9, "muted")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

-- ============================================================================
-- Estilo "estandarte de guerra": marcos dorados, cuero oscuro y letra Morpheus
-- ============================================================================
local MEDIA = "Interface\\AddOns\\CampanasDeGuerra\\media\\"
local TITLE_FONT = "Fonts\\MORPHEUS.TTF"
CdG.MEDIA, CdG.TITLE_FONT = MEDIA, TITLE_FONT
C.goldDark = { 0.55, 0.43, 0.20, 1 }
C.plate    = { 0.07, 0.25, 0.42, 1 }
C.orange   = { 1.00, 0.55, 0.10, 1 }
C.mine     = { 0.95, 0.78, 0.15, 1 }
C.lumber   = { 0.45, 0.75, 0.30, 1 }

-- marco principal: cuero oscuro con borde dorado de diálogo
function CdG.Ornate(f, alpha)
    f:SetBackdrop({ bgFile = MEDIA .. "panelbg", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 256, edgeSize = 26, insets = { left = 7, right = 7, top = 7, bottom = 7 } })
    f:SetBackdropColor(1, 1, 1, alpha or 1)
    f:SetBackdropBorderColor(1, 1, 1, 1)
end

-- caja hundida (listas, secciones)
function CdG.Inset(f, alpha)
    f:SetBackdrop({ bgFile = FLAT, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    f:SetBackdropColor(0.04, 0.035, 0.03, alpha or 0.82)
    f:SetBackdropBorderColor(C.goldDark[1], C.goldDark[2], C.goldDark[3], 0.9)
end

function CdG.Title(parent, size, role)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(TITLE_FONT, size or 16)
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetTextColor(rgba(C[role or "gold"]))
    return fs
end

-- cabecera de sección con líneas doradas a los lados ("— ZONAS DE CONTROL —")
function CdG.Header(parent, text)
    local h = CreateFrame("Frame", nil, parent)
    h:SetHeight(14)
    h.text = CdG.Text(h, 10, "gold"); h.text:SetPoint("CENTER")
    h.l = h:CreateTexture(nil, "ARTWORK"); h.l:SetTexture(FLAT); h.l:SetHeight(1)
    h.l:SetPoint("LEFT", 6, 0); h.l:SetPoint("RIGHT", h.text, "LEFT", -8, 0)
    h.l:SetGradientAlpha("HORIZONTAL", C.gold[1], C.gold[2], C.gold[3], 0, C.gold[1], C.gold[2], C.gold[3], 0.7)
    h.r = h:CreateTexture(nil, "ARTWORK"); h.r:SetTexture(FLAT); h.r:SetHeight(1)
    h.r:SetPoint("RIGHT", -6, 0); h.r:SetPoint("LEFT", h.text, "RIGHT", 8, 0)
    h.r:SetGradientAlpha("HORIZONTAL", C.gold[1], C.gold[2], C.gold[3], 0.7, C.gold[1], C.gold[2], C.gold[3], 0)
    function h:SetText(t) self.text:SetText(t) end
    h:SetText(text or "")
    return h
end

-- placa azul con borde dorado ("Siguiente objetivo")
function CdG.Plate(parent, w, h)
    local p = CreateFrame("Frame", nil, parent)
    p:SetWidth(w); p:SetHeight(h)
    p:SetBackdrop({ bgFile = FLAT, edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    p:SetBackdropColor(rgba(C.plate))
    p.shine = p:CreateTexture(nil, "ARTWORK"); p.shine:SetTexture(FLAT)
    p.shine:SetPoint("TOPLEFT", 5, -5); p.shine:SetPoint("TOPRIGHT", -5, -5); p.shine:SetHeight(h / 2 - 4)
    p.shine:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 0.6, 0.8, 1, 0.18)
    p.text = CdG.Text(p, 13, "gold"); p.text:SetPoint("CENTER", 0, 0)
    return p
end

-- escudo de facción dentro de un aro dorado
function CdG.Crest(parent, size)
    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(size); f:SetHeight(size)
    f.bg = f:CreateTexture(nil, "BACKGROUND"); f.bg:SetTexture(MEDIA .. "circle"); f.bg:SetAllPoints()
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("TOPLEFT", size * 0.14, -size * 0.12); f.icon:SetPoint("BOTTOMRIGHT", -size * 0.06, size * 0.04)
    f.ring = f:CreateTexture(nil, "OVERLAY"); f.ring:SetTexture(MEDIA .. "ring"); f.ring:SetAllPoints()
    f.ring:SetVertexColor(rgba(C.gold))
    function f:SetFaction(fk)
        if fk == "H" then
            self.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde"); self.bg:SetVertexColor(0.35, 0.05, 0.04, 1)
        else
            self.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance"); self.bg:SetVertexColor(0.05, 0.12, 0.35, 1)
        end
        self.icon:SetTexCoord(0, 0.625, 0, 0.625)
    end
    return f
end

-- botón de guerra: fondo oscuro, borde dorado, icono a la izquierda
function CdG.WarButton(parent, label, icon, w, h)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(w or 120); b:SetHeight(h or 24)
    b:SetBackdrop({ bgFile = FLAT, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    b:SetBackdropColor(0.10, 0.08, 0.06, 0.95)
    b:SetBackdropBorderColor(C.goldDark[1], C.goldDark[2], C.goldDark[3], 1)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetWidth((h or 24) - 8); b.icon:SetHeight((h or 24) - 8)
    b.icon:SetPoint("LEFT", 6, 0)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.label = CdG.Text(b, 11, "gold")
    if icon then
        b.icon:SetTexture(icon)
        b.label:SetPoint("LEFT", b.icon, "RIGHT", 6, 0); b.label:SetPoint("RIGHT", -6, 0)
    else
        b.icon:Hide()
        b.label:SetPoint("LEFT", 6, 0); b.label:SetPoint("RIGHT", -6, 0)
    end
    b.label:SetJustifyH(icon and "LEFT" or "CENTER")
    b.label:SetText(label or "")
    b.hl = b:CreateTexture(nil, "HIGHLIGHT"); b.hl:SetTexture(FLAT)
    b.hl:SetPoint("TOPLEFT", 3, -3); b.hl:SetPoint("BOTTOMRIGHT", -3, 3); b.hl:SetVertexColor(1, 0.85, 0.4, 0.10)
    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(rgba(C.gold))
        if self.tip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(self.label:GetText() or "", 1, 0.82, 0.3)
            GameTooltip:AddLine(type(self.tip) == "function" and self.tip() or self.tip, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(rgba(C.goldDark)); GameTooltip:Hide() end)
    function b:SetLabel(t) self.label:SetText(t) end
    function b:SetEnabledLook(on)
        self.label:SetTextColor(rgba(on and C.gold or C.muted))
        self.icon:SetDesaturated(not on)
    end
    function b:SetRed(on)
        if on then self:SetBackdropColor(0.40, 0.06, 0.05, 0.95) else self:SetBackdropColor(0.10, 0.08, 0.06, 0.95) end
    end
    return b
end

-- barra de progreso con texto centrado
function CdG.Progress(parent, h)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(h or 12)
    f:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    f:SetBackdropColor(0.03, 0.03, 0.03, 0.9)
    f:SetBackdropBorderColor(0, 0, 0, 1)
    f.fill = f:CreateTexture(nil, "ARTWORK"); f.fill:SetTexture(FLAT)
    f.fill:SetPoint("TOPLEFT", 1, -1); f.fill:SetPoint("BOTTOMLEFT", 1, 1)
    f.fill2 = f:CreateTexture(nil, "ARTWORK"); f.fill2:SetTexture(FLAT)
    f.fill2:SetPoint("TOPRIGHT", -1, -1); f.fill2:SetPoint("BOTTOMRIGHT", -1, 1); f.fill2:Hide()
    f.gloss = f:CreateTexture(nil, "OVERLAY"); f.gloss:SetTexture(FLAT)
    f.gloss:SetPoint("TOPLEFT", 1, -1); f.gloss:SetPoint("TOPRIGHT", -1, -1); f.gloss:SetHeight((h or 12) / 2)
    f.gloss:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.16)
    f.text = CdG.Text(f, math.max(8, (h or 12) - 3)); f.text:SetPoint("CENTER", 0, 0)
    function f:SetValue(v, col)
        local w = math.max(0.01, (self:GetWidth() - 2) * math.max(0, math.min(1, v or 0)))
        self.fill:SetWidth(w)
        if col then self.fill:SetVertexColor(rgba(col)) end
        self.fill2:Hide()
    end
    -- barra doble (dominación): izquierda a, derecha el resto
    function f:SetSplit(a, colA, colB)
        local full = self:GetWidth() - 2
        self.fill:SetWidth(math.max(0.01, full * a)); self.fill:SetVertexColor(rgba(colA))
        self.fill2:SetWidth(math.max(0.01, full * (1 - a))); self.fill2:SetVertexColor(rgba(colB)); self.fill2:Show()
    end
    return f
end

-- banderola colgante de la cabecera (azul o roja)
function CdG.Drape(parent, w, h, col)
    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(w); f:SetHeight(h)
    f.t = f:CreateTexture(nil, "ARTWORK"); f.t:SetTexture(FLAT); f.t:SetAllPoints()
    f.t:SetGradientAlpha("VERTICAL", col[1] * 0.45, col[2] * 0.45, col[3] * 0.45, 1, col[1] * 0.9, col[2] * 0.9, col[3] * 0.9, 1)
    f.edge = f:CreateTexture(nil, "OVERLAY"); f.edge:SetTexture(FLAT); f.edge:SetHeight(2)
    f.edge:SetPoint("BOTTOMLEFT"); f.edge:SetPoint("BOTTOMRIGHT"); f.edge:SetVertexColor(rgba(C.gold))
    return f
end

-- ventana con marco, título Morpheus y botón de cerrar
function CdG.Window(name, w, h, titleText)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetWidth(w); f:SetHeight(h)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true); f:SetClampedToScreen(true)
    f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    CdG.Ornate(f)
    f.title = CdG.Title(f, 22); f.title:SetPoint("TOP", 0, -16); f.title:SetText(titleText or "")
    f.close = CdG.WarButton(f, "X", nil, 26, 24)
    f.close:SetPoint("TOPRIGHT", -12, -12)
    f.close:SetScript("OnClick", function() f:Hide() end)
    f:Hide()
    if name then table.insert(UISpecialFrames, name) end
    return f
end

-- formato de tiempo m:ss
function CdG.Clock(s)
    s = math.max(0, math.floor(s or 0))
    if s >= 3600 then return format("%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60) end
    return format("%d:%02d", s / 60, s % 60)
end
function CdG.Ago(t)
    local d = time() - (t or time())
    if d < 45 then return "ahora mismo" end
    if d < 3600 then return format("hace %d min", math.max(1, d / 60)) end
    if d < 86400 then return format("hace %d h", d / 3600) end
    return format("hace %d d", d / 86400)
end
