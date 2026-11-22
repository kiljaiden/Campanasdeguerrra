-- ============================================================================
-- Campañas de Guerra - Datos de frentes, fortalezas, avanzadas y recursos
--
-- Coordenadas (x, y de 0 a 1) sacadas del propio cliente 3.3.5 esES
-- (WorldMapOverlay.dbc y TaxiNodes.dbc). Si un punto queda desplazado, usa
-- "/campanas pos" en el sitio exacto y corrige aquí sus x / y.
--
-- Tipos de nodo:  point (punto normal), capital, keep (fortaleza de hermandad),
--                 outpost (avanzada de hermandad), mine (mina), lumber (aserradero)
-- ============================================================================
CdG = CdG or {}
local CdG = CdG

-- Límites del mapa de cada zona en metros del mundo (WorldMapArea.dbc):
-- izquierda, derecha, arriba, abajo, continente (0 = Reinos del Este, 1 = Kalimdor)
CdG.ZONES = {
    Durotar = { -1962.50, -7250.00, 1808.33, -1716.67, 1 },
    Mulgore = { 2047.92, -3089.58, -272.92, -3697.92, 1 },
    Barrens = { 2622.92, -7510.42, 1612.50, -5143.75, 1 },
    Arathi = { -866.67, -4466.67, -133.33, -2533.33, 0 },
    Badlands = { -2079.17, -4566.67, -5889.58, -7547.92, 0 },
    Silverpine = { 3450.00, -750.00, 1666.67, -1133.33, 0 },
    EasternPlaguelands = { -2287.50, -6318.75, 3704.17, 1016.67, 0 },
    Hilsbrad = { 1066.67, -2133.33, 400.00, -1733.33, 0 },
    Elwynn = { 1535.42, -1935.42, -7939.58, -10254.17, 0 },
    LochModan = { -1993.75, -4752.08, -4487.50, -6327.08, 0 },
    Redridge = { -1570.83, -3741.67, -8575.00, -10022.92, 0 },
    Wetlands = { -389.58, -4525.00, -2147.92, -4904.17, 0 },
    Darkshore = { 2941.67, -3608.33, 8333.33, 3966.67, 1 },
    Ashenvale = { 1700.00, -4066.67, 4672.92, 829.17, 1 },
    StonetalonMountains = { 3245.83, -1637.50, 2916.67, -339.58, 1 },
    Feralas = { 5441.67, -1508.33, -2366.67, -7000.00, 1 },
}
CdG.CONTINENT_MAPS = {
    [0] = { map = "Azeroth", name = "Reinos del Este", 18171.97, -22569.21, 11176.34, -15973.34 },
    [1] = { map = "Kalimdor", name = "Kalimdor", 17066.60, -19733.21, 12799.90, -11733.30 },
}
CdG.CONT_BY_MAP = { Azeroth = 0, Kalimdor = 1 }

-- Radio de captura en metros y tiempo base en segundos por tipo
CdG.KIND = {
    point   = { r = 45, time = 120, label = "Punto" },
    capital = { r = 70, time = 480, label = "Capital" },
    keep    = { r = 70, time = 600, label = "Fortaleza" },
    outpost = { r = 40, time = 300, label = "Avanzada" },
    mine    = { r = 35, label = "Mina" },
    lumber  = { r = 40, label = "Aserradero" },
}

CdG.FRONTS = {
    -- --------------------------------------------------------------- Arathi
    {
        key = "arathi", name = "Tierras Altas de Arathi", short = "Arathi", map = "Arathi",
        desc = "Las colinas del viejo reino de Arathor vuelven a arder.",
        nodes = {
            { "refugio",    "Refugio de la Zaga",          0.458, 0.461, "capital", "A" },
            { "sentencia",  "Sentencia",                   0.735, 0.340, "capital", "H" },
            { "redilnorte", "Mansión Redilnorte",          0.306, 0.314 },
            { "stromgarde", "Castillo de Stromgarde",      0.240, 0.600 },
            { "faldir",     "Cala de Faldir",              0.300, 0.790 },
            { "circulo",    "Círculo de Vínculo Exterior", 0.503, 0.555 },
            { "dabyrie",    "Granja de Dabyrie",           0.561, 0.404 },
            { "circeste",   "Círculo de Vínculo Este",     0.637, 0.300 },
            { "goshek",     "Granja Go'shek",              0.645, 0.559 },
            { "secacorteza","Poblado Secacorteza",         0.665, 0.656 },
            { "puno",       "Sala Puño de Roca",           0.538, 0.718 },
            { "thoradin",   "Muralla de Thoradin",         0.182, 0.386, "outpost" },
            { "bouldergor", "Cantera de Boulder'gor",      0.354, 0.400, "mine" },
        },
        links = { "refugio-redilnorte", "refugio-dabyrie", "refugio-circulo", "redilnorte-stromgarde",
            "stromgarde-faldir", "faldir-puno", "circulo-puno", "circulo-goshek", "dabyrie-circeste",
            "dabyrie-goshek", "circeste-sentencia", "goshek-sentencia", "goshek-secacorteza", "puno-secacorteza" },
    },
    -- --------------------------------------------------------------- Trabalomas
    {
        key = "trabalomas", name = "Laderas de Trabalomas", short = "Trabalomas", map = "Hilsbrad",
        desc = "Costasur y Molino Tarren se disputan las granjas del valle.",
        nodes = {
            { "costasur",  "Costasur",              0.505, 0.530, "capital", "A" },
            { "tarren",    "Molino Tarren",         0.615, 0.215, "capital", "H" },
            { "darrow",    "Colinas de Darrow",     0.515, 0.347 },
            { "campos",    "Campos de Trabalomas",  0.350, 0.438 },
            { "nethander", "Granja Nethander",      0.647, 0.533 },
            { "durnholde", "Castillo de Durnholde", 0.795, 0.385 },
            { "dungarok",  "Dun Garok",             0.755, 0.646 },
            { "playaeste", "Playa del Este",        0.638, 0.747 },
            { "austral",   "Torre Austral",         0.146, 0.456, "outpost" },
            { "azur",      "Mina Azur",             0.257, 0.561, "mine" },
        },
        links = { "costasur-darrow", "costasur-campos", "costasur-nethander", "campos-darrow", "darrow-tarren",
            "nethander-durnholde", "durnholde-tarren", "nethander-dungarok", "dungarok-durnholde",
            "costasur-playaeste", "playaeste-dungarok" },
    },
    -- --------------------------------------------------------------- Loch Modan
    {
        key = "lochmodan", name = "Loch Modan", short = "Loch Modan", map = "LochModan",
        desc = "Los ogros de Mo'grosh, aliados de la Horda, bajan hacia la gran presa.",
        nodes = {
            { "thelsamar",   "Thelsamar",                0.350, 0.480, "capital", "A" },
            { "mogrosh",     "Fortaleza de Mo'grosh",    0.698, 0.248, "capital", "H" },
            { "presa",       "Presa de las Tres Cabezas",0.483, 0.147 },
            { "puertanorte", "Paso de la Puerta Norte",  0.240, 0.243 },
            { "rompecantos", "Valle Rompecantos",        0.342, 0.734 },
            { "zarpagris",   "Fuerte Zarpagris",         0.456, 0.732 },
            { "vetaferro",   "Excavación de Vetaferro",  0.653, 0.672 },
            { "errante",     "Cabaña del Errante",       0.810, 0.620 },
            { "isla",        "Orilla del Loch",          0.560, 0.430 },
            { "reyes",       "Valle de los Reyes",       0.206, 0.741, "outpost" },
            { "fuenteplata", "Mina de Fuenteplata",      0.346, 0.219, "mine" },
        },
        links = { "thelsamar-presa", "thelsamar-puertanorte", "puertanorte-presa", "thelsamar-rompecantos",
            "rompecantos-zarpagris", "zarpagris-vetaferro", "vetaferro-errante", "errante-mogrosh",
            "presa-mogrosh", "thelsamar-isla", "isla-mogrosh", "isla-vetaferro" },
    },
    -- --------------------------------------------------------------- Crestagrana
    {
        key = "crestagrana", name = "Montañas Crestagrana", short = "Crestagrana", map = "Redridge",
        desc = "Los orcos de Render bajan de los cañones hacia el lago Sempiterno.",
        nodes = {
            { "villalago",  "Villa del Lago",          0.270, 0.470, "capital", "A" },
            { "render",     "Campamento de Render",    0.414, 0.192, "capital", "H" },
            { "canones",    "Cañones de Crestagrana",  0.303, 0.291 },
            { "tres",       "Tres Caminos",            0.182, 0.687 },
            { "camino",     "Camino del Lago",         0.401, 0.716 },
            { "alther",     "Molino de Alther",        0.515, 0.395 },
            { "petravista", "Torre de Petravista",     0.626, 0.546 },
            { "cascadas",   "Cascadas Petravista",     0.753, 0.636 },
            { "galardell",  "Valle de Galardell",      0.777, 0.428 },
            { "vrender",    "Valle de Render",         0.715, 0.731, "outpost" },
            { "rethban",    "Cavernas de Rethban",     0.200, 0.250, "mine" },
        },
        links = { "villalago-canones", "canones-render", "villalago-tres", "tres-camino", "camino-petravista",
            "villalago-alther", "alther-render", "alther-petravista", "petravista-cascadas",
            "petravista-galardell", "galardell-alther", "cascadas-galardell" },
    },
    -- --------------------------------------------------------------- Elwynn
    {
        key = "elwynn", name = "Bosque de Elwynn", short = "Elwynn", map = "Elwynn",
        desc = "Una incursión de la Horda a las puertas de Ventormenta.",
        nodes = {
            { "arroyoeste", "Cuartel de Arroyoeste",          0.245, 0.745, "capital", "A" },
            { "vegaeste",   "Aserradero de la Vega del Este", 0.830, 0.651, "capital", "H" },
            { "villadorada","Villadorada",                    0.420, 0.650 },
            { "villanorte", "Valle de Villanorte",            0.480, 0.420 },
            { "cristal",    "Lago de Cristal",                0.533, 0.662 },
            { "abisal",     "Mina Abisal",                    0.385, 0.820, "mine" },
            { "jerod",      "Embarcadero de Jerod",           0.475, 0.855 },
            { "azora",      "Torre de Azora",                 0.650, 0.690 },
            { "hito",       "Lago del Hito",                  0.741, 0.476 },
            { "brackwell",  "Plantación de Brackwell",        0.700, 0.800 },
            { "pena",       "Torre de la Peña",               0.847, 0.826, "outpost" },
            { "jaspe",      "Mina de Jaspe",                  0.610, 0.530, "mine" },
            { "linde",      "Linde del Bosque",               0.320, 0.700, "lumber" },
        },
        links = { "arroyoeste-villadorada", "villadorada-villanorte", "villadorada-cristal",
            "arroyoeste-jerod", "jerod-cristal", "cristal-azora", "villanorte-hito", "hito-vegaeste",
            "azora-hito", "azora-brackwell", "brackwell-vegaeste" },
    },
    -- --------------------------------------------------------------- Vallefresno
    {
        key = "vallefresno", name = "Vallefresno", short = "Vallefresno", map = "Ashenvale",
        desc = "Los elfos de la noche defienden el bosque de los aserraderos de la Horda.",
        nodes = {
            { "astranaar", "Astranaar",               0.365, 0.500, "capital", "A" },
            { "hachazo",   "Puesto del Hachazo",      0.715, 0.610, "capital", "H" },
            { "falathim",  "Lago Falathim",           0.195, 0.351 },
            { "piel",      "Poblado Piel de Cardo",   0.330, 0.382 },
            { "polvo",     "Ruinas del Polvo Estelar",0.337, 0.671 },
            { "iris",      "Lago Iris",               0.491, 0.480 },
            { "aullido",   "Vega del Aullido",        0.567, 0.350 },
            { "algaba",    "Refugio de la Algaba",    0.609, 0.540 },
            { "mystral",   "Lago Mystral",            0.493, 0.699 },
            { "cielo",     "Lago Cielo Estrellado",   0.663, 0.791 },
            { "satyrnaar", "Satyrnaar",               0.810, 0.490 },
            { "zoramgar",  "Avanzada de Zoram'gar",   0.122, 0.338, "outpost" },
            { "lumbrevil", "Cerro Lumbrevil",         0.834, 0.706, "mine" },
            { "gritoguerra","Aserradero Grito de Guerra", 0.894, 0.585, "lumber" },
        },
        links = { "astranaar-iris", "astranaar-piel", "astranaar-polvo", "piel-falathim", "polvo-mystral",
            "iris-algaba", "iris-aullido", "aullido-algaba", "algaba-hachazo", "mystral-algaba",
            "mystral-cielo", "cielo-hachazo", "aullido-satyrnaar", "satyrnaar-hachazo" },
    },
    -- --------------------------------------------------------------- Durotar
    {
        key = "durotar", name = "Durotar", short = "Durotar", map = "Durotar",
        desc = "La Alianza desembarca en las Islas del Eco y avanza sobre las tierras rojas.",
        nodes = {
            { "islas",     "Islas del Eco",           0.640, 0.830, "capital", "A" },
            { "cerrotajo", "Cerrotajo",               0.525, 0.430, "capital", "H" },
            { "senjin",    "Poblado Sen'jin",         0.553, 0.740 },
            { "kolkar",    "Risco Kolkar",            0.492, 0.802 },
            { "retos",     "Valle de los Retos",      0.440, 0.660 },
            { "tiragarde", "Fuerte de Tiragarde",     0.575, 0.565 },
            { "crines",    "Tierras Crines de Acero", 0.415, 0.455 },
            { "arido",     "Barranco Árido",          0.531, 0.237 },
            { "trueno",    "Monte del Trueno",        0.421, 0.240, "outpost" },
            { "craneo",    "Roca del Cráneo",         0.527, 0.132, "mine" },
        },
        links = { "islas-senjin", "islas-kolkar", "senjin-kolkar", "senjin-tiragarde", "kolkar-retos",
            "retos-crines", "tiragarde-cerrotajo", "crines-cerrotajo", "cerrotajo-arido", "arido-crines" },
    },
    -- --------------------------------------------------------------- Bosque de Argénteos
    {
        key = "argenteos", name = "Bosque de Argénteos", short = "Argénteos", map = "Silverpine",
        desc = "Desde Piroleña, la Alianza empuja a los Renegados hacia El Sepulcro.",
        nodes = {
            { "pirolena",    "Aldea Piroleña",              0.460, 0.761, "capital", "A" },
            { "sepulcro",    "El Sepulcro",                 0.456, 0.424, "capital", "H" },
            { "colmillo",    "Castillo de Colmillo Oscuro", 0.473, 0.657 },
            { "olsen",       "Finca de Olsen",              0.464, 0.540 },
            { "beren",       "El Desafío de Beren",         0.610, 0.759 },
            { "embarcadero", "El Viejo Embarcadero",        0.546, 0.354 },
            { "hoya",        "Hoya de la Marea",            0.412, 0.287 },
            { "campo",       "El Campo Muerto",             0.489, 0.221 },
            { "ambar",       "Molino Ámbar",                0.613, 0.572, "outpost" },
            { "elem",        "Mina de Elem",                0.549, 0.500, "mine" },
        },
        links = { "pirolena-colmillo", "pirolena-beren", "colmillo-olsen", "beren-olsen", "olsen-sepulcro",
            "olsen-embarcadero", "embarcadero-sepulcro", "sepulcro-hoya", "hoya-campo", "campo-embarcadero" },
    },
    -- --------------------------------------------------------------- Tierras de la Peste del Este
    {
        key = "peste", name = "Tierras de la Peste del Este", short = "La Peste", map = "EasternPlaguelands",
        desc = "Entre las ruinas de Lordaeron ambas facciones se disputan las torres.",
        nodes = {
            { "capilla",    "Capilla de la Esperanza de la Luz", 0.757, 0.533, "capital", "A" },
            { "marris",     "Hacienda de Marris",           0.253, 0.698, "capital", "H" },
            { "muralla",    "Torre de la Muralla del Este", 0.609, 0.448 },
            { "corin",      "Cruce de Corin",               0.598, 0.708 },
            { "cicatriz",   "La Cicatriz Purulenta",        0.506, 0.675 },
            { "bosquenegro","Lago del Bosque Negro",        0.539, 0.457 },
            { "pasonorte",  "Torre del Paso Norte",         0.496, 0.221 },
            { "fungal",     "Cuenca Fungal",                0.368, 0.549 },
            { "darrow",     "Villa Darrow",                 0.406, 0.833 },
            { "corona",     "Torre de la Corona",           0.340, 0.687 },
            { "bosquepeste","Torre del Bosque de la Peste", 0.189, 0.262, "outpost" },
            { "subgranja",  "La Subgranja",                 0.269, 0.824, "mine" },
            { "vallenorte", "Vallenorte",                   0.717, 0.350, "lumber" },
        },
        links = { "capilla-muralla", "capilla-corin", "corin-cicatriz", "muralla-bosquenegro", "bosquenegro-pasonorte",
            "bosquenegro-fungal", "cicatriz-fungal", "cicatriz-darrow", "darrow-corona", "corona-marris",
            "fungal-marris", "corona-cicatriz", "pasonorte-fungal" },
    },
    -- --------------------------------------------------------------- Los Humedales
    {
        key = "humedales", name = "Los Humedales", short = "Humedales", map = "Wetlands",
        desc = "Los Faucedraco salen de Grim Batol hacia el puerto de Menethil.",
        nodes = {
            { "menethil",    "Puerto de Menethil",      0.100, 0.566, "capital", "A" },
            { "faucedraco",  "Puertas Faucedraco",      0.784, 0.614, "capital", "H" },
            { "canal",       "Pantano del Canal Negro", 0.197, 0.498 },
            { "salobre",     "Cañada Salobre",          0.336, 0.241 },
            { "dentellada",  "Campamento Dentellada",   0.459, 0.465 },
            { "tumba",       "Tumba de Barbaférrea",    0.448, 0.311 },
            { "franja",      "La Franja Verde",         0.547, 0.367 },
            { "fraguaferoz", "Cerro Fraguaferoz",       0.634, 0.359 },
            { "raptor",      "Colina del Raptor",       0.722, 0.383 },
            { "pellejomusgo","Pantano Pellejomusgo",    0.628, 0.579 },
            { "thelgen",     "Roca Thelgen",            0.584, 0.698 },
            { "branquizul",  "Pantano Branquizul",      0.201, 0.355, "outpost" },
            { "whelgar",     "Excavación de Whelgar",   0.344, 0.445, "mine" },
        },
        links = { "menethil-canal", "canal-salobre", "canal-dentellada", "salobre-tumba", "tumba-franja",
            "dentellada-franja", "dentellada-pellejomusgo", "franja-fraguaferoz", "fraguaferoz-raptor",
            "raptor-faucedraco", "pellejomusgo-thelgen", "thelgen-faucedraco", "pellejomusgo-faucedraco" },
    },
    -- --------------------------------------------------------------- Los Baldíos
    {
        key = "baldios", name = "Los Baldíos", short = "Baldíos", map = "Barrens",
        desc = "Desde el Fuerte del Norte, la Alianza avanza por la sabana hacia la Horda.",
        nodes = {
            { "fuertenorte", "Fuerte del Norte",        0.601, 0.549, "capital", "A" },
            { "puente",      "Avanzada del Puente",     0.613, 0.201, "capital", "H" },
            { "raptores",    "Tierras de los Raptores", 0.563, 0.505 },
            { "trinquete",   "Trinquete",               0.631, 0.371 },
            { "estancado",   "El Oasis Estancado",      0.557, 0.412 },
            { "rajazarza",   "Rajazarza",               0.503, 0.570 },
            { "taurajo",     "Campamento Taurajo",      0.445, 0.600 },
            { "agamagor",    "Agama'gor",               0.439, 0.489 },
            { "aguaverde",   "Oasis Aguaverde",         0.452, 0.403 },
            { "espinosa",    "Colina Espinosa",         0.567, 0.274 },
            { "groldom",     "Granja de Grol'dom",      0.553, 0.180 },
            { "honor",       "El Alto del Honor",       0.369, 0.290, "outpost" },
            { "pedrusco",    "Mina Pedrusco",           0.614, 0.082, "mine" },
        },
        links = { "fuertenorte-raptores", "fuertenorte-trinquete", "raptores-estancado", "raptores-rajazarza",
            "rajazarza-agamagor", "rajazarza-taurajo", "taurajo-agamagor", "agamagor-aguaverde",
            "estancado-trinquete", "estancado-aguaverde", "trinquete-espinosa", "espinosa-puente",
            "espinosa-groldom", "groldom-puente", "aguaverde-espinosa" },
    },
    -- --------------------------------------------------------------- Costa Oscura
    {
        key = "costaoscura", name = "Costa Oscura", short = "Costa Oscura", map = "Darkshore",
        desc = "La Horda desembarca en el sur y sube por la costa hacia Auberdine.",
        nodes = {
            { "auberdine", "Auberdine",               0.364, 0.456, "capital", "A" },
            { "paramo",    "Páramo de los Ancianos",  0.404, 0.744, "capital", "H" },
            { "bashal",    "Bashal'Aran",             0.454, 0.417 },
            { "fonroca",   "Río Fonroca",             0.489, 0.283 },
            { "althalaxx", "Torre de Althalaxx",      0.552, 0.273 },
            { "ameth",     "Ameth'Aran",              0.418, 0.612 },
            { "espada",    "La Espada del Maestro",   0.416, 0.882 },
            { "mathystra", "Ruinas de Mathystra",     0.606, 0.161, "outpost" },
            { "tripirrem", "Excavación de Tripirrem", 0.316, 0.863, "mine" },
        },
        links = { "auberdine-bashal", "auberdine-ameth", "bashal-ameth", "bashal-fonroca", "fonroca-althalaxx",
            "ameth-paramo", "paramo-espada", "althalaxx-bashal" },
    },
    -- --------------------------------------------------------------- Feralas
    {
        key = "feralas", name = "Feralas", short = "Feralas", map = "Feralas",
        desc = "Plumaluna y Mojache se disputan la selva y las ruinas de los altos elfos.",
        nodes = {
            { "plumaluna", "Bastión Plumaluna",           0.303, 0.433, "capital", "A" },
            { "mojache",   "Campamento Mojache",          0.754, 0.443, "capital", "H" },
            { "costa",     "La Costa Olvidada",           0.476, 0.623 },
            { "colosos",   "Los Dos Colosos",             0.461, 0.296 },
            { "masacre",   "La Masacre",                  0.568, 0.447 },
            { "cicatriz",  "Vega Cicatriz Feral",         0.542, 0.579 },
            { "plumavieja","Tierras Altas de Plumavieja", 0.532, 0.705 },
            { "isildien",  "Ruinas de Isildien",          0.634, 0.666 },
            { "totem",     "Dominios Tótem Siniestro",    0.682, 0.396 },
            { "gordunni",  "Avanzada Gordunni",           0.758, 0.335 },
            { "oniria",    "Rama Oniria",                 0.528, 0.094, "outpost" },
            { "retorcidas","Las Galerías Retorcidas",     0.737, 0.611, "mine" },
        },
        links = { "plumaluna-costa", "plumaluna-colosos", "costa-cicatriz", "costa-plumavieja", "colosos-masacre",
            "cicatriz-masacre", "masacre-totem", "totem-mojache", "plumavieja-isildien", "isildien-mojache",
            "cicatriz-isildien", "gordunni-mojache", "gordunni-totem" },
    },
}

-- Fortalezas de hermandad (sin calendario de asedio: siempre abiertas)
CdG.KEEPS = {
    { "espolon",    "Risco Cortaviento",        "StonetalonMountains", 0.712, 0.501, "Sierra Espolón" },
    { "humedales",  "Dun Modr",                 "Wetlands",            0.502, 0.166, "Los Humedales" },
    { "inhospitas", "Fortaleza de Angor",       "Badlands",            0.422, 0.371, "Tierras Inhóspitas" },
    { "cruce",      "El Cruce",                 "Barrens",             0.515, 0.304, "Los Baldíos" },
    { "mulgore",    "Poblado Pezuña de Sangre", "Mulgore",             0.494, 0.603, "Mulgore" },
}
-- Avanzadas de hermandad fuera de los frentes (las de antes ya están dentro de uno)
CdG.EXTRA_OUTPOSTS = {}   -- { clave, nombre, mapa, x, y, zona }
-- Minas fuera de los frentes (cada frente generado ya trae las suyas)
CdG.EXTRA_MINES = {}

-- Rangos (sobreviven al reinicio semanal; nunca bajan)
CdG.RANKS = {
    { 0, "Recluta" }, { 100, "Soldado" }, { 250, "Cabo" }, { 500, "Sargento" }, { 900, "Sargento primero" },
    { 1400, "Alférez" }, { 2100, "Teniente" }, { 3000, "Capitán" }, { 4200, "Comandante" }, { 5600, "Mayor" },
    { 7400, "Coronel" }, { 9600, "Brigadier" }, { 12500, "General" }, { 16000, "Mariscal" }, { 21000, "Señor de la Guerra" },
}

