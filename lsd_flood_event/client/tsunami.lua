-- ============================================================
-- TSUNAMI — vague visible au loin qui approche, touche la côte,
-- puis recouvre la ville. Pas de modèle à casser, pas de collision à
-- éditer : seulement un front qui voyage le long de Config.Tsunami.path,
-- synchronisé pour tous les joueurs via GlobalState.lsd_tsunamiProgress
-- (calculé côté serveur, jamais via l'horloge système du client), plus un
-- mur visuel et un grondement qui s'intensifie à mesure qu'elle approche.
-- ============================================================

local T = Config.Tsunami
local active = false
local rumbleActive = false

-- Pré-calcul des longueurs cumulées du chemin
local path, cumul, totalLen

local function buildPath()
    path = T.path
    cumul = { 0.0 }
    local total = 0.0
    for i = 2, #path do
        total = total + #(path[i] - path[i - 1])
        cumul[i] = total
    end
    totalLen = total
end

local function positionAt(t)
    if not path then buildPath() end
    if t <= 0.0 then return path[1] end
    if t >= 1.0 then return path[#path] end

    local target = t * totalLen
    for i = 2, #path do
        if cumul[i] >= target then
            local segStart, segEnd = path[i - 1], path[i]
            local segLen = cumul[i] - cumul[i - 1]
            local local_t = segLen > 0.0 and ((target - cumul[i - 1]) / segLen) or 0.0
            return segStart + ((segEnd - segStart) * local_t)
        end
    end
    return path[#path]
end

-- Lit directement la progression calculée par le serveur (GetGameTimer(),
-- jamais os.time() qui reflète l'horloge système de chaque machine et
-- n'a aucune raison d'être synchronisée entre serveur et client — c'était
-- le vrai bug qui empêchait le mur de s'afficher).
local function progress()
    local phase = GlobalState.lsd_floodPhase
    if phase ~= 'rupture' and phase ~= 'rising' and phase ~= 'peak' then return nil end
    local t = GlobalState.lsd_tsunamiProgress
    if not t then return nil end
    return math.max(0.0, math.min(1.0, t))
end

-- ------------------------------------------------------------
-- Mur visuel: plusieurs marqueurs empilés/décalés pour donner du volume
-- et une silhouette de vague déferlante, pas juste un bloc plat. Pas
-- d'asset custom nécessaire — DrawMarker est natif, aucune dépendance.
--
-- La hauteur grandit progressivement à mesure que le tsunami approche:
-- petit à l'horizon, monstrueux au moment de l'impact.
-- ------------------------------------------------------------

local function drawWall(pos, t)
    -- Direction du trajet à cet instant, pour orienter le mur perpendiculaire
    local ahead = positionAt(math.min(t + 0.02, 1.0))
    local dir = ahead - pos
    local len = #dir
    local heading = len > 0.0 and math.deg(math.atan(dir.x, dir.y)) or 0.0

    -- Croissance non-linéaire: reste impressionnant même loin, explose au
    -- moment du landfall.
    local growth = math.min(t / T.landfallProgress, 1.0)
    local height = 15.0 + T.wallHeight * (growth * growth)
    local rad = math.rad(heading)
    local perp = vector3(math.cos(rad), -math.sin(rad), 0.0)

    -- Corps principal du mur
    DrawMarker(
        1, pos.x, pos.y, pos.z + height * 0.5, 0,0,0,
        0.0, 0.0, heading,
        T.width, 30.0, height,
        15, 60, 120, 210,
        false, false, 2, false, nil, nil, false
    )

    -- Crête blanche/écume au sommet, légèrement en avant (donne le sens
    -- de déferlement)
    local crestPos = pos + (dir / math.max(len, 1.0)) * 20.0
    DrawMarker(
        1, crestPos.x, crestPos.y, crestPos.z + height * 0.92, 0,0,0,
        0.0, 0.0, heading,
        T.width * 0.98, 18.0, height * 0.18,
        230, 240, 250, 220,
        false, false, 2, false, nil, nil, false
    )

    -- Deux vaguelettes secondaires derrière le front principal: renforce
    -- l'impression de masse d'eau qui arrive, pas un mur plat isolé
    for i = 1, 2 do
        local behind = pos - (dir / math.max(len, 1.0)) * (60.0 * i)
        local h2 = height * (1.0 - 0.22 * i)
        DrawMarker(
            1, behind.x, behind.y, behind.z + h2 * 0.5, 0,0,0,
            0.0, 0.0, heading,
            T.width * (1.0 - 0.08 * i), 25.0, h2,
            20, 70, 130, math.floor(190 - 40 * i),
            false, false, 2, false, nil, nil, false
        )
    end
end

-- ------------------------------------------------------------
-- Particules d'écume sur le front
-- ------------------------------------------------------------

local function loadPtfx(dict)
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local timeout = GetGameTimer() + 3000
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    return HasNamedPtfxAssetLoaded(dict)
end

local function spawnFoam(pos, scale)
    if not loadPtfx('core') then return end
    for i = -3, 3 do
        local offset = vector3(i * (T.width / 7.0), 0.0, 0.0)
        local p = pos + offset
        UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedAtCoord(
            'water_splash_ped_in',
            p.x, p.y, p.z, 0.0, 0.0, 0.0,
            scale or T.ptfxScale, false, false, false
        )
    end
end

-- ------------------------------------------------------------
-- Grondement qui s'intensifie avec la proximité
-- ------------------------------------------------------------

local function updateRumble(dist)
    if not (T.rumble and T.rumble.enabled) then return end
    if dist > 3000.0 then return end
    if not rumbleActive then
        rumbleActive = true
        CreateThread(function()
            while active and rumbleActive do
                local d = math.max(dist, 50.0)
                local interval = math.floor(300 + (d / 3000.0) * 2000)
                PlaySoundFrontend(-1, 'Bed', T.rumble.soundset, false)
                Wait(interval)
            end
        end)
    end
end

-- ------------------------------------------------------------
-- Impact physique (uniquement après le landfall, jamais pendant
-- l'approche au large)
-- ------------------------------------------------------------

local function applyImpact(pos)
    local imp = T.impact
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local dist = #(coords - pos)
    if dist > T.width then return end

    local intensity = 1.0 - (dist / T.width)
    ShakeGameplayCam(imp.camShake, intensity * 1.2)

    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        local dir = coords - pos
        local len = #dir
        if len > 0.0 then
            local n = dir / len
            ApplyForceToEntity(veh, 1, n.x * imp.vehicleForce, n.y * imp.vehicleForce,
                imp.vehicleForce * 0.4, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
        end
    elseif imp.ragdollPlayers and not IsPedRagdoll(ped) then
        SetPedToRagdoll(ped, imp.ragdollDuration, imp.ragdollDuration, 0, true, true, false)
    end
end

-- ------------------------------------------------------------
-- Boucle principale
-- ------------------------------------------------------------

local lastFoamTime = 0

local function run()
    if active then return end
    active = true
    lastFoamTime = 0

    while active do
        local t = progress()
        if not t then break end

        local pos = positionAt(t)
        local myCoords = GetEntityCoords(PlayerPedId())
        local dist = #(myCoords - pos)

        updateRumble(dist)

        if dist <= T.renderDistance then
            drawWall(pos, t)

            -- Panache d'écume continu pendant TOUTE l'approche (pas
            -- seulement à l'impact) — c'est ce qui donne l'impression
            -- qu'on voit vraiment une masse d'eau vivante venir de loin,
            -- pas juste un bloc statique.
            local now = GetGameTimer()
            if now - lastFoamTime > 800 then
                local scale = t < T.landfallProgress and (T.ptfxScale * 0.5) or T.ptfxScale
                spawnFoam(pos, scale)
                lastFoamTime = now
            end
        end

        if t >= T.landfallProgress then
            -- La vague a touché terre: elle a maintenant un effet physique
            if dist <= T.width * 1.5 then
                applyImpact(pos)
            end
            Wait(100)
        else
            -- Encore au large: visible mais aucun impact
            Wait(150)
        end
    end

    active = false
    rumbleActive = false
    StopGameplayCamShaking(true)
end

RegisterNetEvent('lsd_flood:damRupture', function()
    CreateThread(run)
end)

RegisterNetEvent('lsd_flood:syncState', function(phase)
    if phase == 'rupture' or phase == 'rising' or phase == 'peak' then
        CreateThread(run)
    end
end)

RegisterNetEvent('lsd_flood:phaseChanged', function(phase)
    if phase == 'idle' then
        active = false
        rumbleActive = false
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() ~= resName then return end
    active = false
    rumbleActive = false
    StopGameplayCamShaking(true)
end)

if Config.DevCommands then
    RegisterCommand('ptfxtest', function(_, args)
        local dict, effect, scale = args[1], args[2], tonumber(args[3]) or 5.0
        if not dict or not effect then
            print('[ptfxtest] Usage: /ptfxtest <dict> <effet> [echelle]')
            return
        end
        if not loadPtfx(dict) then
            print(('[ptfxtest] Dictionnaire introuvable: %s'):format(dict))
            return
        end
        local p = GetEntityCoords(PlayerPedId())
        UseParticleFxAssetNextCall(dict)
        local h = StartParticleFxLoopedAtCoord(effect, p.x, p.y, p.z + 1.0, 0.0, 0.0, 0.0, scale, false, false, false, false)
        if h and h ~= 0 then
            print(('[ptfxtest] OK -> %s / %s (10s)'):format(dict, effect))
            Wait(10000)
            StopParticleFxLooped(h, 0)
        else
            print(('[ptfxtest] Echec: %s / %s'):format(dict, effect))
        end
    end, false)

    RegisterCommand('tsunamiinfo', function()
        local t = progress()
        if not t then
            print('[tsunamiinfo] Aucun tsunami en cours.')
            return
        end
        local pos = positionAt(t)
        local dist = #(GetEntityCoords(PlayerPedId()) - pos)
        print(('[tsunamiinfo] Progression: %.1f%% | Distance: %.0fm | Landfall: %s'):format(
            t * 100, dist, t >= T.landfallProgress and 'oui' or 'non'))
    end, false)
end
