ESX = exports['es_extended']:getSharedObject()

local currentPhase = 'idle'
-- niveau d eau courant, lu depuis GlobalState
local currentWaterZ = Config.WaterLevel.base
local hasXSound = GetResourceState('xsound') == 'started'
local sirenSoundId = 'lsd_flood_siren'
local blips = {}

-- ============================================================
-- SYNCHRO: le niveau d'eau et la phase sont lus depuis les statebags
-- globaux (GlobalState). Pas de spam d'events réseau: chaque client
-- lit l'état à son propre rythme, ce qui garde le serveur stable
-- même avec beaucoup de joueurs.
-- ============================================================

CreateThread(function()
    TriggerServerEvent('lsd_flood:requestState')
end)

RegisterNetEvent('lsd_flood:syncState', function(phase, waterLevel)
    currentPhase = phase
    currentWaterZ = waterLevel
end)

-- ============================================================
-- L'eau elle-même est gérée dans client/water.lua, via les water
-- quads natifs du jeu (vraie eau: vagues, nage, bateaux, reflets).
-- Ici on ne garde que le suivi du niveau courant, utilisé par la
-- logique de survie ci-dessous.
-- ============================================================

CreateThread(function()
    while true do
        Wait(250)
        local lvl = GlobalState.lsd_waterLevel
        if lvl then currentWaterZ = lvl end
    end
end)

-- ============================================================
-- SIRÈNES / ALERTE
-- ============================================================

local function playSirens()
    if hasXSound then
        exports.xsound:PlayUrlPos(sirenSoundId, Config.Sirens.url or 'https://your-cdn.example/siren_loop.ogg', 0.6, Config.Sirens.coordsSirens[1], true)
        exports.xsound:setRange(sirenSoundId, Config.Sirens.range)
    else
        CreateThread(function()
            while currentPhase == 'alert' do
                for _, coords in ipairs(Config.Sirens.coordsSirens) do
                    PlaySoundFromCoord(-1, 'Bed', coords.x, coords.y, coords.z, 'DLC_HEIST_HACKING_SNAKE_SOUNDS', false, Config.Sirens.range, false)
                end
                Wait(1800)
            end
        end)
    end
end

local function stopSirens()
    if hasXSound then
        exports.xsound:Destroy(sirenSoundId)
    end
end

-- ============================================================
-- BLIPS zones à risque + points d'évacuation
-- ============================================================

local function createZoneBlips()
    for _, zone in ipairs(Config.FloodZones) do
        local blip = AddBlipForRadius(zone.center.x, zone.center.y, zone.center.z, zone.radius)
        SetBlipColour(blip, 1)
        SetBlipAlpha(blip, 128)
        blips[#blips+1] = blip

        local marker = AddBlipForCoord(zone.center.x, zone.center.y, zone.center.z)
        SetBlipSprite(marker, 51)
        SetBlipColour(marker, 1)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(('Zone à risque: %s'):format(zone.label))
        EndTextCommandSetBlipName(marker)
        blips[#blips+1] = marker
    end

    for _, evac in ipairs(Config.EvacPoints) do
        local blip = AddBlipForCoord(evac.coords.x, evac.coords.y, evac.coords.z)
        SetBlipSprite(blip, 306)
        SetBlipColour(blip, 2)
        SetBlipScale(blip, 1.1)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(('Évacuation: %s'):format(evac.label))
        EndTextCommandSetBlipName(blip)
        blips[#blips+1] = blip
    end
end

local function clearBlips()
    for _, b in ipairs(blips) do
        RemoveBlip(b)
    end
    blips = {}
end

-- ============================================================
-- CHANGEMENT DE PHASE
-- ============================================================

RegisterNetEvent('lsd_flood:phaseChanged', function(phase, duration)
    currentPhase = phase

    if phase == 'alert' then
        ESX.ShowNotification('~r~ALERTE TSUNAMI~s~ : un mur d\'eau a été repéré au large. Évacuez les quartiers bas immédiatement.')
        createZoneBlips()
        playSirens()
        SetWeatherTypeOverTime('THUNDER', 20.0)
    elseif phase == 'rupture' then
        stopSirens()
        ESX.ShowNotification('~r~LA VAGUE TOUCHE LA CÔTE~s~ : fuyez les zones basses immédiatement !')
    elseif phase == 'rising' then
        stopSirens()
        ESX.ShowNotification('~r~LE TSUNAMI FRAPPE~s~ : l\'eau monte. Rejoignez un point d\'évacuation en hauteur.')
    elseif phase == 'peak' then
        -- Pas de notification publique: la décision de la décrue appartient
        -- au staff, les joueurs n'ont pas besoin de le savoir à l'avance.
    elseif phase == 'receding' then
        SetWeatherTypeOverTime('CLEARING', 60.0)
    elseif phase == 'idle' then
        ESX.ShowNotification('La situation est revenue à la normale.')
        clearBlips()
        stopSirens()
    end
end)

-- ============================================================
-- HUD phase / compte à rebours
-- ============================================================

CreateThread(function()
    while true do
        Wait(0)
        if currentPhase ~= 'idle' then
            local label = ({
                alert = 'ALERTE - Évacuation en cours',
                rupture = 'TSUNAMI - IMPACT EN COURS',
                rising = 'CRUE EN COURS - Niveau en hausse',
                peak = 'NIVEAU MAXIMUM ATTEINT',
                receding = 'DÉCRUE EN COURS'
            })[currentPhase] or ''

            SetTextFont(4)
            SetTextProportional(true)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 60, 60, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(2, 0, 0, 0, 150)
            SetTextEntry('STRING')
            AddTextComponentString(label)
            DrawText(0.5, 0.03)
        end
    end
end)

-- ============================================================
-- SURVIE / NOYADE
-- Comparaison manuelle des coordonnées Z (l'eau native ne monte pas
-- réellement), robuste et peu coûteuse en réseau : on rapporte l'état
-- au serveur toutes les Config.Survival.checkInterval ms seulement.
-- ============================================================

local function isInAnyFloodZone(coords)
    for _, zone in ipairs(Config.FloodZones) do
        if #(coords - zone.center) <= zone.radius then
            return true
        end
    end
    return false
end

CreateThread(function()
    while true do
        Wait(Config.Survival.checkInterval)
        if Config.Survival.enabled and (currentPhase == 'rising' or currentPhase == 'peak' or currentPhase == 'receding') then
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) then
                local coords = GetEntityCoords(ped)
                -- L'eau est maintenant la vraie eau du moteur : on peut donc
                -- mesurer la submersion nativement au lieu de comparer des Z.
                local subm = GetEntitySubmergedLevel(ped) or 0.0
                if subm <= 0.0 and coords.z < currentWaterZ and isInAnyFloodZone(coords) then
                    subm = 1.0  -- filet de sécurité si la native ne répond pas
                end
                TriggerServerEvent('lsd_flood:reportSubmersion', subm, coords.z)
            else
                TriggerServerEvent('lsd_flood:reportSubmersion', 0.0, 0.0)
            end
        end
    end
end)

RegisterNetEvent('lsd_flood:drowningWarning', function()
    StartScreenEffect('DeathFailOut', 0, false)
    Wait(600)
    StopScreenEffect('DeathFailOut')
end)

AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() ~= resName then return end
    -- (l eau est restauree par client/water.lua)
    clearBlips()
    stopSirens()
end)
