-- ============================================================
-- MENU CONTEXTUEL — touche ALT
--
-- Détecte ce que le joueur vise (soi-même à courte distance, un
-- autre joueur, un véhicule, ou le sol) et construit un menu adapté.
-- Les actions RP sont visibles par tout le monde ; les actions admin
-- n'apparaissent que si le serveur a confirmé la permission ACE
-- (drapeau reçu une fois à la connexion, jamais décidé côté client).
--
-- HONNÊTETÉ SUR LES ANIMATIONS: la liste ci-dessous n'utilise que des
-- dictionnaires/clips que je suis raisonnablement confiant de voir
-- exister, mais je n'ai pas pu les tester en jeu. Si une anim ne se
-- joue pas, RequestAnimDict échoue silencieusement (pas de crash) —
-- utilisez /animtest <dict> <clip> pour en valider de nouvelles et
-- les ajouter à Config.SelfAnimations.
-- ============================================================

local isAdmin = false
local menuOpen = false
local cuffed = false

TriggerServerEvent('lsd_flood:ctx:requestPermissions')
RegisterNetEvent('lsd_flood:ctx:permissions', function(admin)
    isAdmin = admin
end)

local function openMenu(sections)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'ctxOpen', sections = sections, x = 500, y = 250 })
end

local function closeMenu()
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'ctxClose' })
end

RegisterCommand('lsd_ctxmenu', function()
    if menuOpen then closeMenu() return end

    local ped = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local rad = vector3(math.rad(camRot.x), math.rad(camRot.y), math.rad(camRot.z))
    local dir = vector3(
        -math.sin(rad.z) * math.abs(math.cos(rad.x)),
         math.cos(rad.z) * math.abs(math.cos(rad.x)),
         math.sin(rad.x)
    )
    local dest = camCoords + (dir * 6.0)
    local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, dest.x, dest.y, dest.z, -1, ped, 0)
    local _, hit, hitCoords, _, entity = GetShapeTestResult(ray)

    local sections = {}

    -- --- Toujours disponible : actions sur soi-même ---
    local selfItems = {}
    for _, a in ipairs(Config.SelfAnimations) do
        selfItems[#selfItems+1] = { label = a.label, action = 'self:anim', data = a }
    end
    selfItems[#selfItems+1] = { label = 'Se relever / arrêter l\'animation', action = 'self:clearAnim' }
    selfItems[#selfItems+1] = { label = 'Ranger l\'arme', action = 'self:holster' }
    sections[#sections+1] = { title = 'Moi-même', items = selfItems }

    -- --- Cible : autre joueur ---
    if hit == 1 and entity ~= 0 and DoesEntityExist(entity) and IsEntityAPed(entity) and entity ~= ped then
        local targetPlayer = NetworkGetPlayerIndexFromPed(entity)
        if targetPlayer ~= -1 then
            local serverId = GetPlayerServerId(targetPlayer)
            sections[#sections+1] = {
                title = 'Joueur ciblé',
                items = {
                    { label = cuffed and 'Démenotter' or 'Menotter', action = 'target:cuff', data = serverId },
                    { label = 'Fouiller', action = 'target:search', data = serverId },
                    { label = 'Faire monter dans mon véhicule', action = 'target:putInVehicle', data = serverId },
                    { label = 'Faire descendre du véhicule', action = 'target:removeFromVehicle', data = serverId },
                    { label = 'Réanimer', action = 'target:revive', data = serverId, admin = false },
                    { label = '[Admin] Téléporter à moi', action = 'target:bring', data = serverId, admin = true },
                    { label = '[Admin] Me téléporter à lui', action = 'target:goto', data = serverId, admin = true }
                }
            }
        end
    end

    -- --- Cible : véhicule ---
    local nearVeh = (hit == 1 and entity ~= 0 and IsEntityAVehicle(entity)) and entity
        or GetVehiclePedIsIn(ped, false)
    if nearVeh ~= 0 and DoesEntityExist(nearVeh) then
        local locked = GetVehicleDoorLockStatus(nearVeh) >= 2
        sections[#sections+1] = {
            title = 'Véhicule',
            items = {
                { label = locked and 'Déverrouiller' or 'Verrouiller', action = 'veh:lock', data = { veh = NetworkGetNetworkIdFromEntity(nearVeh), state = not locked } },
                { label = 'Capot', action = 'veh:hood', data = NetworkGetNetworkIdFromEntity(nearVeh) },
                { label = 'Coffre', action = 'veh:trunk', data = NetworkGetNetworkIdFromEntity(nearVeh) },
                { label = 'Moteur on/off', action = 'veh:engine', data = NetworkGetNetworkIdFromEntity(nearVeh) },
                { label = 'Nettoyer', action = 'veh:clean', data = NetworkGetNetworkIdFromEntity(nearVeh) },
                { label = 'Klaxonner', action = 'veh:horn', data = NetworkGetNetworkIdFromEntity(nearVeh) },
                { label = '[Admin] Réparer', action = 'veh:repair', data = NetworkGetNetworkIdFromEntity(nearVeh), admin = true },
                { label = '[Admin] Faire exploser', action = 'veh:explode', data = NetworkGetNetworkIdFromEntity(nearVeh), admin = true }
            }
        }
    end

    -- --- Sol / Admin ---
    if isAdmin then
        local groundItems = {
            { label = 'Me téléporter ici', action = 'admin:tpHere', data = hit == 1 and hitCoords or nil, admin = true },
            { label = 'Geler cette zone (30m, 20s)', action = 'admin:freezeZone', data = hit == 1 and hitCoords or nil, admin = true },
            { label = 'Debug collision / matériau ici', action = 'admin:debugPoint', data = hit == 1 and hitCoords or nil, admin = true },
            { label = 'Noclip (bascule)', action = 'admin:noclip', admin = true }
        }
        sections[#sections+1] = { title = 'Sol / Admin', items = groundItems }
    end

    openMenu(sections)
end, false)

RegisterKeyMapping('lsd_ctxmenu', 'Ouvrir le menu contextuel Land Act', 'keyboard', 'LMENU')

RegisterNUICallback('ctxAction', function(body, cb)
    local action, data = body.action, body.data
    if action == 'close' then
        closeMenu()
        cb('ok')
        return
    end

    local ped = PlayerPedId()

    if action == 'self:anim' then
        local dict, clip = data.dict, data.clip
        RequestAnimDict(dict)
        local timeout = GetGameTimer() + 2000
        while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
        if HasAnimDictLoaded(dict) then
            TaskPlayAnim(ped, dict, clip, 3.0, 3.0, -1, data.flag or 1, 0, false, false, false)
        end

    elseif action == 'self:clearAnim' then
        ClearPedTasks(ped)

    elseif action == 'self:holster' then
        SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)

    elseif action == 'admin:noclip' then
        TriggerEvent('lsd_flood:ctx:toggleNoclip')

    elseif action == 'admin:debugPoint' and data then
        DrawMarker(28, data.x, data.y, data.z, 0,0,0, 0,0,0, 1.0,1.0,1.0, 255,80,80,180, false, false, 2, false, nil, nil, false)
        local ray = StartShapeTestRay(data.x, data.y, data.z + 2.0, data.x, data.y, data.z - 2.0, -1, ped, 0)
        local _, hit2, endCoords, _, matHash = GetShapeTestResultIncludingMaterial(ray)
        print(('[debug] Point: %.2f, %.2f, %.2f  |  materiau hash: %s'):format(data.x, data.y, data.z, tostring(matHash)))
        ESX.ShowNotification(('Debug: %.1f, %.1f, %.1f — matériau %s'):format(data.x, data.y, data.z, tostring(matHash)))

    else
        -- tout le reste (cible joueur, véhicule, admin serveur) passe par le serveur
        TriggerServerEvent('lsd_flood:ctxAction', action, data)
    end

    cb('ok')
end)

local cuffProp = nil

local function applyCuffed(state)
    cuffed = state
    local ped = PlayerPedId()

    if cuffProp and DoesEntityExist(cuffProp) then
        DeleteEntity(cuffProp)
        cuffProp = nil
    end

    if state then
        local hash = GetHashKey('prop_cs_cuffs_01')
        RequestModel(hash)
        local timeout = GetGameTimer() + 2000
        while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
        if HasModelLoaded(hash) then
            cuffProp = CreateObject(hash, 0.0, 0.0, 0.0, true, true, false)
            AttachEntityToEntity(cuffProp, ped, GetPedBoneIndex(ped, 60309),
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            SetModelAsNoLongerNeeded(hash)
        end
        CreateThread(function()
            while cuffed do
                DisablePlayerFiring(PlayerId(), true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 47, true)  -- weapon wheel
                Wait(0)
            end
        end)
    end
end

RegisterNetEvent('lsd_flood:ctx:setCuffed', function(state)
    applyCuffed(state)
end)

RegisterNetEvent('lsd_flood:ctx:requestCuffState', function(fromSrc)
    applyCuffed(not cuffed)
end)

RegisterNetEvent('lsd_flood:ctx:enterVehicle', function(vehNetId)
    local veh = NetworkGetEntityFromNetworkId(vehNetId)
    if veh and veh ~= 0 then
        TaskEnterVehicle(PlayerPedId(), veh, 8000, -1, 1.0, 1, 0)
    end
end)

RegisterNetEvent('lsd_flood:ctx:leaveVehicle', function()
    TaskLeaveVehicle(PlayerPedId(), GetVehiclePedIsIn(PlayerPedId(), false), 0)
end)

RegisterNetEvent('lsd_flood:ctx:revive', function()
    local ped = PlayerPedId()
    NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityHeading(ped), true, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
end)

RegisterNetEvent('lsd_flood:ctx:teleportTo', function(x, y, z)
    SetEntityCoords(PlayerPedId(), x, y, z, false, false, false, false)
end)

RegisterNetEvent('lsd_flood:ctx:freezeZone', function(x, y, z, radius, durationMs)
    local ped = PlayerPedId()
    local d = #(GetEntityCoords(ped) - vector3(x, y, z))
    if d > radius then return end
    FreezeEntityPosition(ped, true)
    ESX.ShowNotification('Vous êtes gelé(e) temporairement (zone administrative).')
    SetTimeout(durationMs, function()
        FreezeEntityPosition(ped, false)
    end)
end)

-- --- Actions véhicule (répliquées à tous les clients à portée) ---

local function nearbyVeh(netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return nil end
    return veh
end

RegisterNetEvent('lsd_flood:ctx:vehLock', function(netId, state)
    local veh = nearbyVeh(netId)
    if veh then SetVehicleDoorsLocked(veh, state and 2 or 1) end
end)

RegisterNetEvent('lsd_flood:ctx:vehDoor', function(netId, doorIndex)
    local veh = nearbyVeh(netId)
    if not veh then return end
    if GetVehicleDoorAngleRatio(veh, doorIndex) > 0.0 then
        SetVehicleDoorShut(veh, doorIndex, false)
    else
        SetVehicleDoorOpen(veh, doorIndex, false, false)
    end
end)

RegisterNetEvent('lsd_flood:ctx:vehEngine', function(netId)
    local veh = nearbyVeh(netId)
    if veh then SetVehicleEngineOn(veh, not GetIsVehicleEngineRunning(veh), true, false) end
end)

RegisterNetEvent('lsd_flood:ctx:vehClean', function(netId)
    local veh = nearbyVeh(netId)
    if veh then SetVehicleDirtLevel(veh, 0.0) end
end)

RegisterNetEvent('lsd_flood:ctx:vehHorn', function(netId)
    local veh = nearbyVeh(netId)
    if veh then StartVehicleHorn(veh, 800, GetHashKey('HELDDOWN'), false) end
end)

RegisterNetEvent('lsd_flood:ctx:vehRepair', function(netId)
    local veh = nearbyVeh(netId)
    if veh then SetVehicleFixed(veh) SetVehicleDirtLevel(veh, 0.0) end
end)

RegisterNetEvent('lsd_flood:ctx:vehExplode', function(netId)
    local veh = nearbyVeh(netId)
    if veh then NetworkExplodeVehicle(veh, true, false, false) end
end)

-- --- Noclip admin, basique ---
local noclipOn = false
RegisterNetEvent('lsd_flood:ctx:toggleNoclip', function()
    noclipOn = not noclipOn
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, noclipOn)
    SetEntityCollision(ped, not noclipOn, not noclipOn)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, noclipOn)
end)

CreateThread(function()
    while true do
        Wait(0)
        if noclipOn then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local speed = IsControlPressed(0, 21) and 0.8 or 0.3
            local fwd, right = 0.0, 0.0
            if IsControlPressed(0, 32) then fwd = 1.0 end
            if IsControlPressed(0, 33) then fwd = -1.0 end
            if IsControlPressed(0, 34) then right = -1.0 end
            if IsControlPressed(0, 35) then right = 1.0 end
            local up = 0.0
            if IsControlPressed(0, 44) then up = 1.0 end   -- Q
            if IsControlPressed(0, 20) then up = -1.0 end  -- C
            local heading = math.rad(GetEntityHeading(ped))
            local dx = (math.cos(heading) * right + math.sin(heading) * fwd) * speed
            local dy = (-math.sin(heading) * right + math.cos(heading) * fwd) * speed
            SetEntityCoordsNoOffset(ped, coords.x + dx, coords.y + dy, coords.z + up * speed, true, true, true)
        end
    end
end)

if Config.DevCommands then
    RegisterCommand('animtest', function(_, args)
        local dict, clip = args[1], args[2]
        if not dict or not clip then
            print('[animtest] Usage: /animtest <dict> <clip>')
            return
        end
        RequestAnimDict(dict)
        local timeout = GetGameTimer() + 3000
        while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
        if HasAnimDictLoaded(dict) then
            TaskPlayAnim(PlayerPedId(), dict, clip, 3.0, 3.0, -1, 1, 0, false, false, false)
            print('[animtest] OK: ' .. dict .. ' / ' .. clip)
        else
            print('[animtest] ECHEC (dict introuvable): ' .. dict)
        end
    end, false)
end
