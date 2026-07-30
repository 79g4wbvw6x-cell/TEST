Config = {}

Config.Locale = 'fr'

-- Commande admin pour déclencher/stopper l'event (ACE permission requise: lsd.flood)
Config.AdminCommand = 'startflood'
Config.StopCommand = 'stopflood'
Config.AdminAce = 'command.startflood'

-- Panel visuel complet: contrôle de l'event, météo/heure, blackout,
-- véhicules, armes, outils joueur. Touche par défaut F6.
Config.AdminPanel = {
    command = 'floodpanel',
    key     = 'F6'
}

-- Durées de chaque phase (secondes)
Config.Phases = {
    alert     = 60,    -- alerte tsunami: sirènes, le mur d'eau est visible au loin sur l'océan
    rupture   = 90,    -- le tsunami traverse l'océan et touche la côte (landfall)
    rising    = 480,   -- montée progressive de l'eau sur la ville (8 min)
    peak      = 120,   -- eau au maximum, stable
    receding  = 300    -- décrue progressive
}

-- ============================================================
-- TSUNAMI — plus simple et plus fiable qu'une rupture de barrage:
-- pas de modèle à casser, pas de collision à éditer. Juste une vague
-- qui vient du large, visible longtemps avant d'arriver, qui touche
-- la côte puis recouvre la ville (la montée d'eau elle-même est gérée
-- par client/water.lua, indépendamment).
-- ============================================================
Config.Tsunami = {
    -- Origine juste au large de Vespucci Beach — assez proche pour être
    -- réellement dans la distance de rendu du jeu (les marqueurs/particules
    -- à plusieurs km ne s'affichent pas de façon fiable, c'était le
    -- problème de la version précédente). "Vient de la plage": le joueur
    -- posté sur le sable la voit dès le début de l'alerte.
    origin = vector3(-2050.0, -2300.0, 0.0),   -- ~700m au large de Vespucci Beach

    -- Landfall: directement sur le sable de Vespucci Beach.
    landfall = vector3(-1400.0, -2000.0, 0.0),

    -- Trajet complet: de la plage jusqu'aux quartiers bas.
    path = {
        vector3(-2050.0, -2300.0, 0.0),  -- origine, juste au large
        vector3(-1700.0, -2130.0, 0.0),
        vector3(-1400.0, -2000.0, 0.0),  -- landfall: Vespucci Beach
        vector3(-1097.0, -1520.0, 0.0),  -- Vespucci
        vector3(  200.0,  -900.0, 0.0),  -- Legion Square
        vector3(  280.0, -2780.0, 0.0),  -- Elysian Island
        vector3(  390.0, -1932.0, 0.0)   -- Rancho
    },

    -- Durée totale du trajet. Long exprès: le joueur voit la vague monter
    -- à l'horizon pendant l'alerte, avant qu'elle ne touche terre.
    travelTime = 240,

    -- Portion du trajet visible "au loin" avant l'impact (fraction 0-1 du
    -- travelTime). Pendant cette portion, un mur imposant + panache et un
    -- grondement sont joués — pas d'impact physique, le joueur ne fait que
    -- la voir venir grossir.
    -- Recalculé pour le nouveau trajet plus court (origine proche de la
    -- plage): le segment océan ne représente plus que ~13% de la distance
    -- totale jusqu'à Rancho.
    landfallProgress = 0.13,

    width      = 600.0,   -- largeur du front (mur visuel + zone d'impact)
    wallHeight = 140.0,   -- hauteur du mur au moment de l'impact — vraiment énorme
    ptfxScale  = 18.0,

    -- Distance à partir de laquelle le mur/panache commencent à être
    -- rendus. Volontairement large: c'est ce qui donne l'effet "on le voit
    -- venir de loin". Les marqueurs/particules sont coûteux à faible
    -- distance mais quasi gratuits au-delà de quelques centaines de mètres.
    renderDistance = 3500.0,

    -- Effets ressentis par le joueur au passage du front (après landfall
    -- uniquement — pendant l'approche au loin, aucun impact)
    impact = {
        ragdollPlayers  = true,
        ragdollDuration = 3000,
        vehicleForce    = 16.0,
        camShake        = 'LARGE_EXPLOSION_SHAKE'
    },

    -- Grondement qui s'intensifie à mesure que la vague approche
    rumble = {
        enabled  = true,
        soundset = 'DLC_HEIST_HACKING_SNAKE_SOUNDS'
    }
}

-- ============================================================
-- MISE EN SCÈNE — tout ce qui rend l'event spectaculaire.
-- Chaque bloc est indépendant : coupez ce qui ne vous plaît pas.
-- ============================================================
Config.Spectacle = {

    -- Le tsunami détruit les infrastructures électriques du littoral :
    -- Los Santos (Sud) s'éteint, Blaine County (Nord) reste sur son propre réseau.
    --
    -- GTA n'a qu'un interrupteur global pour les lumières artificielles
    -- (pas de version par zone dans le moteur), donc l'effet est simulé
    -- par position: chaque client active/désactive SES lumières selon
    -- l'endroit où IL se trouve. Un joueur au Sud voit le clignotement,
    -- un joueur au Nord ne le voit jamais — correct puisque le rendu est
    -- de toute façon local à chaque client.
    blackout = {
        enabled     = true,
        boundaryY   = 500.0,   -- y < boundaryY = Sud (ville) ; y >= boundaryY = Nord (comté)
                                -- Ajustez si la frontière ne vous convient pas en jeu.
        flickerOnMin  = 800,   -- ms lumières allumées (min)
        flickerOnMax  = 2500,  -- ms lumières allumées (max)
        flickerOffMin = 400,   -- ms lumières éteintes (min)
        flickerOffMax = 1800   -- ms lumières éteintes (max)
    },

    -- Ambiance visuelle par phase (noms de timecycle du jeu)
    timecycle = {
        enabled  = true,
        alert    = 'Storm',        -- ciel qui se couvre
        disaster = 'Dark_Storm',   -- apocalypse
        recovery = 'morgue_dark'   -- lendemain glauque
    },

    -- Éclairs pendant la catastrophe
    lightning = {
        enabled  = true,
        minDelay = 4000,
        maxDelay = 15000
    },

    -- Les PNJ paniquent et fuient loin de la crue
    panic = {
        enabled    = true,
        interval   = 3000,
        radius     = 120.0,
        maxPerTick = 8      -- limite pour ne pas plomber les FPS
    },

    -- Débris emportés par le courant, flottant à la surface
    debris = {
        enabled  = true,
        interval = 4000,
        perWave  = 2,
        maxAlive = 25,
        minDist  = 25.0,
        maxDist  = 70.0,
        maxHeightAboveWater = 40.0,
        driftX   = 3.0,
        driftY   = -2.0,
        models   = {
            'prop_barrel_02a', 'prop_woodpile_01a', 'prop_bin_08a',
            'prop_rub_wooden_pallet', 'prop_dumpster_01a',
            'prop_logpile_02', 'prop_cablespool_02', 'prop_water_barrel'
        }
    },

    -- Hélicoptères de secours en patrouille avec projecteur
    helicopters = {
        enabled    = true,
        interval   = 45000,
        maxAlive   = 2,
        model      = 'polmav',
        pilotModel = 's_m_y_pilot_01',
        spawnDist  = 200.0,
        altitude   = 60.0
    },

    -- Alertes diffusées au fil de l'event
    messages = {
        alert = {
            '~r~ALERTE TSUNAMI~s~ — Un mur d\'eau a été repéré au large.',
            '~y~Les services d\'urgence ordonnent l\'évacuation des quartiers bas.',
            '~r~La vague est visible à l\'horizon. Rejoignez la hauteur MAINTENANT.'
        },
        rupture = {
            '~r~LA VAGUE TOUCHE LA CÔTE.~s~ Impact imminent sur Los Santos.',
            '~r~Coupure générale du réseau électrique.',
            '~y~Fuyez les zones basses IMMÉDIATEMENT.'
        },
        rising = {
            '~r~Le niveau de l\'eau monte rapidement.',
            '~y~Elysian Island et La Puerta sont submergées.',
            '~y~Les secours héliportés survolent les zones sinistrées.',
            '~r~Ne tentez pas de traverser les courants à pied.'
        },
        peak = {
            '~y~Le niveau de l\'eau s\'est stabilisé.',
            '~y~Restez en hauteur, la décrue n\'a pas commencé.'
        },
        receding = {
            '~g~La décrue est amorcée.',
            '~y~Les équipes de secours entament les recherches.'
        }
    }
}

-- ============================================================
-- MENU CONTEXTUEL (touche ALT). Actions RP visibles par tous, actions
-- [Admin] filtrées côté serveur selon Config.AdminAce.
--
-- Liste d'animations volontairement COURTE et honnête: je n'ai pas pu
-- tester ces dict/clip en jeu, seulement les documenter comme
-- raisonnablement fiables. Utilisez /animtest <dict> <clip> pour en
-- valider de nouvelles avant de les ajouter ici.
-- ============================================================
Config.SelfAnimations = {
    { label = 'Lever les mains',        dict = 'random@mugging3',                          clip = 'handsup_standing_base' },
    { label = 'S\'asseoir',             dict = 'amb@world_human_seat_wall_tablet@male@base', clip = 'base' },
    { label = 'Fumer une cigarette',    dict = 'amb@world_human_smoking@male@male_a@base', clip = 'base' },
    { label = 'Attendre bras croisés',  dict = 'anim@amb@business@bgen@bgen_no_work@',     clip = 'base' },
    { label = 'Danser',                 dict = 'dance_fac_ch_bd_am',                        clip = 'dance_fac_ch_bd_am' },
    { label = 'Applaudir',              dict = 'anim@mp_player_intcelebrationmale@golf_clap', clip = 'golf_clap' }
}

-- Corrige la démarche "combat stance" qui reste figée (arme à deux
-- mains, pas raide) après avoir tiré et relâché la visée.
Config.CombatStanceFix = {
    enabled       = true,
    checkInterval = 150,  -- ms entre chaque vérification
    graceMs       = 250   -- ms sans viser/tirer avant de forcer le reset
}

-- Commandes de repérage pour développeur (client-side, lecture seule)
Config.DevCommands = true

-- Niveau d'eau (Z absolu) avant/pendant/après l'event.
-- Réglez peak en jeu avec /watertest <niveau> avant de fixer la valeur :
--   ~5   = les plages et quais sont noyés
--   ~15  = Elysian Island, La Puerta, le port sous l'eau
--   ~27  = Vespucci, Del Perro, une partie de Strawberry
--   ~40  = centre-ville touché (très extrême)
Config.WaterLevel = {
    base = 0.0,      -- niveau mer normal GTA
    peak = 35.0      -- niveau par défaut de la séquence auto. Ajustable en jeu à
                      -- tout moment via le panel (F6 > Événement > Niveau d'eau
                      -- manuel) ou /watertest <niveau>, jusqu'à 150 max.
}

Config.Water = {
    wavesIntensity = 3.0,  -- agitation de la mer pendant la crue (1.0 = normal)

    -- Paliers de hauteur pré-générés dans stream/water_lvl_XX.xml.
    -- Générés par tools/generate_water_levels.py, qui affiche la liste
    -- exacte à recopier ici. Tant que cette table est vide, l'eau ne
    -- montera pas : c'est le rechargement de ces fichiers qui produit
    -- l'effet visuel.
    levels = { 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80,
               85, 90, 95, 100, 105, 110, 115, 120, 125, 130, 135, 140, 145, 150 }
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
-- Sirène jouée via l'audio HTML du panel NUI (html/sounds/tsunami_siren.mp3),
-- fiable pour tous les joueurs sans dépendance externe.
Config.Sirens = {
    volume = 0.8  -- 0.0 à 1.0
}
