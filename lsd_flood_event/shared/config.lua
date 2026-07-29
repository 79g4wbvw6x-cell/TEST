Config = {}

Config.Locale = 'fr'

-- Commande admin pour déclencher/stopper l'event (ACE permission requise: lsd.flood)
Config.AdminCommand = 'startflood'
Config.StopCommand = 'stopflood'
Config.AdminAce = 'command.startflood'

-- Coordonnées relevées dans ch3_08.ymap (secteur cityhills_03).
-- Le barrage se situe autour de x=1662, y=-18, z=157.
Config.Dam = {
    label = 'Barrage de Land Act',
    coords = vector3(1662.3, -18.4, 157.3),   -- ch3_08_dam_slod

    -- Point de la brèche: face aval du mur, d'où l'eau se déverse vers les
    -- déversoirs. À affiner en jeu avec /damscan une fois sur place.
    breach = {
        coords  = vector3(1655.0, -30.0, 140.0),
        heading = 250.0,  -- projection vers l'ouest, dans l'axe des déversoirs
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

    -- Masquage d'une portion du barrage (sans asset de remplacement) :
    -- crée un "trou" visuel par lequel l'eau jaillit.
    --
    -- Le barrage est composé de plusieurs morceaux distincts, relevés dans
    -- ch3_08.ymap. Les noms ci-dessous sont les noms HD déduits des entités
    -- LOD (règle vérifiée sur un cas réel : ch3_08_damculvert001_lod a pour
    -- enfant HD ch3_08_damculvert001).
    -- ⚠️ À CONFIRMER en jeu avec /damscan avant de mettre enabled = true.
    modelHide = {
        enabled = false,
        radius  = 40.0,
        models  = {
            'ch3_08_dam_plat',      -- plateforme      (1662.1, -25.8, 169.3)
            'ch3_08_dam_corr',      -- passerelle      (1661.8,  -2.9, 168.5)
            'ch3_08_dam_mp003',     -- mur             (1659.5, -23.5, 163.9)
            'ch3_08_dam_mp2_01',    -- mur             (1660.9, -20.4, 157.2)
            'ch3_08_dam_scaff'      -- échafaudage     (1656.3, -52.5, 156.7)
        }
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
        -- Trajet calqué sur les déversoirs réels du barrage (relevés dans
        -- ch3_08.ymap) : l'eau descend en escalier 157 -> 123 -> 91 -> 61,
        -- puis rejoint les quartiers bas. Les 4 premiers points sont des
        -- positions exactes du jeu, les suivants sont à affiner en jeu.
        path = {
            vector3(1655.0,  -30.0, 145.0),  -- brèche du barrage
            vector3(1577.3,  -35.6, 122.8),  -- ch3_08_weir_03
            vector3(1433.7,  -63.4,  91.0),  -- ch3_08_weir_02
            vector3(1192.5,  -93.9,  61.1),  -- ch3_08_weir_01
            vector3( 900.0, -400.0,  40.0),
            vector3( 650.0, -900.0,  28.0),
            vector3( 450.0,-1450.0,  20.0),
            vector3( 390.0,-1932.0,  12.0)   -- Rancho
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

-- Niveau d'eau (Z absolu) avant/pendant/après l'event.
-- Réglez peak en jeu avec /watertest <niveau> avant de fixer la valeur :
--   ~5   = les plages et quais sont noyés
--   ~15  = Elysian Island, La Puerta, le port sous l'eau
--   ~27  = Vespucci, Del Perro, une partie de Strawberry
--   ~40  = centre-ville touché (très extrême)
Config.WaterLevel = {
    base = 0.0,     -- niveau mer normal GTA
    peak = 26.5
}

Config.Water = {
    wavesIntensity = 3.0,  -- agitation de la mer pendant la crue (1.0 = normal)

    -- Paliers de hauteur pré-générés dans stream/water_lvl_XX.xml.
    -- Générés par tools/generate_water_levels.py, qui affiche la liste
    -- exacte à recopier ici. Tant que cette table est vide, l'eau ne
    -- montera pas : c'est le rechargement de ces fichiers qui produit
    -- l'effet visuel.
    levels = { 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34,
               36, 38, 40, 42, 44, 46, 48, 50, 52, 54, 56, 58, 60, 62, 64, 66,
               68, 70, 72, 74, 76, 78, 80 }
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
        vector3(1662.3, -18.4, 157.3),  -- barrage
        vector3(390.0, -1932.0, 22.0),
        vector3(280.0, -2780.0, 5.0),
        vector3(-230.0, -2900.0, 5.0),
        vector3(-1580.0, -450.0, 32.0),
        vector3(200.0, -900.0, 28.0)
    },
    range = 600.0
}
