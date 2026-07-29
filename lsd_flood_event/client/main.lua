ESX = exports['es_extended']:getSharedObject()

local currentPhase = 'idle'
local waterProp = nil
local waterPropCurrentZ = Config.WaterLevel.base
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
    waterPropCurrentZ = waterLevel
end)

-- ============================================================
-- OBJET D'EAU (placeholder). Remplacez Config.WaterProp par votre
-- asset custom (ymap/prop shader eau) pour un rendu premium.
-- La montée réelle n'est PAS gérée par la heightmap eau native du
-- jeu (non modifiable en temps réel côté client), donc on simule
-- visuellement la crue avec un plan translucide qui suit
-- GlobalState.lsd_waterLevel, pendant que la logique de noyade est
-- calculée en pur script (comparaison de coordonnées Z).
-- ============================================================

Config.WaterProp = Config.WaterProp or { model = 'prop_worldwater_lod', sizeXY = 6000.0 }

local function ensureWaterProp()
    if waterProp and DoesEntityExist(waterProp) then return end
    local hash = GetHashKey(Config.WaterProp.model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end
    if not HasModelLoaded(hash) then return end

    waterProp = CreateObject(hash, Config.Dam.coords.x, Config.Dam.coords.y, Config.WaterLevel.base, false, false, false)
    SetEntityAlpha(waterProp, 160, false)
    SetEntityCollision(waterProp, false, false)
    FreezeEntityPosition(waterProp, true)
    SetModelAsNoLongerNeeded(hash)
end

local function destroyWaterProp()
    if waterProp and DoesEntityExist(waterProp) then
        DeleteEntity(waterProp)
    end
    waterProp = nil
end

CreateThread(function()
    while true do
        Wait(250)
        if currentPhase == 'rising' or currentPhase == 'peak' or currentPhase == 'receding' then
            ensureWaterProp()
            if waterProp and DoesEntityExist(waterProp) then
                local x, y, _ = table.unpack(GetEntityCoords(waterProp))
                SetEntityCoords(waterProp, x, y, waterPropCurrentZ, false, false, false, false)
            end
        elseif currentPhase == 'idle' then
            destroyWaterProp()
        end
    end
end)

-- ============================================================
-- SIRÈNES / ALERTE
-- ============================================================

local function playSirens()
    if hasXSound then
        exports.xsound:PlayUrlPos(sirenSoundId, Config.Sirens.url or 'https://your-cdn.example/siren_loop.ogg', 0.6, Config.Dam.coords, true)
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
        ESX.ShowNotification('~r~ALERTE CRUE~s~ : le barrage de Land Act menace de céder. Évacuez les quartiers bas immédiatement.')
        createZoneBlips()
        playSirens()
        SetWeatherTypeOverTime('THUNDER', 20.0)
    elseif phase == 'rising' then
        stopSirens()
        ESX.ShowNotification('~r~RUPTURE DU BARRAGE~s~ : l\'eau monte. Rejoignez un point d\'évacuation en hauteur.')
    elseif phase == 'peak' then
        ESX.ShowNotification('Le niveau de l\'eau s\'est stabilisé. Restez en hauteur.')
    elseif phase == 'receding' then
        ESX.ShowNotification('La décrue commence. Les secours interviennent dans les quartiers touchés.')
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
                local submerged = coords.z < waterPropCurrentZ and isInAnyFloodZone(coords)
                TriggerServerEvent('lsd_flood:reportSubmersion', submerged and 1.0 or 0.0, coords.z)
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
    destroyWaterProp()
    clearBlips()
    stopSirens()
end)
