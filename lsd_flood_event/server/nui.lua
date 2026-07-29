-- ============================================================
-- SERVEUR — validation des permissions et exécution des actions du
-- panel admin. Chaque action est revérifiée ici : le client ne peut
-- rien déclencher sans passer par ce filtre ACE.
-- ============================================================

ESX = ESX or exports['es_extended']:getSharedObject()

local function isAllowed(src)
    return src == 0 or IsPlayerAceAllowed(src, Config.AdminAce)
end

RegisterNetEvent('lsd_flood:requestPanelAccess', function()
    local src = source
    if not isAllowed(src) then
        TriggerClientEvent('ESX:Notify', src, { type = 'error', message = 'Accès refusé au panel.' })
        return
    end
    TriggerClientEvent('lsd_flood:panelAccessGranted', src)
end)

-- Vérifie qu'un nom de modèle/arme proposé par le client existe bien dans
-- le catalogue du config, pour ne jamais exécuter un hash arbitraire.
local function isInCatalog(catalog, value)
    for _, list in pairs(catalog) do
        for _, item in ipairs(list) do
            if item == value then return true end
        end
    end
    return false
end

RegisterNetEvent('lsd_flood:nuiAction', function(action, data)
    local src = source
    if not isAllowed(src) then return end

    local ped = GetPlayerPed(src)

    if action == 'startFlood' then
        exports[GetCurrentResourceName()]:StartFlood()

    elseif action == 'stopFlood' then
        exports[GetCurrentResourceName()]:StopFlood()

    elseif action == 'forcePhase' then
        local valid = { alert=1, rupture=1, rising=1, peak=1, receding=1, idle=1 }
        if valid[data] then
            exports[GetCurrentResourceName()]:ForcePhase(data)
        end

    elseif action == 'setWaterLevel' then
        local lvl = tonumber(data)
        if lvl then exports[GetCurrentResourceName()]:SetWaterLevel(lvl) end

    elseif action == 'setDurations' then
        if type(data) == 'table' then
            exports[GetCurrentResourceName()]:SetDurations(data)
        end

    elseif action == 'setWeather' then
        if type(data) == 'string' then
            TriggerClientEvent('lsd_flood:nui:setWeather', -1, data)
        end

    elseif action == 'setTime' then
        if type(data) == 'table' and data.h then
            TriggerClientEvent('lsd_flood:nui:setTime', -1, data.h, data.m or 0)
        end

    elseif action == 'freezeTime' then
        TriggerClientEvent('lsd_flood:nui:freezeTime', -1, data == true)

    elseif action == 'setBlackoutEnabled' then
        TriggerClientEvent('lsd_flood:nui:blackoutEnabled', -1, data == true)

    elseif action == 'setBlackoutBoundary' then
        local y = tonumber(data)
        if y then TriggerClientEvent('lsd_flood:nui:blackoutBoundary', -1, y) end

    elseif action == 'spawnVehicle' then
        if type(data) == 'string' and isInCatalog(Config.VehicleCatalog, data) then
            TriggerClientEvent('lsd_flood:nui:spawnVehicle', src, data)
        end

    elseif action == 'giveWeapon' then
        if type(data) == 'string' and isInCatalog(Config.WeaponCatalog, data) then
            TriggerClientEvent('lsd_flood:nui:giveWeapon', src, data)
        end

    elseif action == 'giveAllWeapons' then
        TriggerClientEvent('lsd_flood:nui:giveAllWeapons', src)

    elseif action == 'removeAllWeapons' then
        TriggerClientEvent('lsd_flood:nui:removeAllWeapons', src)

    elseif action == 'maxAmmo' then
        TriggerClientEvent('lsd_flood:nui:maxAmmo', src)

    elseif action == 'revive' then
        if ped and ped ~= 0 then
            TriggerClientEvent('lsd_flood:nui:revive', src)
        end
    end
end)
