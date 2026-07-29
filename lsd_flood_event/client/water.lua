-- ============================================================
-- MONTÉE D'EAU RÉELLE
--
-- Deux mécanismes, essayés dans cet ordre :
--
--  1. LoadWaterFromPath : recharge un water.xml complet. C'est la
--     SEULE méthode qui force le moteur à re-rendre l'eau. On
--     pré-génère un fichier par palier de hauteur (voir
--     tools/generate_water_levels.py) et on charge celui qui
--     correspond au niveau courant.
--
--  2. SetWaterQuadLevel : modifie les quads en mémoire. Utilisé en
--     complément, car ça met à jour la logique de collision/nage
--     même quand le rendu ne suit pas. Seul, ça ne suffit PAS —
--     les quads changent mais l'eau reste affichée à sa hauteur
--     d'origine.
--
-- C'est la vraie eau du moteur : on nage dedans, les bateaux
-- flottent, la noyade native fonctionne.
-- ============================================================

local quadsCached    = false
local originalLevels = {}
local loadedLevelFile = nil
local appliedQuadLevel = nil

local hasQuadNatives =
    type(GetWaterQuadCount) == 'function' and
    type(SetWaterQuadLevel) == 'function'

local hasLoadWater = type(LoadWaterFromPath) == 'function'

-- ------------------------------------------------------------
-- Mécanisme 1 : rechargement de water.xml
-- ------------------------------------------------------------

-- Trouve le palier pré-généré le plus proche du niveau demandé
local function nearestLevel(target)
    local levels = Config.Water and Config.Water.levels
    if not levels or #levels == 0 then return nil end
    local best, bestDiff = nil, math.huge
    for _, v in ipairs(levels) do
        local d = math.abs(v - target)
        if d < bestDiff then best, bestDiff = v, d end
    end
    return best
end

local function loadWaterFile(level)
    if not hasLoadWater then return false end
    local lvl = nearestLevel(level)
    if not lvl then return false end
    if loadedLevelFile == lvl then return true end  -- déjà chargé

    local file = ('stream/water_lvl_%02d.xml'):format(lvl)
    local ok = LoadWaterFromPath(GetCurrentResourceName(), file)
    if ok then
        loadedLevelFile = lvl
        return true
    else
        print(('[lsd_flood] Echec du chargement de %s'):format(file))
        return false
    end
end

local function restoreWaterFile()
    if not hasLoadWater then return end
    -- ResetWater remet le water.xml d'origine du jeu
    if type(ResetWater) == 'function' then
        ResetWater()
    elseif Config.Water and Config.Water.baseFile then
        LoadWaterFromPath(GetCurrentResourceName(), Config.Water.baseFile)
    end
    loadedLevelFile = nil
end

-- ------------------------------------------------------------
-- Mécanisme 2 : quads en mémoire (complément)
-- ------------------------------------------------------------

local function cacheOriginalLevels()
    if quadsCached then return true end
    if not hasQuadNatives then return false end
    local count = GetWaterQuadCount()
    if not count or count == 0 then return false end
    for i = 0, count - 1 do
        local a, b = GetWaterQuadLevel(i)
        originalLevels[i] = (type(b) == 'number') and b or a
    end
    quadsCached = true
    return true
end

local function applyQuadLevel(level)
    if not hasQuadNatives then return end
    if not cacheOriginalLevels() then return end
    if appliedQuadLevel and math.abs(appliedQuadLevel - level) < 0.01 then return end
    for i, _ in pairs(originalLevels) do
        SetWaterQuadLevel(i, level)
    end
    appliedQuadLevel = level
end

local function restoreQuadLevels()
    if not hasQuadNatives or not quadsCached then return end
    for i, lvl in pairs(originalLevels) do
        SetWaterQuadLevel(i, lvl)
    end
    appliedQuadLevel = nil
end

-- ------------------------------------------------------------
-- Application combinée
-- ------------------------------------------------------------

local function setFloodLevel(level)
    loadWaterFile(level)
    applyQuadLevel(level)
end

local function restoreWater()
    restoreWaterFile()
    restoreQuadLevels()
end

-- ------------------------------------------------------------
-- Suivi du niveau synchronisé
-- ------------------------------------------------------------

CreateThread(function()
    if not hasLoadWater then
        print('[lsd_flood] ATTENTION: LoadWaterFromPath indisponible sur cet artefact FiveM.')
        print('[lsd_flood] La montee d\'eau ne sera pas visible. Mettez a jour votre serveur.')
    end
    if not (Config.Water and Config.Water.levels and #Config.Water.levels > 0) then
        print('[lsd_flood] Aucun palier d\'eau genere. Voir tools/generate_water_levels.py')
    end

    while true do
        local phase = GlobalState.lsd_floodPhase
        local level = GlobalState.lsd_waterLevel

        if phase and phase ~= 'idle' and level then
            setFloodLevel(level)
            Wait(500)
        else
            if loadedLevelFile or appliedQuadLevel then restoreWater() end
            Wait(1000)
        end
    end
end)

RegisterNetEvent('lsd_flood:phaseChanged', function(phase)
    if type(SetWavesIntensity) ~= 'function' then return end
    if phase == 'rupture' or phase == 'rising' or phase == 'peak' then
        SetWavesIntensity((Config.Water and Config.Water.wavesIntensity) or 3.0)
    elseif phase == 'idle' then
        SetWavesIntensity(1.0)
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() ~= resName then return end
    restoreWater()
    if type(SetWavesIntensity) == 'function' then SetWavesIntensity(1.0) end
end)

-- ------------------------------------------------------------
-- Outils de test
-- ------------------------------------------------------------

if Config.DevCommands then
    RegisterCommand('watertest', function(_, args)
        local lvl = tonumber(args[1])
        if not lvl then
            print('[watertest] Usage: /watertest <niveau_z>   (ex: /watertest 20)')
            return
        end
        setFloodLevel(lvl)
        print(('[watertest] Niveau demande %.1f -> palier charge: %s'):format(
            lvl, tostring(loadedLevelFile)))
        if not loadedLevelFile then
            print('[watertest] Aucun palier charge: les fichiers water_lvl_XX.xml manquent.')
            print('[watertest] Generez-les avec tools/generate_water_levels.py')
        end
    end, false)

    RegisterCommand('waterreset', function()
        restoreWater()
        print('[waterreset] Eau restauree.')
    end, false)

    RegisterCommand('waterinfo', function()
        print(('[waterinfo] LoadWaterFromPath dispo : %s'):format(tostring(hasLoadWater)))
        print(('[waterinfo] ResetWater dispo        : %s'):format(tostring(type(ResetWater) == 'function')))
        print(('[waterinfo] Natives quad dispo      : %s'):format(tostring(hasQuadNatives)))
        if hasQuadNatives then
            print(('[waterinfo] Nombre de water quads   : %s'):format(GetWaterQuadCount()))
        end
        local n = (Config.Water and Config.Water.levels) and #Config.Water.levels or 0
        print(('[waterinfo] Paliers generes         : %d'):format(n))
        print(('[waterinfo] Palier actuellement charge : %s'):format(tostring(loadedLevelFile)))
    end, false)
end
