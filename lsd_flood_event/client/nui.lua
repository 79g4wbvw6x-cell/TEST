-- ============================================================
-- PANEL ADMIN — ouverture NUI, transmission des actions au serveur.
-- Toute vérification de permission se fait côté serveur (server/nui.lua) :
-- ce fichier ne fait qu'ouvrir l'UI et relayer les clics, jamais confiance
-- aveugle au client.
-- ============================================================

local panelOpen = false
local godmode = false
local invisible = false
local frozen = false

RegisterCommand(Config.AdminPanel and Config.AdminPanel.command or 'floodpanel', function()
    if panelOpen then return end
    TriggerServerEvent('lsd_flood:requestPanelAccess')
end, false)

RegisterKeyMapping(
    Config.AdminPanel and Config.AdminPanel.command or 'floodpanel',
    'Ouvrir le panel Land Act',
    'keyboard',
    Config.AdminPanel and Config.AdminPanel.key or 'F6'
)

RegisterNetEvent('lsd_flood:panelAccessGranted', function()
    panelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type        = 'open',
        vehicles    = Config.VehicleCatalog,
        weapons     = Config.WeaponCatalog,
        evacPoints  = (function()
            local out = {}
            for _, p in ipairs(Config.EvacPoints) do
                out[#out+1] = { label = p.label, x = p.coords.x, y = p.coords.y, z = p.coords.z }
            end
            return out
        end)(),
        floodZones  = (function()
            local out = {}
            for _, z in ipairs(Config.FloodZones) do
                out[#out+1] = { label = z.label, x = z.center.x, y = z.center.y, z = z.center.z + 5.0 }
            end
            return out
        end)()
    })
end)

RegisterNUICallback('nuiAction', function(body, cb)
    local action, data = body.action, body.data

    if action == 'close' then
        panelOpen = false
        SetNuiFocus(false, false)

    elseif action == 'teleportCoords' then
        local ped = PlayerPedId()
        SetEntityCoords(ped, data.x, data.y, data.z, false, false, false, false)

    elseif action == 'teleportDam' then
        local ped = PlayerPedId()
        local d = Config.Dam.coords
        SetEntityCoords(ped, d.x, d.y, d.z + 5.0, false, false, false, false)

    elseif action == 'toggleGodmode' then
        godmode = not godmode
        SetEntityInvincible(PlayerPedId(), godmode)

    elseif action == 'toggleInvisible' then
        invisible = not invisible
        SetEntityVisible(PlayerPedId(), not invisible, false)

    elseif action == 'toggleFreeze' then
        frozen = not frozen
        FreezeEntityPosition(PlayerPedId(), frozen)

    elseif action == 'heal' then
        local ped = PlayerPedId()
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        SetPedArmour(ped, 100)

    elseif action == 'kill' then
        SetEntityHealth(PlayerPedId(), 0)

    else
        -- Toutes les actions à effet serveur (spawn véhicule, armes, event,
        -- météo, blackout, revive) sont revalidées côté serveur avant exécution.
        TriggerServerEvent('lsd_flood:nuiAction', action, data)
    end

    cb('ok')
end)

-- ============================================================
-- Actions revalidées et rediffusées par le serveur (server/nui.lua)
-- ============================================================

RegisterNetEvent('lsd_flood:nui:setWeather', function(name)
    SetWeatherTypeNow(name)
    SetWeatherTypePersist(name)
end)

RegisterNetEvent('lsd_flood:nui:setTime', function(h, m)
    NetworkOverrideClockTime(h, m, 0)
end)

RegisterNetEvent('lsd_flood:nui:freezeTime', function(state)
    PauseClock(state)
end)

RegisterNetEvent('lsd_flood:nui:blackoutEnabled', function(state)
    if Config.Spectacle and Config.Spectacle.blackout then
        Config.Spectacle.blackout.enabled = state
    end
end)

RegisterNetEvent('lsd_flood:nui:blackoutBoundary', function(y)
    if Config.Spectacle and Config.Spectacle.blackout then
        Config.Spectacle.blackout.boundaryY = y
    end
end)

RegisterNetEvent('lsd_flood:nui:spawnVehicle', function(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 4000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(hash) then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnPos = coords + forward * 5.0

    local veh = CreateVehicle(hash, spawnPos.x, spawnPos.y, spawnPos.z + 1.0, GetEntityHeading(ped), true, false)
    SetPedIntoVehicle(ped, veh, -1)
    SetVehicleFuelLevel(veh, 100.0)
    SetModelAsNoLongerNeeded(hash)
end)

RegisterNetEvent('lsd_flood:nui:giveWeapon', function(weapon)
    GiveWeaponToPed(PlayerPedId(), GetHashKey(weapon), 250, false, true)
end)

RegisterNetEvent('lsd_flood:nui:giveAllWeapons', function()
    for _, list in pairs(Config.WeaponCatalog) do
        for _, w in ipairs(list) do
            GiveWeaponToPed(PlayerPedId(), GetHashKey(w), 250, false, false)
        end
    end
end)

RegisterNetEvent('lsd_flood:nui:removeAllWeapons', function()
    RemoveAllPedWeapons(PlayerPedId(), true)
end)

RegisterNetEvent('lsd_flood:nui:maxAmmo', function()
    local ped = PlayerPedId()
    for _, list in pairs(Config.WeaponCatalog) do
        for _, w in ipairs(list) do
            local hash = GetHashKey(w)
            if HasPedGotWeapon(ped, hash, false) then
                SetPedAmmo(ped, hash, 9999)
            end
        end
    end
end)

RegisterNetEvent('lsd_flood:nui:revive', function()
    local ped = PlayerPedId()
    NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityHeading(ped), true, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
end)

-- Diffusion périodique de l'état pour le bandeau du panel
CreateThread(function()
    while true do
        Wait(1000)
        if panelOpen then
            SendNUIMessage({
                type  = 'state',
                phase = GlobalState.lsd_floodPhase or 'idle',
                level = GlobalState.lsd_waterLevel or 0.0
            })
        end
    end
end)
