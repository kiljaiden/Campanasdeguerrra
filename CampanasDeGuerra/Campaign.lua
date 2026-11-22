-- ============================================================================
-- Campañas de Guerra - Motor de campaña (diseño propio para 3.3.5)
--
-- Captura:   quédate a pie dentro del círculo. Más aliados que enemigos: avanza.
--            Iguales: se congela. Más enemigos: retrocede. Si sales, decae.
-- Frentes:   caminos de puntos entre dos capitales. Solo puedes atacar un punto
--            conectado a otro de tu facción. Tomar la capital rival gana el frente.
-- Recursos:  monedas de guerra (minas, bajas) para Atacar / Reforzar; madera
--            (aserraderos) para donar a la dominación semanal de tu facción.
-- Sincronía: canal oculto + hermandad + grupo/banda. Sin servidor.
-- ============================================================================
CdG = CdG or {}
local CdG = CdG

local Engine = CreateFrame("Frame", "CdGEngine", UIParent)
CdG.Engine = Engine

local CHANNEL, PREFIX = "CampanasGuerra", "CdG2"
local TICK = 0.5
local ENEMY_WINDOW = 10          -- segundos que un enemigo visto cuenta como "cerca"
local PRESENCE_WINDOW = 7        -- segundos que vale un aviso de presencia de otro jugador
local COST = 25                  -- monedas por Atacar / Reforzar
local MAX_COINS, MAX_WOOD, DONATE = 100, 500, 500
local CALL_CD = 4 * 3600         -- llamada a las armas: una por facción cada 4 h
local BOUNTY_STREAK = 10
CdG.COST, CdG.MAX_COINS, CdG.MAX_WOOD = COST, MAX_COINS, MAX_WOOD

local myFaction, myName, myFK
local db, char
local curMap, curFront           -- mapa de zona y frente donde estás
local px, py                     -- tu posición en curMap
local progress = {}              -- [id] = segundos acumulados de tu captura
local enemies = {}               -- [nombre] = GetTime()
local presence = {}              -- [id] = { [nombre] = { f, t } }
local remoteCaps = {}            -- [id] = { f, prog, total, who, t }
local events = {}                -- actividad reciente { t, fk, kind, f }
local peers = {}                 -- [nombre] = time()
local lastDefend, nemesisSeen = {}, {}
CdG.generals, CdG.bounties = {}, {}

local function now() return time() end
local function Changed() Engine.dirty = true end
CdG.Changed = Changed

-- ---------------------------------------------------------------------------
-- Utilidades de facción y texto
-- ---------------------------------------------------------------------------
function CdG.FactionName(code) return code == "A" and FACTION_ALLIANCE or (code == "H" and FACTION_HORDE) or "Neutral" end
function CdG.FactionColor(code) local C = CdG.C return code == "A" and C.alliance or (code == "H" and C.horde) or C.neutral end
function CdG.Enemy(code) return code == "A" and "H" or "A" end
local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage("|cffdc3337Campañas de Guerra:|r " .. msg) end
CdG.Print = Print
local function Notice(msg, code)
    if not db.alerts then return end
    local c = CdG.FactionColor(code)
    RaidNotice_AddMessage(RaidWarningFrame, msg, { r = c[1], g = c[2], b = c[3] })
end
local function Clean(s) return (tostring(s or ""):gsub("[%^:|]", "")) end

-- semana de campaña: empieza el miércoles a las 04:00
local WEEK_OFFSET = 6 * 86400 + 4 * 3600
function CdG.WeekId(t) return math.floor(((t or now()) - WEEK_OFFSET) / 604800) end
function CdG.WeekStart(w) return (w or CdG.WeekId()) * 604800 + WEEK_OFFSET end

-- ---------------------------------------------------------------------------
-- Base de datos
-- ---------------------------------------------------------------------------
local DEFAULTS = {
    enabled = true, sync = true, markers = true, minimap = true, hud = true, alerts = true, sound = true,
    chat = true, nemesis = true, guildalerts = true, panelonmap = true, mapmode = "full",
    speed = 1, needpvp = true, needfoot = true, scale = 1, mapscale = 0.85, mapalpha = 0.8, dockbars = true,
    tooltip = true, links = true, labels = true, continent = true,
}
local CHAR_DEFAULTS = { coins = 0, wood = 0, glory = 0, rank = 1, kills = 0, captures = 0, defends = 0,
    keeps = 0, outposts = 0, streak = 0, best = 0, deaths = 0 }

local function NewBoard() return { week = CdG.WeekId(), players = {}, keeps = {}, outposts = {}, seen = {} } end

local WeeklyReset -- definida más abajo (usa Domination)

local function InitDB()
    CampanasDB = CampanasDB or {}
    CampanasDB.campaign = CampanasDB.campaign or {}
    db = CampanasDB.campaign
    for k, v in pairs(DEFAULTS) do if db[k] == nil then db[k] = v end end
    if type(db.st) ~= "table" then db.st = {} end
    db.mines = db.mines or {}
    db.don = db.don or { A = 0, H = 0, seen = {} }
    db.don.seen = db.don.seen or {}
    db.lastcall = db.lastcall or {}
    db.fame = db.fame or {}
    db.log = db.log or {}
    if not db.board or not db.board.seen then db.board = NewBoard() end
    db.state, db.capturetime, db.expirehours = nil, nil, nil -- formato antiguo
    CampanasDB.chars = CampanasDB.chars or {}
    local key = myName .. " - " .. (GetRealmName() or "")
    CampanasDB.chars[key] = CampanasDB.chars[key] or {}
    char = CampanasDB.chars[key]
    for k, v in pairs(CHAR_DEFAULTS) do if char[k] == nil then char[k] = v end end
    char.faction = myFK
    CdG.db, CdG.char = db, char
    if db.week ~= CdG.WeekId() then
        if db.week then WeeklyReset() else db.week = CdG.WeekId() end
    end
end

-- ---------------------------------------------------------------------------
-- Estado de los nodos
-- ---------------------------------------------------------------------------
-- dueño, momento, jugador, hermandad
function CdG.GetOwner(id)
    local s = db and db.st[id]
    if s and s.o then return s.o, s.t, s.p, s.g end
    local n = CdG.NODES[id]
    if n and n.kind == "capital" then return n.home end
    return nil
end
local GetOwner = CdG.GetOwner

function CdG.Reinforcements(id) local s = db and db.st[id]; return s and s.rf or 0 end

local WAR = { point = true, capital = true, keep = true, outpost = true }
CdG.WAR = WAR

-- ¿puede la facción fk atacar este nodo?
function CdG.CanAttack(n, fk)
    if not WAR[n.kind] then return false end
    if GetOwner(n.id) == fk then return false end
    if n.kind == "keep" or n.kind == "outpost" then return true end
    if n.kind == "capital" and n.home == fk then return true end -- recuperar tu propia capital
    for _, l in ipairs(n.links) do if GetOwner(l.id) == fk then return true end end
    return false
end

-- tiempo total de captura para la facción fk
function CdG.CaptureTime(n, fk, mine)
    local t = n.time * (db.speed or 1)
    if n.front and n.kind == "point" and n.front.outpost and GetOwner(n.front.outpost.id) == CdG.Enemy(fk) then t = t + 30 end
    t = t + CdG.Reinforcements(n.id) * 60
    if mine and char.attack then t = t - 60 end
    return math.max(15, t)
end

function CdG.FrontScore(f)
    local a, h = 0, 0
    for _, n in ipairs(f.points) do
        local o = GetOwner(n.id)
        if o == "A" then a = a + 1 elseif o == "H" then h = h + 1 end
    end
    return a, h, #f.points
end

-- frente ganado: la capital rival en tus manos
function CdG.FrontWinner(f)
    if GetOwner(f.caps.H.id) == "A" then return "A" end
    if GetOwner(f.caps.A.id) == "H" then return "H" end
end

local WEIGHT = { point = 1, capital = 3, keep = 3, outpost = 1 }
function CdG.Domination()
    if not db then return 50, 50 end
    local a, h = 0, 0
    for id, s in pairs(db.st) do
        local n = CdG.NODES[id]
        if n and WEIGHT[n.kind] and n.kind ~= "capital" then
            local w = WEIGHT[n.kind]
            if s.o == "A" then a = a + w elseif s.o == "H" then h = h + w end
        end
    end
    for _, f in ipairs(CdG.FRONTS) do
        local w = CdG.FrontWinner(f)
        if w == "A" then a = a + 10 elseif w == "H" then h = h + 10 end
    end
    local pa = (a + h > 0) and (a / (a + h) * 100) or 50
    pa = pa + (db.don.A or 0) - (db.don.H or 0)
    pa = math.max(5, math.min(95, pa))
    return pa, 100 - pa
end

function CdG.Featured()
    local day = math.floor((now() - 4 * 3600) / 86400)
    return CdG.FRONTS[(day % #CdG.FRONTS) + 1]
end

-- ---------------------------------------------------------------------------
-- Clasificación
-- ---------------------------------------------------------------------------
local function Entry(name, f)
    local e = db.board.players[name]
    if not e then e = { f = f, k = 0, c = 0, kw = 0, ow = 0, t = 0 }; db.board.players[name] = e end
    return e
end
CdG.BoardEntry = Entry

function CdG.GuildRanking(board)
    board = board or db.board
    local g = {}
    for _, e in pairs(board.players) do
        if e.g and e.g ~= "" then
            local r = g[e.g] or { name = e.g, f = e.f, k = 0, c = 0 }
            r.k, r.c = r.k + (e.k or 0), r.c + (e.c or 0)
            g[e.g] = r
        end
    end
    local list = {}
    for _, r in pairs(g) do r.score = r.k + r.c * 5; table.insert(list, r) end
    table.sort(list, function(a, b) return a.score > b.score end)
    return list
end

function CdG.Nemesis()
    local list = {}
    for name, e in pairs(db.board.players) do
        if e.f and e.f ~= myFK and (e.k or 0) > 0 then table.insert(list, { name = name, k = e.k }) end
    end
    table.sort(list, function(a, b) return a.k > b.k end)
    local set = {}
    for i = 1, math.min(5, #list) do set[list[i].name] = i end
    return set
end

function WeeklyReset()
    -- campeones de la semana que termina al Salón de la Fama
    local b = db.board
    if b and b.players and next(b.players) then
        local fame = { week = b.week }
        for name, e in pairs(b.players) do
            if (e.k or 0) > (fame.kills or 0) then fame.player, fame.kills, fame.pf = name, e.k, e.f end
            if (e.c or 0) > (fame.caps or 0) then fame.capturer, fame.caps, fame.cf = name, e.c, e.f end
        end
        local guilds = CdG.GuildRanking(b)
        if guilds[1] then fame.guild, fame.gscore, fame.gf = guilds[1].name, guilds[1].score, guilds[1].f end
        fame.domA, fame.domH = CdG.Domination()
        table.insert(db.fame, 1, fame)
        while #db.fame > 20 do table.remove(db.fame) end
    end
    db.st, db.mines, db.don, db.lastcall = {}, {}, { A = 0, H = 0, seen = {} }, {}
    db.board = NewBoard()
    db.week = CdG.WeekId()
    for k in pairs(progress) do progress[k] = nil end
end

local function AddGlory(v)
    char.glory = (char.glory or 0) + v
    local idx, name = CdG.RankFor(char.glory)
    if idx > (char.rank or 1) then
        char.rank = idx
        if db.alerts then RaidNotice_AddMessage(RaidWarningFrame, "¡Nuevo rango: " .. name .. "!", { r = 1, g = 0.82, b = 0.3 }) end
        Print("Has ascendido a |cffffcc55" .. name .. "|r.")
    end
end

-- ---------------------------------------------------------------------------
-- Actividad reciente
-- ---------------------------------------------------------------------------
local function AddEvent(fk, kind, f)
    if not fk or fk == "" then return end
    table.insert(events, 1, { t = now(), fk = fk, kind = kind, f = f })
    while #events > 200 do table.remove(events) end
end
local function Log(text)
    table.insert(db.log, 1, { t = now(), text = text })
    while #db.log > 60 do table.remove(db.log) end
    Changed()
end
CdG.Log = Log

-- frentes ordenados por actividad de los últimos 5 min: { front, last, a, h }
function CdG.RecentActivity()
    local by, list = {}, {}
    local limit = now() - 300
    for _, e in ipairs(events) do
        if e.t >= limit then
            local r = by[e.fk]
            if not r then r = { front = CdG.FRONT_BY_KEY[e.fk], last = e.t, a = 0, h = 0 }; by[e.fk] = r end
            if e.kind == "kill" then if e.f == "A" then r.a = r.a + 1 else r.h = r.h + 1 end end
            if e.t > r.last then r.last = e.t end
        end
    end
    for _, r in pairs(by) do if r.front then table.insert(list, r) end end
    table.sort(list, function(a, b) return a.last > b.last end)
    return list
end

function CdG.ActiveCaptures()
    local list = {}
    local S = Engine.state
    if S.node and S.mode == "capture" then
        table.insert(list, { node = S.node, f = myFK, prog = S.prog, total = S.total, who = myName, mine = true })
    end
    for id, c in pairs(remoteCaps) do
        if now() - c.t < 12 then
            if not (S.node and S.node.id == id and S.mode == "capture") then
                table.insert(list, { node = CdG.NODES[id], f = c.f, prog = c.prog, total = c.total, who = c.who })
            end
        else remoteCaps[id] = nil end
    end
    return list
end

function CdG.CaptureOn(id)
    local S = Engine.state
    if S.node and S.node.id == id and S.mode == "capture" then return myFK, S.prog, S.total end
    local c = remoteCaps[id]
    if c and now() - c.t < 12 then return c.f, c.prog + (now() - c.t), c.total end
end

function CdG.Peers()
    local n = 0
    for name, t in pairs(peers) do if now() - t < 600 then n = n + 1 else peers[name] = nil end end
    return n
end

-- ---------------------------------------------------------------------------
-- Sincronización
-- ---------------------------------------------------------------------------
local queue, lastSend = {}, 0
local function ChannelId() local id = GetChannelName(CHANNEL); return (id and id > 0) and id or nil end
CdG.SyncChannelId = ChannelId

local function RawSend(payload)
    local id = ChannelId()
    if id then SendChatMessage(PREFIX .. " " .. payload, "CHANNEL", nil, id) end
    if IsInGuild() then SendAddonMessage(PREFIX, payload, "GUILD") end
    if GetNumRaidMembers() > 0 then SendAddonMessage(PREFIX, payload, "RAID")
    elseif GetNumPartyMembers() > 0 then SendAddonMessage(PREFIX, payload, "PARTY") end
end

local function Send(payload, urgent)
    if not db.sync then return end
    if #queue > 40 then -- descarta primero los avisos de presencia
        for i = 1, #queue do if queue[i]:sub(1, 2) == "P^" then table.remove(queue, i) break end end
    end
    if urgent then table.insert(queue, 1, payload) else table.insert(queue, payload) end
end
CdG.Send = Send
function CdG.RequestSync() Send("R", true) end

local function EntryPayload(name, e)
    return format("L^%s^%s^%s^%s^%d^%s^%d^%d^%d^%d^%d^%d", name, e.f or "", e.cl or "", e.r or "", e.x or 2, Clean(e.g),
        e.k or 0, e.c or 0, e.kw or 0, e.ow or 0, e.rk or 1, e.t or 0)
end
local function MyEntryPayload()
    local e = Entry(myName, myFK)
    local _, cl = UnitClass("player")
    local _, race = UnitRace("player")
    e.f, e.cl, e.r, e.x, e.g, e.rk, e.t = myFK, cl, race, UnitSex("player"), GetGuildInfo("player") or "", char.rank, now()
    return EntryPayload(myName, e)
end
local lastEntrySend = 0
local function SendMyEntry(force)
    if force or now() - lastEntrySend > 30 then lastEntrySend = now(); Send(MyEntryPayload()) else Engine.entryPending = true end
end

local function ApplyEntry(p)
    local name, f = p[2], p[3]
    if not name or name == "" or name == myName or (f ~= "A" and f ~= "H") then return end
    local t = tonumber(p[13]) or 0
    local e = Entry(name, f)
    if (e.t or 0) > t then return end
    e.f, e.cl, e.r, e.x, e.g = f, p[4], p[5], tonumber(p[6]), p[7]
    e.k, e.c, e.kw, e.ow, e.rk, e.t = tonumber(p[8]) or 0, tonumber(p[9]) or 0, tonumber(p[10]) or 0, tonumber(p[11]) or 0, tonumber(p[12]) or 1, t
end

local function CreditGuildObjective(n, o, g, uid)
    if not g or g == "" or db.board.seen[uid] then return end
    db.board.seen[uid] = true
    local tbl = n.kind == "keep" and db.board.keeps or db.board.outposts
    local k = n.id .. "|" .. g
    local r = tbl[k] or { id = n.id, g = g, f = o, n = 0 }
    r.n, r.f = r.n + 1, o
    tbl[k] = r
end

-- aplica una captura (propia o recibida). live = aviso en directo
local function ApplyCapture(id, o, t, who, g, live)
    local n = CdG.NODES[id]
    if not n or (o ~= "A" and o ~= "H") then return end
    t = tonumber(t) or 0
    local cur = db.st[id]
    if cur and (cur.t or 0) >= t then return end
    local prev = GetOwner(id)
    if who == "" then who = nil end
    if g == "" then g = nil end
    db.st[id] = { o = o, t = t, p = who, g = g, rf = 0 }
    remoteCaps[id] = nil
    progress[id] = nil
    if n.kind == "keep" or n.kind == "outpost" then CreditGuildObjective(n, o, g, id .. "@" .. t) end
    if live and who then
        AddEvent(n.front and n.front.key or n.id, "cap", o)
        local where = n.front and n.front.name or n.zone or ""
        Log(format("%s capturó %s (%s) para la %s", who, n.name, where, CdG.FactionName(o)))
        if now() - t < 180 then
            if prev == myFK and o ~= myFK then
                Notice(format("¡%s ha caído en manos de la %s!", n.name, CdG.FactionName(o)), o)
                if db.sound then PlaySound("RaidWarning") end
            elseif db.chat and o == myFK then
                Print(format("%s ha tomado |cffffcc55%s|r.", who, n.name))
            end
            if n.kind == "keep" and g and db.guildalerts then
                Print(format("La hermandad |cffffcc55<%s>|r controla ahora %s.", g, n.name))
            end
            if n.kind == "capital" and n.front and n.home ~= o then
                Notice(format("¡La %s ha ganado el frente de %s!", CdG.FactionName(o), n.front.name), o)
            end
        end
    end
    Changed()
end

local replyTimer, othersReplied
local function SendStateReply()
    local buf = "S"
    for id, s in pairs(db.st) do
        if s.o then
            local seg = format("^%s:%s:%d:%d:%s", id, s.o, s.t or 0, s.rf or 0, Clean(s.g))
            if #buf + #seg > 230 then Send(buf); buf = "S" end
            buf = buf .. seg
        end
    end
    if buf ~= "S" then Send(buf) end
    Send(format("T^%d^%d^%d^%d", db.don.A or 0, db.don.H or 0, db.lastcall.A or 0, db.lastcall.H or 0))
    Send(MyEntryPayload())
    local list = {}
    for name, e in pairs(db.board.players) do if name ~= myName and e.cl and e.cl ~= "" then table.insert(list, { name = name, e = e }) end end
    table.sort(list, function(a, b) return (a.e.k or 0) + (a.e.c or 0) * 5 > (b.e.k or 0) + (b.e.c or 0) * 5 end)
    for i = 1, math.min(12, #list) do Send(EntryPayload(list[i].name, list[i].e)) end
end

local function HandlePayload(payload, sender)
    if not sender or sender == myName then return end
    peers[sender] = now()
    local p = { strsplit("^", payload) }
    local kind = p[1]
    if kind == "C" then
        ApplyCapture(p[2], p[3], p[4], p[5], p[6], true)
    elseif kind == "S" then
        othersReplied = true
        for i = 2, #p do
            local id, o, t, rf, g = strsplit(":", p[i])
            ApplyCapture(id, o, t, nil, g, false)
            local s = db.st[id or ""]
            if s and tonumber(t) == s.t then s.rf = math.max(s.rf or 0, tonumber(rf) or 0) end
        end
    elseif kind == "R" then
        othersReplied = false
        replyTimer = 1.5 + math.random() * 5
        SendMyEntry(true)
    elseif kind == "T" then
        db.don.A = math.max(db.don.A or 0, tonumber(p[2]) or 0)
        db.don.H = math.max(db.don.H or 0, tonumber(p[3]) or 0)
        db.lastcall.A = math.max(db.lastcall.A or 0, tonumber(p[4]) or 0)
        db.lastcall.H = math.max(db.lastcall.H or 0, tonumber(p[5]) or 0)
        Changed()
    elseif kind == "L" then
        ApplyEntry(p); Changed()
    elseif kind == "P" then -- presencia / captura en curso: id, facción, progreso, total
        local id, f = p[2], p[3]
        local n = CdG.NODES[id or ""]
        if not n then return end
        presence[id] = presence[id] or {}
        presence[id][sender] = { f = f, t = GetTime() }
        local prog, total = tonumber(p[4]) or 0, tonumber(p[5]) or 0
        if total > 0 then
            remoteCaps[id] = { f = f, prog = prog, total = total, who = sender, t = now() }
            AddEvent(n.front and n.front.key or id, "att", f)
            if f ~= myFK and GetOwner(id) == myFK and db.alerts and (not lastDefend["w" .. id] or GetTime() - lastDefend["w" .. id] > 120) then
                lastDefend["w" .. id] = GetTime()
                Notice(format("¡%s está siendo atacado!", n.name), f)
            end
        end
        Changed()
    elseif kind == "K" then -- baja: frente, facción del asesino, asesino, víctima
        AddEvent(p[2], "kill", p[3]); Changed()
    elseif kind == "G" then -- general: frente, facción, nombre, x, y, estado
        local key = (p[2] or "") .. ":" .. (p[3] or "")
        local g = CdG.generals[key]
        if p[7] == "on" then
            if (not g or g.name ~= p[4]) and p[3] == myFK and db.chat then
                local f = CdG.FRONT_BY_KEY[p[2]]
                Print(format("|cffffcc55%s|r es ahora el General de la %s en %s.", p[4], CdG.FactionName(p[3]), f and f.name or "?"))
            end
            CdG.generals[key] = { name = p[4], f = p[3], fk = p[2], x = tonumber(p[5]), y = tonumber(p[6]), t = now() }
        elseif p[7] == "dead" then
            Notice(format("¡El General %s (%s) ha caído!", p[4], CdG.FactionName(p[3])), p[3])
            CdG.generals[key] = nil
        elseif g and g.name == p[4] then
            CdG.generals[key] = nil
        end
        Changed()
    elseif kind == "W" then -- llamada a las armas: frente, lugar, facción, nombre, momento
        local t = tonumber(p[6]) or now()
        if p[4] == "A" or p[4] == "H" then db.lastcall[p[4]] = math.max(db.lastcall[p[4]] or 0, t) end
        if p[4] == myFK and now() - t < 300 then
            local f = CdG.FRONT_BY_KEY[p[2]]
            local where = (p[3] and p[3] ~= "") and p[3] or (f and f.name or "?")
            Notice(format("¡LLAMADA A LAS ARMAS! %s pide refuerzos en %s", p[5], where), myFK)
            if db.sound then PlaySound("RaidWarning") end
            Print(format("|cffff5544Llamada a las armas|r de %s: %s.", p[5], where))
        end
        Changed()
    elseif kind == "B" then -- recompensa: nombre, facción, racha, frente, x, y  (racha 0 = fin)
        local s = tonumber(p[4]) or 0
        if s <= 0 then CdG.bounties[p[2]] = nil
        else
            local was = CdG.bounties[p[2]]
            CdG.bounties[p[2]] = { f = p[3], s = s, fk = p[5], x = tonumber(p[6]), y = tonumber(p[7]), t = now() }
            if not was and db.chat then
                if p[3] ~= myFK then Print(format("|cffff3333%s|r es una recompensa (%d bajas seguidas). ¡Abátelo!", p[2], s))
                else Print(format("%s lleva %d bajas seguidas: ahora es una recompensa para el enemigo.", p[2], s)) end
            end
        end
        Changed()
    elseif kind == "D" then -- donación: facción, id, nombre
        if (p[2] == "A" or p[2] == "H") and p[3] and not db.don.seen[p[3]] then
            db.don.seen[p[3]] = true
            db.don[p[2]] = (db.don[p[2]] or 0) + 1
            if db.chat and p[2] == myFK then Print(format("%s ha donado madera: +1%% de dominación para la %s.", p[4] or "?", CdG.FactionName(p[2]))) end
            Changed()
        end
    elseif kind == "E" then -- refuerzo: id, nombre
        local s = db.st[p[2] or ""]
        if s then s.rf = math.min(3, (s.rf or 0) + 1) end
        Changed()
    elseif kind == "M" then -- reservas de mina: id, valor, momento
        local m, t = db.mines[p[2] or ""], tonumber(p[4]) or 0
        if CdG.NODES[p[2] or ""] and (not m or (m.t or 0) < t) then db.mines[p[2]] = { v = tonumber(p[3]) or 100, t = t } end
    end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", function(_, _, msg)
    if type(msg) == "string" and msg:sub(1, #PREFIX + 1) == PREFIX .. " " then return true end
end)
for _, ev in ipairs({ "CHAT_MSG_CHANNEL_JOIN", "CHAT_MSG_CHANNEL_LEAVE", "CHAT_MSG_CHANNEL_NOTICE", "CHAT_MSG_CHANNEL_NOTICE_USER" }) do
    ChatFrame_AddMessageEventFilter(ev, function(_, _, msg, _, _, chan, _, _, _, _, chanName)
        for _, s in ipairs({ chanName, chan, msg }) do
            if type(s) == "string" and s:lower():find(CHANNEL:lower(), 1, true) then return true end
        end
    end)
end

local function JoinSyncChannel()
    if not db.sync then return end
    if not ChannelId() then JoinTemporaryChannel(CHANNEL) end
    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        if cf then ChatFrame_RemoveChannel(cf, CHANNEL) end
    end
end
CdG.JoinSyncChannel = JoinSyncChannel

function CdG.SetSync(on)
    db.sync = on
    if on then JoinSyncChannel(); CdG.RequestSync()
    elseif ChannelId() then LeaveChannelByName(CHANNEL) end
end

-- ---------------------------------------------------------------------------
-- Enemigos cercanos
-- ---------------------------------------------------------------------------
local band = bit.band
local HOSTILE_PLAYER = bit.bor(COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_REACTION_HOSTILE)
local function IsHostilePlayer(flags) return flags and band(flags, HOSTILE_PLAYER) == HOSTILE_PLAYER end

local function SeeEnemy(name)
    if not name then return end
    name = name:match("^([^%-]+)") or name
    enemies[name] = GetTime()
    if db.nemesis then
        local nem = CdG.Nemesis()
        if nem[name] and (not nemesisSeen[name] or GetTime() - nemesisSeen[name] > 600) then
            nemesisSeen[name] = GetTime()
            Print(format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t |cffff3333Némesis cerca:|r %s (n.º %d de la semana en bajas).", name, nem[name]))
            if db.sound then PlaySound("RaidWarning") end
        end
    end
end

function CdG.CountEnemies()
    local n, t = 0, GetTime()
    for name, seen in pairs(enemies) do
        if t - seen <= ENEMY_WINDOW then n = n + 1 else enemies[name] = nil end
    end
    return n
end

local function CheckUnit(unit)
    if UnitExists(unit) and UnitIsPlayer(unit) and UnitIsEnemy("player", unit) and not UnitIsDeadOrGhost(unit) then
        SeeEnemy(UnitName(unit))
    end
end

-- ---------------------------------------------------------------------------
-- Posición
-- ---------------------------------------------------------------------------
local function UpdateCurrentMap()
    if WorldMapFrame and WorldMapFrame:IsShown() then return end
    local _, itype = IsInInstance()
    if itype and itype ~= "none" then curMap, curFront = nil, nil
    else
        SetMapToCurrentZone()
        curMap = GetMapInfo()
        if GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel() > 0 then curMap = nil end
        curFront = curMap and CdG.FRONT_BY_MAP[curMap]
    end
    CdG.curMap, CdG.current = curMap, curFront
    Changed()
end
CdG.UpdateCurrentFront = UpdateCurrentMap

function CdG.PlayerPos() return curMap, px, py end

local function NodeAt(x, y)
    local list = curMap and CdG.BY_MAP[curMap]
    if not list then return end
    local best, bd
    for _, n in ipairs(list) do
        local d = CdG.Yards(curMap, x, y, n.x, n.y)
        if d <= n.r and (not bd or d < bd) then best, bd = n, d end
    end
    return best
end

-- servidor con facciones cruzadas: en tu grupo puede haber jugadores del otro bando,
-- así que cada miembro cuenta según su facción real
local grouped = {}
local function GroupInside(n)
    local a, h = 1, 0
    for k in pairs(grouped) do grouped[k] = nil end
    local raid = GetNumRaidMembers()
    local prefix, count = raid > 0 and "raid" or "party", raid > 0 and raid or GetNumPartyMembers()
    for i = 1, count do
        local u = prefix .. i
        if not UnitIsUnit(u, "player") and UnitIsConnected(u) and not UnitIsDeadOrGhost(u) then
            local x, y = GetPlayerMapPosition(u)
            if x and x > 0 and CdG.Yards(n.map, x, y, n.x, n.y) <= n.r then
                grouped[UnitName(u)] = true
                if UnitFactionGroup(u) == myFaction then a = a + 1 else h = h + 1 end
            end
        end
    end
    return a, h
end

local function PresenceCount(n)
    local a, h = 0, 0
    local list = presence[n.id]
    if not list then return 0, 0 end
    for name, e in pairs(list) do
        if GetTime() - e.t > PRESENCE_WINDOW then list[name] = nil
        elseif not grouped[name] then -- los del grupo ya se contaron por su posición
            if e.f == myFK then a = a + 1 else h = h + 1 end
        end
    end
    return a, h
end

-- siguiente objetivo: el punto atacable más cercano del frente indicado (o del actual)
function CdG.NextObjective(front)
    front = front or curFront
    if not front or not front.points then return nil end
    local here = curMap == front.map and px
    local best, bd
    for _, n in ipairs(front.points) do
        if CdG.CanAttack(n, myFK) then
            local d = here and CdG.Yards(curMap, px, py, n.x, n.y)
            if not best or (d and (not bd or d < bd)) then best, bd = n, d end
        end
    end
    if not best and front.outpost and CdG.CanAttack(front.outpost, myFK) then
        best = front.outpost
        if here then bd = CdG.Yards(curMap, px, py, best.x, best.y) end
    end
    return best, bd
end

-- ---------------------------------------------------------------------------
-- Captura
-- ---------------------------------------------------------------------------
local function Captured(n)
    local t = now()
    local g = Clean(GetGuildInfo("player") or "")
    char.captures = char.captures + 1
    local e = Entry(myName, myFK); e.c = (e.c or 0) + 1
    local glory = 25
    if n.kind == "capital" then glory = 60 end
    if n.kind == "keep" then glory = 100; char.keeps = char.keeps + 1; e.kw = (e.kw or 0) + 1 end
    if n.kind == "outpost" then glory = 50; char.outposts = char.outposts + 1; e.ow = (e.ow or 0) + 1 end
    char.attack = nil
    ApplyCapture(n.id, myFK, t, myName, g, false)
    Send(format("C^%s^%s^%d^%s^%s", n.id, myFK, t, myName, g), true)
    AddEvent(n.front and n.front.key or n.id, "cap", myFK)
    Log("Has capturado " .. n.name)
    AddGlory(glory)
    SendMyEntry(true)
    Notice("¡" .. n.name .. " capturado!", myFK)
    if db.sound then PlaySound(myFaction == "Horde" and "PVPFlagCapturedHorde" or "PVPFlagCaptured") end
    if n.kind == "capital" and n.home ~= myFK and n.front then
        Notice(format("¡La %s ha ganado el frente de %s!", CdG.FactionName(myFK), n.front.name), myFK)
    end
end

Engine.state = { mode = nil, node = nil, status = "", pct = 0, prog = 0, total = 0, allies = 0, enemies = 0 }
local lastP, mineAcc, woodAcc = 0, 0, 0

local function Requirements()
    if db.needfoot and (IsMounted() or UnitOnTaxi("player") or (IsFlying and IsFlying())) then return "Desmonta para capturar" end
    if db.needpvp and not UnitIsPVP("player") then return "Activa el JcJ (/pvp) para capturar" end
end

local function Tick()
    local S = Engine.state
    S.mode, S.node, S.status, S.pct, S.prog, S.total = nil, nil, "", 0, 0, 0
    CheckUnit("target"); CheckUnit("mouseover"); CheckUnit("focus")
    S.enemies, S.allies = CdG.CountEnemies(), 0
    if not curMap or UnitIsDeadOrGhost("player") then px = nil; return end
    if WorldMapFrame:IsShown() and GetMapInfo() ~= curMap then return end
    local x, y = GetPlayerMapPosition("player")
    if not x or (x == 0 and y == 0) then return end
    px, py = x, y
    local n = NodeAt(x, y)
    if not n then
        for k, v in pairs(progress) do
            v = v - TICK * 0.5
            progress[k] = v > 0 and v or nil
        end
        return
    end
    S.node = n
    -- recursos
    if n.kind == "mine" then
        S.mode = "mine"
        local m = db.mines[n.id] or { v = 100, t = now() }
        local regen = math.floor((now() - (m.t or now())) / 180)
        if regen > 0 then m.v = math.min(100, m.v + regen); m.t = now() end
        db.mines[n.id] = m
        S.pct, S.prog, S.total = m.v / 100, m.v, 100
        if m.v <= 0 then S.status = "Mina agotada: vuelve más tarde"
        elseif char.coins >= MAX_COINS then S.status = "Bolsa llena (100 monedas)"
        else
            mineAcc = mineAcc + TICK
            S.status = format("Extrayendo… próxima moneda en %d s", math.max(0, 20 - mineAcc))
            if mineAcc >= 20 then
                mineAcc = 0
                char.coins = math.min(MAX_COINS, char.coins + 1)
                m.v, m.t = m.v - 1, now()
                Send(format("M^%s^%d^%d", n.id, m.v, m.t))
            end
        end
        return
    elseif n.kind == "lumber" then
        S.mode = "lumber"
        S.pct, S.prog, S.total = char.wood / MAX_WOOD, char.wood, MAX_WOOD
        if char.wood >= MAX_WOOD then S.status = "Madera completa: dónala desde el panel"
        else
            woodAcc = woodAcc + TICK
            S.status = format("Talando… %d / %d", char.wood, MAX_WOOD)
            if woodAcc >= 10 then woodAcc = 0; char.wood = math.min(MAX_WOOD, char.wood + 10) end
        end
        return
    end
    -- nodos de guerra
    local owner = GetOwner(n.id)
    local ga, gh = GroupInside(n)
    local pa, pe = PresenceCount(n)
    S.allies = ga + pa
    S.enemies = math.max(S.enemies, pe + gh)
    if owner == myFK then
        S.mode, S.pct = "hold", 1
        if S.enemies > 0 then
            S.status = format("¡Bajo ataque! %d enemigo%s cerca", S.enemies, S.enemies == 1 and "" or "s")
            n._contested = GetTime()
        else
            S.status = "Bajo control de tu facción"
            if n._contested and GetTime() - n._contested > 15 and GetTime() - n._contested < 60
                and (not lastDefend[n.id] or GetTime() - lastDefend[n.id] > 300) then
                lastDefend[n.id] = GetTime()
                char.defends = char.defends + 1
                AddGlory(15)
                Log("Has defendido " .. n.name)
                n._contested = nil
            end
        end
        if GetTime() - lastP > 5 then lastP = GetTime(); Send(format("P^%s^%s^0^0", n.id, myFK)) end
        return
    end
    if not CdG.CanAttack(n, myFK) then
        S.mode, S.status = "locked", "Bloqueado: conquista antes un punto conectado"
        return
    end
    if (n.kind == "keep" or n.kind == "outpost") and not IsInGuild() then
        S.mode, S.status = "locked", "Necesitas una hermandad para tomarlo"
        return
    end
    local req = Requirements()
    local total = CdG.CaptureTime(n, myFK, true)
    local v = progress[n.id] or 0
    S.total = total
    if req then
        S.mode, S.status, S.prog, S.pct = "req", req, v, v / total
        return
    end
    S.mode = "capture"
    if S.allies > S.enemies then
        v = v + TICK * math.min(1.5, 1 + 0.1 * (S.allies - S.enemies - 1))
        S.status = S.enemies > 0 and format("Superáis al enemigo (%d contra %d)", S.allies, S.enemies)
            or format("Capturando… (%d aliado%s)", S.allies, S.allies == 1 and "" or "s")
    elseif S.allies == S.enemies then
        S.status = format("Igualados (%d contra %d): el tiempo se congela", S.allies, S.enemies)
    else
        v = math.max(0, v - TICK)
        S.status = format("¡Os superan (%d contra %d)! La captura retrocede", S.allies, S.enemies)
    end
    if v >= total then
        S.prog, S.pct = total, 1
        Captured(n)
        return
    end
    progress[n.id] = v > 0 and v or nil
    S.prog, S.pct = v, v / total
    if GetTime() - lastP > 5 then lastP = GetTime(); Send(format("P^%s^%s^%d^%d", n.id, myFK, v, total)) end
end

-- ---------------------------------------------------------------------------
-- Acciones del panel
-- ---------------------------------------------------------------------------
function CdG.BuyAttack()
    if char.attack then return Print("Ya tienes un Ataque preparado para tu próxima captura.") end
    if char.coins < COST then return Print(format("Necesitas %d monedas de guerra (tienes %d).", COST, char.coins)) end
    char.coins = char.coins - COST
    char.attack = true
    Print("Ataque preparado: tu próxima captura será un minuto más corta.")
    Changed()
end

function CdG.BuyReinforce()
    if char.coins < COST then return Print(format("Necesitas %d monedas de guerra (tienes %d).", COST, char.coins)) end
    local n = Engine.state.node
    if not n or GetOwner(n.id) ~= myFK or not WAR[n.kind] then
        n = nil
        if curFront and px then
            local bd
            for _, p in ipairs(curFront.points) do
                if GetOwner(p.id) == myFK then
                    local d = CdG.Yards(curMap, px, py, p.x, p.y)
                    if not bd or d < bd then n, bd = p, d end
                end
            end
        end
    end
    if not n then return Print("Ponte en un frente cerca de un punto de tu facción para reforzarlo.") end
    if CdG.Reinforcements(n.id) >= 3 then return Print(n.name .. " ya tiene el máximo de refuerzos (3).") end
    char.coins = char.coins - COST
    local s = db.st[n.id]
    if not s then s = { o = myFK, t = 0 }; db.st[n.id] = s end
    s.rf = (s.rf or 0) + 1
    Send(format("E^%s^%s", n.id, myName), true)
    Print(format("%s reforzado: la próxima captura enemiga tardará un minuto más.", n.name))
    Changed()
end

function CdG.DonateWood()
    if char.wood < DONATE then return Print(format("Necesitas %d de madera (tienes %d).", DONATE, char.wood)) end
    char.wood = char.wood - DONATE
    local id = myName .. now()
    db.don.seen[id] = true
    db.don[myFK] = (db.don[myFK] or 0) + 1
    Send(format("D^%s^%s^%s", myFK, id, myName), true)
    AddGlory(30)
    Print("Has donado 500 de madera: +1% de dominación semanal para tu facción.")
    Changed()
end

function CdG.CallCooldown()
    return math.max(0, (db.lastcall[myFK] or 0) + CALL_CD - now())
end

function CdG.CallToArms()
    local where = Engine.state.node
    if where and not WAR[where.kind] then where = nil end
    if not curFront and not where then return Print("Solo puedes llamar a las armas desde un frente, una fortaleza o una avanzada.") end
    local cd = CdG.CallCooldown()
    if cd > 0 then return Print(format("Tu facción ya llamó a las armas. Próxima llamada en %d:%02d h.", cd / 3600, (cd % 3600) / 60)) end
    local t = now()
    db.lastcall[myFK] = t
    local fk = curFront and curFront.key or (where and where.id) or ""
    local place = where and where.name or (curFront and curFront.name) or ""
    Send(format("W^%s^%s^%s^%s^%d", fk, Clean(place), myFK, myName, t), true)
    Notice("Has llamado a tu facción a las armas", myFK)
    Changed()
end

function CdG.IsGeneral() return Engine.general ~= nil end
function CdG.ToggleGeneral()
    if Engine.general then
        Send(format("G^%s^%s^%s^0^0^off", Engine.general, myFK, myName), true)
        CdG.generals[Engine.general .. ":" .. myFK] = nil
        Engine.general = nil
        Print("Has dejado el mando.")
        return Changed()
    end
    if not curFront then return Print("Tienes que estar en un frente para tomar el mando.") end
    if not (IsPartyLeader() or IsRaidLeader()) then return Print("Solo el líder de un grupo o de una banda puede ser General.") end
    local g = CdG.generals[curFront.key .. ":" .. myFK]
    if g and g.name ~= myName and now() - g.t < 45 then return Print(g.name .. " ya es el General de tu facción en este frente.") end
    Engine.general = curFront.key
    Engine.genTimer = 15
    Print("Ahora eres el |cffffcc55General|r de la " .. CdG.FactionName(myFK) .. " en " .. curFront.name .. ".")
    Changed()
end

-- ---------------------------------------------------------------------------
-- Bajas
-- ---------------------------------------------------------------------------
local recentKills = {}
local function CreditKill(victim)
    if not victim or victim == "" then return end
    victim = victim:match("^([^%-]+)") or victim
    if recentKills[victim] and GetTime() - recentKills[victim] < 5 then return end
    recentKills[victim] = GetTime()
    local _, itype = IsInInstance()
    if itype and itype ~= "none" then return end
    local credit, coins = 1, 1
    if curFront and CdG.Featured() == curFront then credit, coins = 2, 2 end
    local b = CdG.bounties[victim]
    if b and b.f ~= myFK then
        credit, coins = credit + 2, coins + 5
        Notice("¡Has cobrado la recompensa por " .. victim .. "!", myFK)
        Send(format("B^%s^%s^0^^0^0", victim, b.f))
        CdG.bounties[victim] = nil
    end
    char.kills = char.kills + credit
    char.coins = math.min(MAX_COINS, char.coins + coins)
    char.streak = char.streak + 1
    if char.streak > char.best then char.best = char.streak end
    local e = Entry(myName, myFK); e.k = (e.k or 0) + credit
    AddGlory(10 * credit)
    AddEvent(curFront and curFront.key, "kill", myFK)
    Send(format("K^%s^%s^%s^%s", curFront and curFront.key or "", myFK, myName, victim))
    if char.streak >= BOUNTY_STREAK then
        Send(format("B^%s^%s^%d^%s^%.3f^%.3f", myName, myFK, char.streak, curFront and curFront.key or "", px or 0, py or 0))
        if char.streak == BOUNTY_STREAK then Notice("¡Racha de " .. BOUNTY_STREAK .. "! Ahora eres una recompensa para el enemigo", myFK) end
    end
    if curFront then Log(format("Has abatido a %s en %s", victim, curFront.name)) end
    SendMyEntry()
    Changed()
end

-- patrón de COMBATLOG_HONORGAIN ("%s muere, ...") convertido a patrón de Lua
local honorPattern
do
    local s = COMBATLOG_HONORGAIN or "%s dies, honorable kill Rank: %s (Estimated Honor Points: %d)"
    s = s:gsub("%%%d%$", "%%")
    s = s:gsub("([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
    s = s:gsub("%%s", "(.-)"):gsub("%%d", "(%%d+)")
    honorPattern = "^" .. s
end

-- ---------------------------------------------------------------------------
-- Tooltip de jugadores: rango, némesis, recompensa
-- ---------------------------------------------------------------------------
GameTooltip:HookScript("OnTooltipSetUnit", function(tt)
    if not db or not db.tooltip then return end
    local _, unit = tt:GetUnit()
    if not unit or not UnitIsPlayer(unit) then return end
    local name = UnitName(unit)
    if name == myName then
        tt:AddLine("Campañas: " .. CdG.RANKS[char.rank or 1][2], 1, 0.82, 0.3)
    else
        local e = db.board.players[name]
        if e and (e.rk or 1) >= 11 and CdG.RANKS[e.rk] then tt:AddLine("Campañas: " .. CdG.RANKS[e.rk][2], 1, 0.82, 0.3) end
        if UnitIsEnemy("player", unit) then
            local nem = CdG.Nemesis()
            if nem[name] then tt:AddLine(format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t Némesis de la semana (n.º %d)", nem[name]), 1, 0.2, 0.2) end
            if CdG.bounties[name] then tt:AddLine("Recompensa: " .. CdG.bounties[name].s .. " bajas seguidas", 1, 0.5, 0.1) end
        end
    end
    tt:Show()
end)

-- ---------------------------------------------------------------------------
-- Eventos
-- ---------------------------------------------------------------------------
Engine:RegisterEvent("PLAYER_LOGIN")
Engine:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        myFaction, myName = UnitFactionGroup("player"), UnitName("player")
        myFK = myFaction == "Alliance" and "A" or "H"
        CdG.myFK, CdG.myName = myFK, myName
        InitDB()
        for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
            "COMBAT_LOG_EVENT_UNFILTERED", "CHAT_MSG_CHANNEL", "CHAT_MSG_ADDON", "PLAYER_TARGET_CHANGED",
            "UPDATE_MOUSEOVER_UNIT", "CHAT_MSG_COMBAT_HONOR_GAIN", "PLAYER_DEAD", "UNIT_SPELLCAST_SUCCEEDED",
            "PLAYER_GUILD_UPDATE" }) do self:RegisterEvent(ev) end
        self.loginTimer = 8
        if CdG.OnLogin then CdG.OnLogin() end
        UpdateCurrentMap()
    elseif event == "PLAYER_ENTERING_WORLD" or event:find("^ZONE_CHANGED") then
        UpdateCurrentMap()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, sub, _, sname, sflags, _, dname, dflags = ...
        if IsHostilePlayer(sflags) then SeeEnemy(sname) end
        if IsHostilePlayer(dflags) then SeeEnemy(dname) end
        if sub == "PARTY_KILL" and sname == myName and IsHostilePlayer(dflags) then CreditKill(dname) end
        if sub == "UNIT_DIED" and dname and CdG.bounties[dname] then CdG.bounties[dname] = nil; Changed() end
    elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        local msg = ...
        local victim = msg and msg:match(honorPattern)
        if victim then CreditKill(victim) end
    elseif event == "PLAYER_DEAD" then
        char.deaths = char.deaths + 1
        if char.streak >= BOUNTY_STREAK then Send(format("B^%s^%s^0^^0^0", myName, myFK)) end
        char.streak = 0
        if Engine.general then
            Send(format("G^%s^%s^%s^0^0^dead", Engine.general, myFK, myName), true)
            CdG.generals[Engine.general .. ":" .. myFK] = nil
            Engine.general = nil
        end
        Changed()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, spell = ...
        if unit == "player" and Engine.state.mode == "mine" and spell == (GetSpellInfo(2575)) and char.coins < MAX_COINS then
            char.coins = math.min(MAX_COINS, char.coins + 2)
            Print("Has extraído mineral en la mina: +2 monedas de guerra.")
            Changed()
        end
    elseif event == "PLAYER_TARGET_CHANGED" then CheckUnit("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then CheckUnit("mouseover")
    elseif event == "PLAYER_GUILD_UPDATE" then SendMyEntry()
    elseif event == "CHAT_MSG_CHANNEL" then
        local msg, author, _, _, _, _, _, _, chanName = ...
        if type(chanName) == "string" and chanName:lower() == CHANNEL:lower() and type(msg) == "string"
            and msg:sub(1, #PREFIX + 1) == PREFIX .. " " then
            HandlePayload(msg:sub(#PREFIX + 2), author)
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, _, sender = ...
        if prefix == PREFIX then HandlePayload(msg, sender) end
    end
end)

local acc, slow = 0, 0
Engine:SetScript("OnUpdate", function(self, e)
    if not db then return end
    if #queue > 0 and GetTime() - lastSend > 1 then lastSend = GetTime(); RawSend(table.remove(queue, 1)) end
    if self.loginTimer then
        self.loginTimer = self.loginTimer - e
        if self.loginTimer <= 0 then self.loginTimer = nil; JoinSyncChannel(); CdG.RequestSync(); SendMyEntry(true) end
    end
    if replyTimer then
        replyTimer = replyTimer - e
        if replyTimer <= 0 then replyTimer = nil; if not othersReplied then SendStateReply() end end
    end
    if self.general then
        self.genTimer = (self.genTimer or 0) + e
        if self.genTimer >= 15 and curFront and self.general == curFront.key then
            self.genTimer = 0
            Send(format("G^%s^%s^%s^%.3f^%.3f^on", curFront.key, myFK, myName, px or 0, py or 0))
            CdG.generals[curFront.key .. ":" .. myFK] = { name = myName, f = myFK, fk = curFront.key, x = px, y = py, t = now() }
        end
    end
    acc = acc + e
    if acc >= TICK then
        acc = 0
        if db.enabled then Tick() end
        Changed()
    end
    slow = slow + e
    if slow >= 15 then
        slow = 0
        if db.week ~= CdG.WeekId() then WeeklyReset(); Print("¡Empieza una nueva campaña semanal!") end
        if self.entryPending then self.entryPending = nil; SendMyEntry(true) end
        for k, g in pairs(CdG.generals) do if now() - g.t > 60 then CdG.generals[k] = nil end end
        for k, b in pairs(CdG.bounties) do if now() - b.t > 900 then CdG.bounties[k] = nil end end
    end
    if self.dirty then
        self.dirty = nil
        if CdG.OnCampaignChanged then CdG.OnCampaignChanged() end
    end
end)

-- refrescos encadenados: cada módulo de interfaz añade su función
local listeners = {}
function CdG.OnChange(fn) table.insert(listeners, fn) end
CdG.OnCampaignChanged = function() for _, fn in ipairs(listeners) do fn() end end

WorldMapFrame:HookScript("OnHide", function() if db then UpdateCurrentMap() end end)
