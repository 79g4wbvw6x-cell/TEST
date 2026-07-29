-- ============================================================
-- SERVEUR — permissions et relais des actions du menu contextuel.
-- Toute action touchant un AUTRE joueur ou un véhicule passe par ici :
-- le client ne peut jamais agir directement sur une entité qui n'est
-- pas la sienne.
-- ============================================================

local function isAllowed(src)
    return src == 0 or IsPlayerAceAllowed(src, Config.AdminAce)
end

RegisterNetEvent('lsd_flood:ctx:requestPermissions', function()
    local src = source
    TriggerClientEvent('lsd_flood:ctx:permissions', src, isAllowed(src))
end)

RegisterNetEvent('lsd_flood:ctxAction', function(action, data)
    local src = source
    local adminActions = {
        ['target:bring'] = 1, ['target:goto'] = 1,
        ['veh:repair'] = 1, ['veh:explode'] = 1,
        ['admin:tpHere'] = 1, ['admin:freezeZone'] = 1
    }
    if adminActions[action] and not isAllowed(src) then return end

    if action == 'target:cuff' then
        TriggerClientEvent('lsd_flood:ctx:requestCuffState', data, src)

    elseif action == 'target:search' then
        TriggerClientEvent('ESX:Notify', data, { message = 'Vous êtes fouillé(e).' })
        TriggerClientEvent('ESX:Notify', src, { message = 'Fouille effectuée.' })

    elseif action == 'target:putInVehicle' then
        local veh = GetVehiclePedIsIn(GetPlayerPed(src), false)
        if veh ~= 0 then
            TriggerClientEvent('lsd_flood:ctx:enterVehicle', data, NetworkGetNetworkIdFromEntity(veh))
        end

    elseif action == 'target:removeFromVehicle' then
        TriggerClientEvent('lsd_flood:ctx:leaveVehicle', data)

    elseif action == 'target:revive' then
        TriggerClientEvent('lsd_flood:ctx:revive', data)

    elseif action == 'target:bring' then
        local srcCoords = GetEntityCoords(GetPlayerPed(src))
        TriggerClientEvent('lsd_flood:ctx:teleportTo', data, srcCoords.x, srcCoords.y, srcCoords.z)

    elseif action == 'target:goto' then
        local tgtCoords = GetEntityCoords(GetPlayerPed(data))
        TriggerClientEvent('lsd_flood:ctx:teleportTo', src, tgtCoords.x, tgtCoords.y, tgtCoords.z)

    elseif action == 'veh:lock' then
        TriggerClientEvent('lsd_flood:ctx:vehLock', -1, data.veh, data.state)

    elseif action == 'veh:hood' then
        TriggerClientEvent('lsd_flood:ctx:vehDoor', -1, data, 4)

    elseif action == 'veh:trunk' then
        TriggerClientEvent('lsd_flood:ctx:vehDoor', -1, data, 5)

    elseif action == 'veh:engine' then
        TriggerClientEvent('lsd_flood:ctx:vehEngine', -1, data)

    elseif action == 'veh:clean' then
        TriggerClientEvent('lsd_flood:ctx:vehClean', -1, data)

    elseif action == 'veh:horn' then
        TriggerClientEvent('lsd_flood:ctx:vehHorn', -1, data)

    elseif action == 'veh:repair' then
        TriggerClientEvent('lsd_flood:ctx:vehRepair', -1, data)

    elseif action == 'veh:explode' then
        TriggerClientEvent('lsd_flood:ctx:vehExplode', -1, data)

    elseif action == 'admin:tpHere' and data then
        TriggerClientEvent('lsd_flood:ctx:teleportTo', src, data.x, data.y, data.z)

    elseif action == 'admin:freezeZone' and data then
        TriggerClientEvent('lsd_flood:ctx:freezeZone', -1, data.x, data.y, data.z, 30.0, 20000)
    end
end)
