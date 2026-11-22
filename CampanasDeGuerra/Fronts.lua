-- ============================================================================
-- Campañas de Guerra - Frentes y puntos de captura
-- Diseño propio. "map" es el nombre interno del mapa (GetMapInfo), igual en
-- cualquier idioma. x / y van de 0 a 1 sobre el mapa de la zona; r es el radio
-- de captura en unidades de alto del mapa. Las coordenadas son aproximadas:
-- si algún punto queda mal situado se corrige aquí sin tocar nada más.
-- ============================================================================
CdG = CdG or {}

CdG.CONTINENTS = { "Reinos del Este", "Kalimdor", "Terrallende", "Rasganorte" }

local R = 0.035 -- radio por defecto

CdG.FRONTS = {
    -- ------------------------------------------------------------ Reinos del Este
    {
        key = "arathi", name = "Tierras Altas de Arathi", map = "Arathi", continent = "Reinos del Este",
        desc = "Las colinas del viejo reino de Arathor vuelven a arder.",
        points = {
            { key = "refugio",    name = "Refugio de la Zaga",       x = 0.460, y = 0.465 },
            { key = "sentencia",  name = "Sentencia",                x = 0.735, y = 0.340 },
            { key = "stromgarde", name = "Ruinas de Stromgarde",     x = 0.300, y = 0.600 },
            { key = "secacorteza",name = "Aldea Secacorteza",        x = 0.675, y = 0.705 },
            { key = "circulo",    name = "Círculo de Vínculo",       x = 0.520, y = 0.505 },
        },
    },
    {
        key = "trabalomas", name = "Laderas de Trabalomas", map = "Hilsbrad", continent = "Reinos del Este",
        desc = "Costasur y Molino Tarren se disputan las granjas del valle.",
        points = {
            { key = "costasur",   name = "Costasur",                 x = 0.510, y = 0.580 },
            { key = "tarren",     name = "Molino Tarren",            x = 0.620, y = 0.210 },
            { key = "granjas",    name = "Granjas de Trabalomas",    x = 0.360, y = 0.430 },
            { key = "durnholde",  name = "Castillo de Durnholde",    x = 0.775, y = 0.420 },
            { key = "darrow",     name = "Colina de Darrow",         x = 0.470, y = 0.340 },
        },
    },
    {
        key = "lochmodan", name = "Loch Modan", map = "LochModan", continent = "Reinos del Este",
        desc = "La Horda avanza sobre la gran presa de los enanos.",
        points = {
            { key = "thelsamar",  name = "Thelsamar",                x = 0.350, y = 0.470 },
            { key = "presa",      name = "Presa de Piedraforjada",   x = 0.475, y = 0.150 },
            { key = "reyes",      name = "Valle de los Reyes",       x = 0.225, y = 0.720 },
            { key = "pabellon",   name = "Pabellón de los Montaraces", x = 0.820, y = 0.640 },
            { key = "ironband",   name = "Excavación de Ironband",   x = 0.690, y = 0.630 },
        },
    },
    {
        key = "crestagrana", name = "Montañas Crestagrana", map = "Redridge", continent = "Reinos del Este",
        desc = "El lago Everstill es la frontera entre ambos bandos.",
        points = {
            { key = "villalago",  name = "Villa del Lago",           x = 0.280, y = 0.480 },
            { key = "altopiedra", name = "Alto de Piedra",           x = 0.630, y = 0.500 },
            { key = "tresesq",    name = "Tres Caminos",             x = 0.160, y = 0.660 },
            { key = "galardell",  name = "Valle de Galardell",       x = 0.660, y = 0.600 },
            { key = "everstill",  name = "Orilla del lago Everstill",x = 0.450, y = 0.580 },
        },
    },
    {
        key = "elwynn", name = "Bosque de Elwynn", map = "Elwynn", continent = "Reinos del Este",
        desc = "Una incursión a las puertas de Ventormenta.",
        points = {
            { key = "villadorada",name = "Villadorada",              x = 0.420, y = 0.650 },
            { key = "fargodeep",  name = "Mina Abisal",              x = 0.390, y = 0.820 },
            { key = "jasperlode", name = "Mina de Jaspe",            x = 0.610, y = 0.530 },
            { key = "brightwood", name = "Campamento de Valleoriente", x = 0.820, y = 0.660 },
            { key = "northshire", name = "Entrada de Villanorte",    x = 0.480, y = 0.470 },
        },
    },
    -- ------------------------------------------------------------ Kalimdor
    {
        key = "vallefresno", name = "Vallefresno", map = "Ashenvale", continent = "Kalimdor",
        desc = "Los elfos de la noche defienden el bosque de los aserraderos de la Horda.",
        points = {
            { key = "astranaar",  name = "Astranaar",                x = 0.360, y = 0.500 },
            { key = "hacha",      name = "Puesto del Hacha",         x = 0.730, y = 0.620 },
            { key = "raynewood",  name = "Retiro Raynewood",         x = 0.600, y = 0.500 },
            { key = "iris",       name = "Lago Iris",                x = 0.460, y = 0.450 },
            { key = "aessina",    name = "Arboleda de Aessina",      x = 0.210, y = 0.420 },
        },
    },
    {
        key = "tanaris", name = "Tanaris", map = "Tanaris", continent = "Kalimdor",
        desc = "Arena, piratas y el control de las rutas de Gadgetzan.",
        points = {
            { key = "zulfarrak",  name = "Puertas de Zul'Farrak",    x = 0.390, y = 0.200 },
            { key = "bonvapor",   name = "Puerto Bonvapor",          x = 0.670, y = 0.230 },
            { key = "aparejo",    name = "Cala del Aparejo Perdido", x = 0.710, y = 0.480 },
            { key = "cardos",     name = "Valle de los Cardos",      x = 0.300, y = 0.650 },
            { key = "abismal",    name = "Dunas de Abismal",         x = 0.450, y = 0.500 },
        },
    },
    {
        key = "durotar", name = "Durotar", map = "Durotar", continent = "Kalimdor",
        desc = "La Alianza desembarca en las tierras rojas de la Horda.",
        points = {
            { key = "cerrotajo",  name = "Cerrotajo",                x = 0.525, y = 0.430 },
            { key = "senjin",     name = "Aldea Sen'jin",            x = 0.550, y = 0.740 },
            { key = "tiragarde",  name = "Fortaleza Tiragarde",      x = 0.580, y = 0.570 },
            { key = "pruebas",    name = "Valle de las Pruebas",     x = 0.430, y = 0.680 },
            { key = "trueno",     name = "Cresta del Trueno",        x = 0.400, y = 0.250 },
        },
    },
    -- ------------------------------------------------------------ Terrallende
    {
        key = "fuegoinfernal", name = "Península del Fuego Infernal", map = "Hellfire", continent = "Terrallende",
        desc = "La primera línea tras el Portal Oscuro.",
        points = {
            { key = "ciudadela",  name = "Puertas de la Ciudadela",  x = 0.470, y = 0.520 },
            { key = "halcon",     name = "Avanzada del Halcón",      x = 0.275, y = 0.600 },
            { key = "telhamat",   name = "Templo de Telhamat",       x = 0.230, y = 0.400 },
            { key = "zethgor",    name = "Zeth'Gor",                 x = 0.690, y = 0.720 },
            { key = "trincheras", name = "Trincheras del Portal",    x = 0.740, y = 0.560 },
        },
    },
    {
        key = "nagrand", name = "Nagrand", map = "Nagrand", continent = "Terrallende",
        desc = "Halaa y las praderas flotantes de Nagrand.",
        points = {
            { key = "halaa",      name = "Halaa",                    x = 0.420, y = 0.440 },
            { key = "garadar",    name = "Garadar",                  x = 0.550, y = 0.370 },
            { key = "telaar",     name = "Telaar",                   x = 0.540, y = 0.750 },
            { key = "kilsorrow",  name = "Fortaleza Kil'sorrow",     x = 0.690, y = 0.790 },
            { key = "aeris",      name = "Desembarco Aeris",         x = 0.720, y = 0.370 },
        },
    },
    {
        key = "terokkar", name = "Bosque de Terokkar", map = "TerokkarForest", continent = "Terrallende",
        desc = "Los espíritus de las Tierras Óseas no descansan.",
        points = {
            { key = "allerian",   name = "Bastión Allerian",         x = 0.560, y = 0.720 },
            { key = "rompepiedras", name = "Bastión Rompepiedras",   x = 0.490, y = 0.450 },
            { key = "auchindoun", name = "Ruinas de Auchindoun",     x = 0.400, y = 0.650 },
            { key = "oseas",      name = "Tierras Óseas",            x = 0.630, y = 0.700 },
            { key = "veil",       name = "Velo Rhaze",               x = 0.700, y = 0.450 },
        },
    },
    -- ------------------------------------------------------------ Rasganorte
    {
        key = "colinaspardas", name = "Colinas Pardas", map = "GrizzlyHills", continent = "Rasganorte",
        desc = "Madera, osos y la guerra por los aserraderos.",
        points = {
            { key = "ventura",    name = "Bahía Ventura",            x = 0.130, y = 0.730 },
            { key = "conquista",  name = "Bastión de la Conquista",  x = 0.210, y = 0.640 },
            { key = "pinoambar",  name = "Refugio Pinoámbar",        x = 0.320, y = 0.600 },
            { key = "cieloazul",  name = "Campamento Cielo Azul",    x = 0.350, y = 0.670 },
            { key = "brigada",    name = "Campamento de la Brigada", x = 0.590, y = 0.270 },
        },
    },
    {
        key = "cementerio", name = "Cementerio de Dragones", map = "Dragonblight", continent = "Rasganorte",
        desc = "Entre los huesos de los dragones, la Plaga vigila.",
        points = {
            { key = "invernal",   name = "Bastión Invernal",         x = 0.780, y = 0.490 },
            { key = "agmar",      name = "Martillo de Agmar",        x = 0.370, y = 0.470 },
            { key = "reposo",     name = "Templo del Reposo del Dragón", x = 0.590, y = 0.540 },
            { key = "estelar",    name = "Reposo Estelar",           x = 0.290, y = 0.560 },
            { key = "rencor",     name = "Rencor Venenoso",          x = 0.760, y = 0.620 },
        },
    },
}

-- índices rápidos
CdG.FRONT_BY_MAP, CdG.FRONT_BY_KEY = {}, {}
for _, f in ipairs(CdG.FRONTS) do
    CdG.FRONT_BY_MAP[f.map] = f
    CdG.FRONT_BY_KEY[f.key] = f
    f.byKey = {}
    for _, p in ipairs(f.points) do
        p.r = p.r or R
        f.byKey[p.key] = p
    end
end
