Config = {}

Config.Locale = 'fr'

-- Commande admin pour déclencher/stopper l'event (ACE permission requise: lsd.flood)
Config.AdminCommand = 'startflood'
Config.StopCommand = 'stopflood'
Config.AdminAce = 'command.startflood'

Config.Dam = {
    label = 'Barrage de Land Act',
    coords = vector3(2645.6, 3474.4, 94.5),

    -- Point exact de la brèche (là où l'eau jaillit). À ajuster en jeu avec
    -- /damscan qui affiche vos coordonnées + le modèle visé.
    breach = {
        coords  = vector3(2637.0, 3465.0, 62.0),
        heading = 210.0,  -- direction dans laquelle l'eau est projetée
        width   = 18.0    -- largeur de la brèche (nb d'émetteurs répartis dessus)
    }
}

-- Durées de chaque phase (secondes)
Config.Phases = {
    alert     = 45,   -- sirènes + alerte radio, pas encore d'eau
    rupture   = 25,   -- explosion + effondrement du barrage + départ de la vague
    rising    = 480,  -- montée progressive de l'eau (8 min)
    peak      = 120,  -- eau au maximum, stable
    receding  = 300   -- décrue progressive
}

-- ============================================================
-- RUPTURE DU BARRAGE
-- ============================================================
Config.Rupture = {
    -- Charges explosives déclenchées en cascade sur la crête du barrage.
    -- offset = décalage par rapport à Config.Dam.breach.coords
    explosions = {
        { offset = vector3(-14.0, 6.0, 12.0), delay = 0,    type = 5,  scale = 1.0 },
        { offset = vector3(  0.0, 0.0, 12.0), delay = 900,  type = 5,  scale = 1.0 },
        { offset = vector3( 14.0,-6.0, 12.0), delay = 1700, type = 5,  scale = 1.0 },
        { offset = vector3( -6.0, 2.0,  4.0), delay = 2600, type = 13, scale = 0.8 },
        { offset = vector3(  6.0,-2.0,  4.0), delay = 3100, type = 13, scale = 0.8 }
    },

    -- Remplacement visuel du barrage intact par une version éventrée.
    -- IMPORTANT: nécessite VOTRE asset (voir README). Laissez à nil pour
    -- désactiver proprement — le reste de l'effet fonctionne sans.
    modelSwap = {
        enabled   = false,
        srcModel  = nil,   -- ex: 'des_damdoors' (à trouver via /damscan)
        dstModel  = nil,   -- ex: 'lsd_dam_broken' (votre prop custom streamé)
        radius    = 60.0
    },

    -- Masquage pur et simple d'une portion du barrage (sans asset de
    -- remplacement) : crée un "trou" visuel par lequel l'eau jaillit.
    modelHide = {
        enabled = false,
        model   = nil,     -- hash/nom du morceau à masquer (via /damscan)
        radius  = 25.0
    },

    -- Particules du torrent jaillissant de la brèche.
    -- ⚠️ Ces noms d'assets ptfx sont des CANDIDATS à valider en jeu avec
    -- /ptfxtest <dict> <effet> — voir README, section "Valider les ptfx".
    ptfx = {
        dict   = 'core',
        effect = 'water_splash_ped_in',
        scale  = 6.0,
        emitterSpacing = 3.0,   -- un émetteur tous les X mètres sur la brèche
        renderDistance = 350.0  -- au-delà, les émetteurs ne sont pas créés (perf)
    },

    -- Vague de crue qui part du barrage et déferle vers la ville.
    -- Chaque node = un point de passage; travelTime = durée totale du trajet.
    wave = {
        enabled    = true,
        travelTime = 180,  -- secondes pour aller du barrage aux quartiers bas
        width      = 90.0, -- rayon d'influence de la vague (knockback)
        ptfxScale  = 9.0,
        path = {
            vector3(2637.0, 3465.0, 55.0),
            vector3(2200.0, 3100.0, 40.0),
            vector3(1700.0, 2400.0, 30.0),
            vector3(1100.0, 1400.0, 25.0),
            vector3( 600.0,  200.0, 20.0),
            vector3( 300.0, -900.0, 15.0),
            vector3( 350.0,-1930.0, 10.0)
        }
    },

    -- Effets ressentis par le joueur au passage de la vague
    impact = {
        ragdollPlayers   = true,
        ragdollDuration  = 3000,
        vehicleForce     = 12.0,  -- poussée appliquée aux véhicules pris dedans
        camShake         = 'LARGE_EXPLOSION_SHAKE'
    }
}

-- Commande de repérage pour développeur (client-side, lecture seule)
Config.DevCommands = true

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
