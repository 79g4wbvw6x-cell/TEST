ESX = exports['es_extended']:getSharedObject()

local running = false
local submersionState = {} -- [source] = { since = os.time() or false }

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

    setPhase('alert', Config.Phases.alert)
    TriggerClientEvent('lsd_flood:alert', -1)
    Wait(Config.Phases.alert * 1000)
    if not running then return end

    setPhase('rising', Config.Phases.rising)
    lerpWater(Config.WaterLevel.base, Config.WaterLevel.peak, Config.Phases.rising)
    if not running then return end

    setPhase('peak', Config.Phases.peak)
    Wait(Config.Phases.peak * 1000)
    if not running then return end

    setPhase('receding', Config.Phases.receding)
    lerpWater(Config.WaterLevel.peak, Config.WaterLevel.base, Config.Phases.receding)
    if not running then return end

    setPhase('idle', 0)
    GlobalState.lsd_waterLevel = Config.WaterLevel.base
    running = false
end

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
    setPhase('idle', 0)
    GlobalState.lsd_waterLevel = Config.WaterLevel.base
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
