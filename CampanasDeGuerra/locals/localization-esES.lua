if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then return end

-- Traducción al español (esES y esMX). Las frases del sistema de los campos de
-- batalla siguen los textos del cliente en español (contrastados con DBM-PvP).
-- Los patrones se comparan en minúsculas, por eso van sin mayúscula inicial.
CappingLocale:CreateLocaleTable({
	-- campos de batalla
	["Alterac Valley"] = "Valle de Alterac",
	["Arathi Basin"] = "Cuenca de Arathi",
	["Warsong Gulch"] = "Garganta Grito de Guerra",
	["Eye of the Storm"] = "Ojo de la Tormenta",
	["Wintergrasp"] = "Conquista del Invierno",
	["Isle of Conquest"] = "Isla de la Conquista",

	-- menú de opciones
	["Auto Quest Turnins"] = "Entregar misiones automáticamente",
	["Bar"] = "Barra",
	["Width"] = "Ancho",
	["Height"] = "Alto",
	["Texture"] = "Textura",
	["Map Scale"] = "Escala del mapa",
	["Hide Border"] = "Ocultar borde",
	["Port Timer"] = "Tiempo para entrar",
	["Wait Timer"] = "Tiempo de espera en cola",
	["Show/Hide Anchor"] = "Mostrar/ocultar ancla",
	["Narrow Map Mode"] = "Mapa estrecho",
	["Narrow Anchor Left"] = "Anclar mapa estrecho a la izquierda",
	["Test"] = "Prueba",
	["Flip Growth"] = "Invertir apilado",
	["Single Group"] = "Un solo grupo",
	["Move Scoreboard"] = "Mover marcador",
	["Spacing"] = "Espaciado",
	["Request Sync"] = "Pedir sincronización",
	["Fill Grow"] = "Rellenar en vez de vaciar",
	["Fill Right"] = "Crecer hacia la derecha",
	["Font"] = "Fuente",
	["Time Position"] = "Posición del tiempo",
	["Border Width"] = "Margen interior",
	["Send to BG"] = "Enviar al campo de batalla",
	["Send to SAY"] = "Enviar a /decir",
	["Cancel Timer"] = "Cancelar temporizador",
	["Move Capture Bar"] = "Mover barra de captura",
	["Move Vehicle Seat"] = "Mover asientos de vehículo",

	-- temporizadores varios
	["Port: %s"] = "Entrar: %s",
	["Queue: %s"] = "Cola: %s",
	["Battle Begins"] = "Comienza la batalla",
	["1 minute"] = "1 minuto",
	["60 seconds"] = "60 segundos",
	["30 seconds"] = "30 segundos",
	["15 seconds"] = "15 segundos",
	["One minute until"] = "un minuto",
	["Forty five seconds"] = "cuarenta y cinco segundos",
	["Thirty seconds until"] = "treinta segundos",
	["Fifteen seconds until"] = "quince segundos",
	["has begun"] = "ha comenzado",
	["%s: %s - %d:%02d"] = "%s: %s - %d:%02d",

	-- Cuenca de Arathi / Ojo de la Tormenta
	-- El marcador se lee por sus números, así funciona con cualquier redacción
	["Bases: (%d+)  Resources: (%d+)/(%d+)"] = "(%d+)%D+(%d+)/(%d+)",
	["has assaulted"] = "ha asaltado",
	["claims the"] = "reclama",
	["has taken the"] = "ha tomado",
	["has defended the"] = "ha defendido",
	["Final: %d - %d"] = "Final: %d - %d",
	["wins %d-%d"] = "gana %d-%d",

	-- Garganta Grito de Guerra
	["was picked up by (.+)!"] = "¡(.+) ha cogido la bandera",
	["was picked up by (.+)!2"] = "¡(.+) ha recogido la bandera",
	["dropped"] = "dejado caer",
	["captured the"] = "ha capturado la bandera",
	["Flag respawns"] = "Reaparece la bandera",
	["%s's flag carrier: %s (%s)"] = "Portador de la bandera (%s): %s (%s)",

	-- Valle de Alterac: PNJ
	["Smith Regzar"] = "Herrero Regzar",
	["Murgot Deepforge"] = "Murgot Forjahonda",
	["Primalist Thurloga"] = "Primalista Thurloga",
	["Arch Druid Renferal"] = "Archidruida Renferal",
	["Stormpike Ram Rider Commander"] = "Comandante de jinetes de carneros Pico Tormenta",
	["Frostwolf Wolf Rider Commander"] = "Comandante de jinetes de lobos Lobo Gélido",

	-- Valle de Alterac: frases
	["Upgrade to"] = "Mejorar",
	["Wicked, wicked, mortals!"] = "¡Malvados, malvados mortales!",
	["Ivus begins moving"] = "Ivus se pone en marcha",
	["WHO DARES SUMMON LOKHOLAR"] = "QUIÉN OSA INVOCAR A LOKHOLAR",
	["The Ice Lord has arrived!"] = "¡Ha llegado el Señor del Hielo!",
	["Lokholar begins moving"] = "Lokholar se pone en marcha",

	-- Ojo de la Tormenta
	["^(.+) has taken the flag!"] = "^¡(.+) ha tomado la bandera!",
	["Bases: (%d+)  Victory Points: (%d+)/(%d+)"] = "(%d+)%D+(%d+)/(%d+)",

	-- Isla de la Conquista
	["Alliance Keep"] = "Fortaleza de la Alianza",
	["Horde Keep"] = "Fortaleza de la Horda",
	["Goblin"] = "oblin",                -- el mecánico de la Horda es goblin
	["seaforium bombs"] = "bombas de seforio",
	["It's broken"] = "rota",
	["halfway"] = "a medias",            -- Alianza: "¡Estoy a medias!"
	["halfway2"] = "casi estoy",         -- Horda: "¡Ya casi estoy!"
})
