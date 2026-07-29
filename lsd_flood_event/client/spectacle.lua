-- ============================================================
-- MISE EN SCÈNE DE LA CATASTROPHE
--
-- Tout ce qui transforme une montée d'eau en événement mémorable :
-- coupure de courant, ciel d'apocalypse, foudre, panique des PNJ,
-- débris à la dérive, hélicoptères de secours, alertes radio.
--
-- Chaque effet est indépendant et désactivable dans Config.Spectacle.
-- Tout est piloté par la phase courante lue dans GlobalState, donc
-- rien à synchroniser en réseau : chaque client joue sa propre mise
-- en scène au bon moment.
-- ============================================================

local S = Config.Spectacle
local phase = 'idle'
local spawnedEntities = {}
local blackoutOn = false

local function track(ent)
    if ent and ent ~= 0 then spawnedEntities[#spawnedEntities + 1] = ent end
end

local function cleanupEntities()
    for _, e in ipairs(spawnedEntities) do
        if DoesEntityExist(e) then DeleteEntity(e) end
    end
    spawnedEntities = {}
end

local function loadModel(hash)
    RequestModel(hash)
    local timeout = GetGameTimer() + 4000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
    return HasModelLoaded(hash)
end

-- ============================================================
-- 1. BLACKOUT — Sud (ville) clignote à l'infini, Nord (comté) épargné.
-- Basé sur la position du joueur local: chaque client décide pour
-- lui-même, ce qui est correct puisque SetArtificialLightsState est
-- un interrupteur global côté client (pas de version par zone dans
-- le moteur).
-- ============================================================

local blackoutFlickerActive = false

local function setLights(state)
    if blackoutOn == state then return end
    SetArtificialLightsState(state)
    if type(SetArtificialLightsStateAffectsVehicles) == 'function' then
        SetArtificialLightsStateAffectsVehicles(not state)
    end
    blackoutOn = state
end

local function isInSouth()
    local coords = GetEntityCoords(PlayerPedId())
    return coords.y < S.blackout.boundaryY
end

-- Boucle de clignotement: tourne en continu tant que l'event est actif.
-- Ne coupe les lumières que si le joueur est au Sud à cet instant précis;
-- redevient transparente (lumières normales) dès qu'il passe au Nord.
CreateThread(function()
    while true do
        if S.blackout.enabled and phase ~= 'idle' and isInSouth() then
            blackoutFlickerActive = true
            setLights(true)
            Wait(math.random(S.blackout.flickerOffMin, S.blackout.flickerOffMax))
            if phase ~= 'idle' and isInSouth() then
                setLights(false)
                Wait(math.random(S.blackout.flickerOnMin, S.blackout.flickerOnMax))
            end
        else
            if blackoutFlickerActive then
                setLights(false)
                blackoutFlickerActive = false
            end
            Wait(500)
        end
    end
end)

-- ============================================================
-- 2. CIEL D'APOCALYPSE — timecycle + foudre
-- ============================================================

local function applyTimecycle(name, strength)
    if not S.timecycle.enabled then return end
    if name then
        SetTimecycleModifier(name)
        SetTimecycleModifierStrength(strength or 1.0)
    else
        ClearTimecycleModifier()
    end
end

CreateThread(function()
    while true do
        if S.lightning.enabled and (phase == 'rupture' or phase == 'rising' or phase == 'peak') then
            Wait(math.random(S.lightning.minDelay, S.lightning.maxDelay))
            if type(ForceLightningFlash) == 'function' then ForceLightningFlash() end
        else
            Wait(3000)
        end
    end
end)

-- ============================================================
-- 3. PANIQUE DES PNJ — ils fuient vers les hauteurs
-- ============================================================

local panicked = {}

CreateThread(function()
    while true do
        Wait(S.panic.interval)
        if S.panic.enabled and phase ~= 'idle' and phase ~= 'receding' then
            local me = PlayerPedId()
            local myCoords = GetEntityCoords(me)
            local handle, ped = FindFirstPed()
            local ok = true
            local count = 0

            repeat
                if ped ~= me and not IsPedAPlayer(ped) and DoesEntityExist(ped)
                   and not IsPedDeadOrDying(ped) and not panicked[ped] then
                    local d = #(GetEntityCoords(ped) - myCoords)
                    if d < S.panic.radius then
                        SetPedFleeAttributes(ped, 0, false)
                        SetPedPanicExitScenario(ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                        ClearPedTasksImmediately(ped)
                        -- fuite loin du barrage / de la montée d'eau
                        TaskSmartFleeCoord(ped, Config.Dam.coords.x, Config.Dam.coords.y,
                                           Config.Dam.coords.z, 500.0, -1, false, false)
                        SetPedKeepTask(ped, true)
                        panicked[ped] = true
                        count = count + 1
                    end
                end
                ok, ped = FindNextPed(handle)
            until not ok or count >= S.panic.maxPerTick

            EndFindPed(handle)
        else
            panicked = {}
        end
    end
end)

-- ============================================================
-- 4. DÉBRIS À LA DÉRIVE — ce que la crue emporte
-- ============================================================

CreateThread(function()
    while true do
        Wait(S.debris.interval)
        if S.debris.enabled and (phase == 'rising' or phase == 'peak') then
            local level = GlobalState.lsd_waterLevel or 0.0
            local me = GetEntityCoords(PlayerPedId())

            -- On ne fait apparaître des débris que si le joueur est
            -- effectivement au-dessus d'une zone inondée
            if me.z < level + S.debris.maxHeightAboveWater then
                for _ = 1, S.debris.perWave do
                    if #spawnedEntities >= S.debris.maxAlive then break end
                    local model = GetHashKey(S.debris.models[math.random(#S.debris.models)])
                    if loadModel(model) then
                        local ang = math.random() * math.pi * 2
                        local dist = S.debris.minDist + math.random() * (S.debris.maxDist - S.debris.minDist)
                        local x = me.x + math.cos(ang) * dist
                        local y = me.y + math.sin(ang) * dist
                        local obj = CreateObject(model, x, y, level + 0.3, false, false, false)
                        if obj and obj ~= 0 then
                            SetEntityDynamic(obj, true)
                            SetEntityLodDist(obj, 300)
                            ApplyForceToEntity(obj, 1,
                                S.debris.driftX, S.debris.driftY, 0.0,
                                0.0, 0.0, 0.0, 0, true, true, true, false, true)
                            track(obj)
                        end
                        SetModelAsNoLongerNeeded(model)
                    end
                end
            end
        elseif phase == 'idle' and #spawnedEntities > 0 then
            cleanupEntities()
        end
    end
end)

-- ============================================================
-- 5. HÉLICOPTÈRES DE SECOURS — survols avec projecteur
-- ============================================================

local function spawnRescueHeli()
    if not S.helicopters.enabled then return end
    local model = GetHashKey(S.helicopters.model)
    if not loadModel(model) then return end

    local me = GetEntityCoords(PlayerPedId())
    local ang = math.random() * math.pi * 2
    local x = me.x + math.cos(ang) * S.helicopters.spawnDist
    local y = me.y + math.sin(ang) * S.helicopters.spawnDist
    local z = (GlobalState.lsd_waterLevel or 0.0) + S.helicopters.altitude

    local heli = CreateVehicle(model, x, y, z, 0.0, false, false)
    if heli and heli ~= 0 then
        SetHeliBladesFullSpeed(heli)
        SetVehicleEngineOn(heli, true, true, false)
        SetVehicleSearchlight(heli, true, true)
        SetEntityLodDist(heli, 500)
        track(heli)

        -- pilote PNJ qui patrouille au-dessus de la zone
        local pilotModel = GetHashKey(S.helicopters.pilotModel)
        if loadModel(pilotModel) then
            local pilot = CreatePedInsideVehicle(heli, 26, pilotModel, -1, false, false)
            if pilot and pilot ~= 0 then
                SetBlockingOfNonTemporaryEvents(pilot, true)
                TaskHeliMission(pilot, heli, 0, 0, me.x, me.y, z,
                                4, 30.0, 10.0, -1.0, 40, 40, -1.0, 0)
                track(pilot)
            end
            SetModelAsNoLongerNeeded(pilotModel)
        end
    end
    SetModelAsNoLongerNeeded(model)
end

CreateThread(function()
    while true do
        Wait(S.helicopters.interval)
        if S.helicopters.enabled and (phase == 'rising' or phase == 'peak' or phase == 'receding') then
            local n = 0
            for _, e in ipairs(spawnedEntities) do
                if DoesEntityExist(e) and IsEntityAVehicle(e) then n = n + 1 end
            end
            if n < S.helicopters.maxAlive then spawnRescueHeli() end
        end
    end
end)

-- ============================================================
-- 6. ALERTES RADIO — messages égrenés pendant l'event
-- ============================================================

local function broadcast(messages, interval)
    CreateThread(function()
        local startPhase = phase
        for _, msg in ipairs(messages) do
            if phase ~= startPhase then return end
            ESX.ShowNotification(msg)
            if type(PlaySoundFrontend) == 'function' then
                PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
            end
            Wait(interval)
        end
    end)
end

-- ============================================================
-- 7. SECOUSSE CONTINUE + EFFET ÉCRAN sous l'eau
-- ============================================================

CreateThread(function()
    while true do
        Wait(500)
        if phase == 'rising' or phase == 'peak' then
            local ped = PlayerPedId()
            local subm = GetEntitySubmergedLevel(ped) or 0.0
            if subm > 0.7 then
                if not S._underwaterFx then
                    StartScreenEffect('CamPushInNeutral', 0, true)
                    S._underwaterFx = true
                end
            elseif S._underwaterFx then
                StopScreenEffect('CamPushInNeutral')
                S._underwaterFx = false
            end
        elseif S._underwaterFx then
            StopScreenEffect('CamPushInNeutral')
            S._underwaterFx = false
        end
    end
end)

-- ============================================================
-- ORCHESTRATION PAR PHASE
-- ============================================================

RegisterNetEvent('lsd_flood:phaseChanged', function(newPhase)
    phase = newPhase

    if newPhase == 'alert' then
        applyTimecycle(S.timecycle.alert, 0.6)
        broadcast(S.messages.alert, 12000)

    elseif newPhase == 'rupture' then
        applyTimecycle(S.timecycle.disaster, 1.0)
        broadcast(S.messages.rupture, 8000)

    elseif newPhase == 'rising' then
        applyTimecycle(S.timecycle.disaster, 1.0)
        broadcast(S.messages.rising, 25000)

    elseif newPhase == 'peak' then
        broadcast(S.messages.peak, 20000)

    elseif newPhase == 'receding' then
        applyTimecycle(S.timecycle.recovery, 0.7)
        broadcast(S.messages.receding, 20000)

    elseif newPhase == 'idle' then
        applyTimecycle(nil)
        cleanupEntities()
        panicked = {}
    end
end)

-- Resynchro pour un joueur qui arrive en cours d'event
-- (le blackout se réapplique de lui-même via la boucle CreateThread,
-- qui lit `phase` en continu — rien à faire ici pour lui)
RegisterNetEvent('lsd_flood:syncState', function(p)
    phase = p or 'idle'
    if phase == 'rupture' or phase == 'rising' or phase == 'peak' then
        applyTimecycle(S.timecycle.disaster, 1.0)
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() ~= resName then return end
    setLights(false)
    ClearTimecycleModifier()
    cleanupEntities()
    if S._underwaterFx then StopScreenEffect('CamPushInNeutral') end
end)
