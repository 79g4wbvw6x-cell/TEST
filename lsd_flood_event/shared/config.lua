Config = {}

Config.Locale = 'fr'

-- Commande admin pour déclencher/stopper l'event (ACE permission requise: lsd.flood)
Config.AdminCommand = 'startflood'
Config.StopCommand = 'stopflood'
Config.AdminAce = 'command.startflood'

Config.Dam = {
    label = 'Barrage de Land Act',
    coords = vector3(2645.6, 3474.4, 94.5)
}

-- Durées de chaque phase (secondes)
Config.Phases = {
    alert     = 45,   -- sirènes + alerte radio, pas encore d'eau
    rising    = 480,  -- montée progressive de l'eau (8 min)
    peak      = 120,  -- eau au maximum, stable
    receding  = 300   -- décrue progressive
}

-- Niveau d'eau (Z absolu) avant/pendant/après l'event
Config.WaterLevel = {
    base = 0.0,     -- niveau mer normal GTA
    peak = 26.5      -- submerge les quartiers bas (Rancho, Strawberry, Elysian Island, La Puerta)
}

-- Zones inondées : utilisées pour les dégâts, les blips d'alerte et les effets
Config.FloodZones = {
    { label = 'Rancho',         center = vector3(390.0, -1932.0, 22.0), radius = 400.0 },
    { label = 'Strawberry',     center = vector3(300.0, -1980.0, 25.0), radius = 350.0 },
    { label = 'Elysian Island', center = vector3(280.0, -2780.0, 5.0),  radius = 450.0 },
    { label = 'La Puerta',      center = vector3(-230.0, -2900.0, 5.0), radius = 400.0 },
    { label = 'Del Perro',      center = vector3(-1580.0, -450.0, 32.0), radius = 350.0 },
    { label = 'Legion Square',  center = vector3(200.0, -900.0, 28.0),  radius = 300.0 }
}

-- Points d'évacuation en hauteur, hors zone inondable
Config.EvacPoints = {
    { label = 'Vinewood Hills - Point Haut',   coords = vector3(273.0, 549.0, 173.0) },
    { label = 'Rockford Hills - Toit Sécurisé', coords = vector3(-750.0, 330.0, 100.0) },
    { label = 'Mount Chiliad - Refuge',        coords = vector3(501.0, 5604.0, 797.0) },
    { label = 'Vespucci - Parking Élevé',      coords = vector3(-1097.0, -1520.0, 15.0) }
}

-- Système de survie / noyade
Config.Survival = {
    enabled = true,
    checkInterval = 2000,       -- ms entre chaque vérification serveur
    damagePerTick = 4,          -- dégâts appliqués si submergé sans échapper
    safeSubmersion = 0.35,      -- niveau de submersion ped (0-1) toléré avant dégâts (nage possible)
    graceBeforeDamage = 20      -- secondes après le début de submersion locale avant 1er dégât
}

-- Audio / immersion
Config.Sirens = {
    soundset = 'DLC_HEIST_HACKING_SNAKE_SOUNDS',
    -- fallback: sirène via native PLAY_SOUND_FROM_COORD, réutilise un son d'alarme existant du jeu
    coordsSirens = {
        vector3(2645.6, 3474.4, 94.5),
        vector3(390.0, -1932.0, 22.0),
        vector3(280.0, -2780.0, 5.0),
        vector3(-230.0, -2900.0, 5.0),
        vector3(-1580.0, -450.0, 32.0),
        vector3(200.0, -900.0, 28.0)
    },
    range = 600.0
}
