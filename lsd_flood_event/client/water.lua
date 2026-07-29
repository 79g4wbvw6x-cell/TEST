-- ============================================================
-- MONTÉE D'EAU RÉELLE — manipulation des water quads
--
-- GTA V découpe son eau en "quads" définis dans water.xml (océan,
-- rivières, plans d'eau). FiveM expose des natives pour lire et
-- MODIFIER la hauteur de ces quads en temps réel.
--
-- C'est la vraie eau du moteur : vagues, nage, bateaux, reflets,
-- noyade native — tout fonctionne, contrairement à un faux plan
-- d'eau en prop.
--
-- Limite honnête: on ne peut relever que les quads QUI EXISTENT.
-- L'eau montera donc là où le jeu en connaît déjà (océan, rivières,
-- réservoir), inondant les côtes et les berges à mesure que le
-- niveau grimpe. Pour de l'eau en plein centre-ville, là où aucun
-- quad n'existe, il faut streamer un water.xml élargi (voir README).
-- ============================================================

local quadsCached   = false
local originalLevels = {}   -- [quadIndex] = niveau d'origine
local appliedLevel  = nil

-- Toutes les natives water quad de FiveM ne sont pas garanties selon
-- la version de l'artefact serveur. On vérifie leur présence plutôt
-- que de planter en silence.
local hasWaterNatives =
    type(GetWaterQuadCount) == 'function' and
    type(SetWaterQuadLevel) == 'function' and
    type(GetWaterQuadLevel) == 'function'

local function cacheOriginalLevels()
    if quadsCached then return true end
    if not hasWaterNatives then return false end

    local count = GetWaterQuadCount()
    if not count or count == 0 then
        print('[lsd_flood] Aucun water quad trouvé.')
        return false
    end

    for i = 0, count - 1 do
        local ok, lvl = GetWaterQuadLevel(i)
        if ok and lvl then
            originalLevels[i] = lvl
        elseif type(ok) == 'number' then
            -- certaines versions renvoient directement la valeur
            originalLevels[i] = ok
        end
    end

    quadsCached = true
    print(('[lsd_flood] %d water quads mis en cache.'):format(count))
    return true
end

-- Applique un niveau absolu à tous les quads.
-- On ne fait rien si le niveau n'a pas bougé: inutile de spammer
-- les natives à chaque frame.
local function applyWaterLevel(level)
    if not hasWaterNatives then return end
    if not cacheOriginalLevels() then return end
    if appliedLevel and math.abs(appliedLevel - level) < 0.01 then return end

    for i, _ in pairs(originalLevels) do
        SetWaterQuadLevel(i, level)
    end
    appliedLevel = level
end

local function restoreWaterLevel()
    if not hasWaterNatives or not quadsCached then return end
    for i, lvl in pairs(originalLevels) do
        SetWaterQuadLevel(i, lvl)
    end
    appliedLevel = nil
end

-- ------------------------------------------------------------
-- Suivi du niveau synchronisé
-- ------------------------------------------------------------

CreateThread(function()
    if not hasWaterNatives then
        print('[lsd_flood] ATTENTION: natives water quad indisponibles sur cet artefact.')
        print('[lsd_flood] La montée d\'eau ne sera pas visible. Mettez à jour votre serveur FiveM.')
        return
    end

    while true do
        local phase = GlobalState.lsd_floodPhase
        local level = GlobalState.lsd_waterLevel

        if phase and phase ~= 'idle' and level then
            applyWaterLevel(level)
            Wait(200)
        else
            if appliedLevel then restoreWaterLevel() end
            Wait(1000)
        end
    end
end)

-- Mer agitée pendant la crue, calme au retour à la normale
RegisterNetEvent('lsd_flood:phaseChanged', function(phase)
    if type(SetWavesIntensity) ~= 'function' then return end
    if phase == 'rupture' or phase == 'rising' or phase == 'peak' then
        SetWavesIntensity(Config.Water and Config.Water.wavesIntensity or 3.0)
    elseif phase == 'idle' then
        SetWavesIntensity(1.0)
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() ~= resName then return end
    restoreWaterLevel()
    if type(SetWavesIntensity) == 'function' then SetWavesIntensity(1.0) end
end)

-- ------------------------------------------------------------
-- Outils de test
-- ------------------------------------------------------------

if Config.DevCommands then
    -- Force un niveau d'eau immédiatement, sans lancer l'event.
    -- Le meilleur moyen de trouver la bonne valeur de peak.
    RegisterCommand('watertest', function(_, args)
        if not hasWaterNatives then
            print('[watertest] Natives water quad indisponibles sur cet artefact.')
            return
        end
        local lvl = tonumber(args[1])
        if not lvl then
            print('[watertest] Usage: /watertest <niveau_z>   (ex: /watertest 20)')
            print('[watertest] /watertest reset  pour revenir à la normale')
            return
        end
        applyWaterLevel(lvl)
        print(('[watertest] Niveau d\'eau forcé à %.1f'):format(lvl))
    end, false)

    RegisterCommand('waterreset', function()
        restoreWaterLevel()
        print('[waterreset] Niveau d\'eau restauré.')
    end, false)

    -- Diagnostic: combien de quads, et quel quad sous vos pieds
    RegisterCommand('waterinfo', function()
        if not hasWaterNatives then
            print('[waterinfo] Natives water quad indisponibles.')
            return
        end
        print(('[waterinfo] Nombre de water quads : %s'):format(GetWaterQuadCount()))
        local p = GetEntityCoords(PlayerPedId())
        if type(GetWaterQuadAtCoords) == 'function' then
            local q = GetWaterQuadAtCoords(p.x, p.y)
            print(('[waterinfo] Quad sous vous : %s (-1 = aucun)'):format(tostring(q)))
        end
    end, false)
end
