ESX = exports['es_extended']:getSharedObject()

local running = false
local pendingReceding = false  -- ne redevient true que par décision du staff
local submersionState = {} -- [source] = { since = os.time() or false }

-- Notifie uniquement les joueurs ayant la permission admin (jamais les
-- joueurs normaux) — utilisé pour tenir le staff informé du statut de
-- l'event (ex: "niveau stable, en attente de votre décision pour la
-- décrue") sans le révéler aux joueurs qui vivent l'event sans meta-info.
local function notifyStaff(message)
    for _, idStr in ipairs(GetPlayers()) do
        local src = tonumber(idStr)
        if src and IsPlayerAceAllowed(src, Config.AdminAce) then
            TriggerClientEvent('ESX:Notify', src, { message = message })
        end
    end
end

-- Copie modifiable des durées, éditable en direct depuis le panel admin
-- sans toucher au fichier de config.
local durations = {
    alert    = Config.Phases.alert,
    rupture  = Config.Phases.rupture,
    rising   = Config.Phases.rising,
    peak     = Config.Phases.peak,
    receding = Config.Phases.receding
}

GlobalState.lsd_floodPhase = 'idle'
GlobalState.lsd_waterLevel = Config.WaterLevel.base
GlobalState.lsd_phaseEndsAt = 0

local function setPhase(phase, duration)
    GlobalState.lsd_floodPhase = phase
    GlobalState.lsd_phaseEndsAt = GetGameTimer() + (duration * 1000)
    TriggerClientEvent('lsd_flood:phaseChanged', -1, phase, duration)
end

local function lerpWater(fromZ, toZ, durationSec)
    local steps = math.max(durationSec, 1)
    local stepTime = 1000
    local delta = (toZ - fromZ) / steps
    for i = 1, steps do
        if not running then return end
        GlobalState.lsd_waterLevel = fromZ + (delta * i)
        Wait(stepTime)
    end
    GlobalState.lsd_waterLevel = toZ
end

local function runFloodSequence()
    running = true
    pendingReceding = false

    setPhase('alert', durations.alert)
    TriggerClientEvent('lsd_flood:alert', -1)
    Wait(durations.alert * 1000)
    if not running then return end

    -- Rupture: le tsunami touche la côte, départ de la vague vers la ville.
    -- L'eau ne monte pas encore, mais la vague voyage déjà.
    setPhase('rupture', durations.rupture)
    -- Horodatage partagé: permet à un joueur qui se connecte pendant la crue
    -- de retrouver la position exacte de la vague au lieu de la rater.
    GlobalState.lsd_ruptureAt = os.time()
    TriggerClientEvent('lsd_flood:damRupture', -1)
    Wait(durations.rupture * 1000)
    if not running then return end

    setPhase('rising', durations.rising)
    lerpWater(Config.WaterLevel.base, Config.WaterLevel.peak, durations.rising)
    if not running then return end

    -- Pic: NIVEAU INDÉFINI. On n'avance plus automatiquement vers la
    -- décrue — c'est désormais une décision du staff (panel F6 > Forcer
    -- une phase > Décrue, ou export BeginReceding). Les joueurs normaux
    -- ne voient aucune info sur ce statut; seul le staff est notifié.
    setPhase('peak', 0)
    notifyStaff('Niveau d\'eau stabilisé. La décrue attend votre décision (panel F6 > Événement > Décrue).')
    while running and not pendingReceding do
        Wait(500)
    end
    if not running then return end

    setPhase('receding', durations.receding)
    lerpWater(Config.WaterLevel.peak, Config.WaterLevel.base, durations.receding)
    if not running then return end

    setPhase('idle', 0)
    GlobalState.lsd_waterLevel = Config.WaterLevel.base
    running = false
end

-- ============================================================
-- API exposée au panel admin (server/nui.lua). Toute la validation de
-- permission a déjà été faite par nui.lua avant d'appeler ces fonctions :
-- elles ne revérifient pas l'ACE, elles exécutent.
-- ============================================================

local function forcePhase(phase)
    if phase == 'receding' then
        -- Si une séquence auto est en cours (bloquée au pic en attente du
        -- staff), on la débloque proprement au lieu de créer un second
        -- déroulement en parallèle.
        if running then
            pendingReceding = true
            return
        end
        running = true
        setPhase('receding', durations.receding)
        return
    end

    running = (phase ~= 'idle')
    pendingReceding = false

    if phase == 'idle' then
        setPhase('idle', 0)
        GlobalState.lsd_waterLevel = Config.WaterLevel.base
    elseif phase == 'peak' then
        setPhase('peak', 0)
        GlobalState.lsd_waterLevel = Config.WaterLevel.peak
        notifyStaff('Niveau d\'eau stabilisé. La décrue attend votre décision (panel F6 > Événement > Décrue).')
    elseif phase == 'rising' then
        setPhase('rising', durations.rising)
    elseif phase == 'rupture' then
        GlobalState.lsd_ruptureAt = os.time()
        setPhase('rupture', durations.rupture)
        TriggerClientEvent('lsd_flood:damRupture', -1)
    elseif phase == 'alert' then
        setPhase('alert', durations.alert)
        TriggerClientEvent('lsd_flood:alert', -1)
    end
end

local function setWaterLevel(level)
    GlobalState.lsd_waterLevel = level
end

local function setDurations(d)
    for k, v in pairs(d) do
        if durations[k] ~= nil and type(v) == 'number' and v > 0 then
            durations[k] = v
        end
    end
end

exports('ForcePhase', forcePhase)
exports('SetWaterLevel', setWaterLevel)
exports('SetDurations', setDurations)
exports('StartFlood', function() if not running then CreateThread(runFloodSequence) end end)
exports('StopFlood', function()
    running = false
    pendingReceding = false
    setPhase('idle', 0)
    GlobalState.lsd_waterLevel = Config.WaterLevel.base
    GlobalState.lsd_ruptureAt = 0
    submersionState = {}
end)
exports('BeginReceding', function() pendingReceding = true end)

RegisterCommand(Config.AdminCommand, function(source)
    if source ~= 0 and not IsPlayerAceAllowed(source, Config.AdminAce) then
        TriggerClientEvent('ESX:Notify', source, {type = 'error', message = 'Accès refusé.'})
        return
    end
    if running then
        TriggerClientEvent('ESX:Notify', source, {type = 'error', message = 'L\'event est déjà en cours.'})
        return
    end
    CreateThread(runFloodSequence)
end, false)

RegisterCommand(Config.StopCommand, function(source)
    if source ~= 0 and not IsPlayerAceAllowed(source, Config.AdminAce) then
        TriggerClientEvent('ESX:Notify', source, {type = 'error', message = 'Accès refusé.'})
        return
    end
    running = false
    pendingReceding = false
    setPhase('idle', 0)
    GlobalState.lsd_waterLevel = Config.WaterLevel.base
    GlobalState.lsd_ruptureAt = 0
    submersionState = {}
end, false)

-- Renvoie l'état courant à un joueur qui vient de se connecter/ressource restart
RegisterNetEvent('lsd_flood:requestState', function()
    local src = source
    TriggerClientEvent('lsd_flood:syncState', src, GlobalState.lsd_floodPhase, GlobalState.lsd_waterLevel)
end)

-- Rapport de submersion envoyé périodiquement par le client, utilisé pour les dégâts
RegisterNetEvent('lsd_flood:reportSubmersion', function(submLevel, pedZ)
    local src = source
    if not Config.Survival.enabled then return end

    local phase = GlobalState.lsd_floodPhase
    if phase ~= 'rising' and phase ~= 'peak' and phase ~= 'receding' then
        submersionState[src] = nil
        return
    end

    if submLevel and submLevel > Config.Survival.safeSubmersion then
        local st = submersionState[src]
        if not st then
            submersionState[src] = { since = GetGameTimer() }
        else
            local elapsed = (GetGameTimer() - st.since) / 1000
            if elapsed >= Config.Survival.graceBeforeDamage then
                local ped = GetPlayerPed(src)
                if ped and ped ~= 0 then
                    local health = GetEntityHealth(ped)
                    local newHealth = math.max(health - Config.Survival.damagePerTick, 0)
                    SetEntityHealth(ped, newHealth)
                    TriggerClientEvent('lsd_flood:drowningWarning', src)
                end
            end
        end
    else
        submersionState[src] = nil
    end
end)

AddEventHandler('playerDropped', function()
    submersionState[source] = nil
end)

-- Sécurité: si la ressource redémarre en pleine crue, on ne laisse pas un état incohérent
AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() ~= resName then return end
    running = false
end)
