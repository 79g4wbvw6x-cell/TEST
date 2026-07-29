-- ============================================================
-- RUPTURE DU BARRAGE DE LAND ACT
--
-- Ce module gère tout ce qui se passe AU barrage: explosion en
-- cascade, effondrement visuel, torrent jaillissant de la brèche,
-- et la vague qui déferle du barrage jusqu'aux quartiers bas.
--
-- Contrainte assumée: le barrage de Land Act est de la géométrie de
-- map statique. On ne peut pas le "casser" par script. On combine
-- donc trois techniques pour l'illusion:
--   1. masquage/remplacement du modèle (CreateModelHide / CreateModelSwap)
--   2. explosions + secousses caméra au moment de la rupture
--   3. un torrent de particules permanent sortant de la brèche
-- ============================================================

local ruptured = false
local breachHandles = {}       -- émetteurs ptfx du torrent
local breachActive = false
local waveActive = false
local swapApplied = false
local hideApplied = false

-- ------------------------------------------------------------
-- Utilitaires
-- ------------------------------------------------------------

local function loadPtfxAsset(dict)
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local timeout = GetGameTimer() + 5000
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < timeout do
        Wait(0)
    end
    return HasNamedPtfxAssetLoaded(dict)
end

local function headingToVector(heading)
    local rad = math.rad(heading)
    return vector3(-math.sin(rad), math.cos(rad), 0.0)
end

-- ------------------------------------------------------------
-- 1. EFFONDREMENT VISUEL DU BARRAGE
-- ------------------------------------------------------------

local function applyDamDestruction()
    local d = Config.Dam.breach.coords

    local swap = Config.Rupture.modelSwap
    if swap.enabled and swap.srcModel and swap.dstModel then
        local src = type(swap.srcModel) == 'string' and GetHashKey(swap.srcModel) or swap.srcModel
        local dst = type(swap.dstModel) == 'string' and GetHashKey(swap.dstModel) or swap.dstModel
        CreateModelSwap(d.x, d.y, d.z, swap.radius, src, dst, true)
        swapApplied = true
    end

    -- Le barrage est fait de plusieurs morceaux : on les masque tous.
    local hide = Config.Rupture.modelHide
    if hide.enabled and hide.models then
        for _, name in ipairs(hide.models) do
            local m = type(name) == 'string' and GetHashKey(name) or name
            CreateModelHide(d.x, d.y, d.z, hide.radius, m, true)
        end
        hideApplied = true
    end
end

local function revertDamDestruction()
    local d = Config.Dam.breach.coords

    if swapApplied then
        local swap = Config.Rupture.modelSwap
        local src = type(swap.srcModel) == 'string' and GetHashKey(swap.srcModel) or swap.srcModel
        local dst = type(swap.dstModel) == 'string' and GetHashKey(swap.dstModel) or swap.dstModel
        RemoveModelSwap(d.x, d.y, d.z, swap.radius, src, dst, false)
        swapApplied = false
    end

    if hideApplied then
        local hide = Config.Rupture.modelHide
        for _, name in ipairs(hide.models) do
            local m = type(name) == 'string' and GetHashKey(name) or name
            RemoveModelHide(d.x, d.y, d.z, hide.radius, m, false)
        end
        hideApplied = false
    end
end

-- ------------------------------------------------------------
-- 2. EXPLOSIONS EN CASCADE + SECOUSSES
-- ------------------------------------------------------------

local function playRuptureBlast()
    local base = Config.Dam.breach.coords

    for _, ex in ipairs(Config.Rupture.explosions) do
        CreateThread(function()
            Wait(ex.delay)
            local p = base + ex.offset
            AddExplosion(p.x, p.y, p.z, ex.type, ex.scale, true, false, 1.0)
        end)
    end

    -- Secousse ressentie partout en ville, atténuée avec la distance
    CreateThread(function()
        local ped = PlayerPedId()
        local dist = #(GetEntityCoords(ped) - base)
        local intensity = math.max(0.0, 1.0 - (dist / 3000.0))
        if intensity > 0.05 then
            ShakeGameplayCam(Config.Rupture.impact.camShake, intensity * 1.5)
            SetPadShake(0, 2000, math.floor(180 * intensity))
            Wait(4000)
            StopGameplayCamShaking(true)
        end
    end)
end

-- ------------------------------------------------------------
-- 3. TORRENT PERMANENT SORTANT DE LA BRÈCHE
--
-- Les émetteurs ne sont créés que si le joueur est assez proche,
-- et détruits dès qu'il s'éloigne: aucun coût quand personne n'est
-- au barrage, ce qui garde le FPS stable en ville.
-- ------------------------------------------------------------

local function startBreachEmitters()
    if breachActive then return end
    local cfg = Config.Rupture.ptfx
    if not loadPtfxAsset(cfg.dict) then return end

    local b = Config.Dam.breach
    local dir = headingToVector(b.heading)
    -- vecteur perpendiculaire pour répartir les émetteurs sur la largeur
    local perp = vector3(-dir.y, dir.x, 0.0)
    local count = math.max(1, math.floor(b.width / cfg.emitterSpacing))

    for i = 0, count do
        local t = (i / count) - 0.5
        local p = b.coords + (perp * (t * b.width))
        UseParticleFxAssetNextCall(cfg.dict)
        local h = StartParticleFxLoopedAtCoord(
            cfg.effect,
            p.x, p.y, p.z,
            0.0, 0.0, b.heading,
            cfg.scale,
            false, false, false, false
        )
        if h and h ~= 0 then
            breachHandles[#breachHandles + 1] = h
        end
    end

    breachActive = true
end

local function stopBreachEmitters()
    for _, h in ipairs(breachHandles) do
        if DoesParticleFxLoopedExist(h) then
            StopParticleFxLooped(h, 0)
        end
    end
    breachHandles = {}
    breachActive = false
end

-- Gestion distance: allume/éteint le torrent selon la position du joueur
CreateThread(function()
    while true do
        Wait(1500)
        if ruptured then
            local dist = #(GetEntityCoords(PlayerPedId()) - Config.Dam.breach.coords)
            if dist <= Config.Rupture.ptfx.renderDistance then
                startBreachEmitters()
            else
                stopBreachEmitters()
            end
        elseif breachActive then
            stopBreachEmitters()
        end
    end
end)

-- ------------------------------------------------------------
-- 4. LA VAGUE QUI DÉFERLE VERS LA VILLE
--
-- La vague suit un chemin de nodes. Sa position est calculée à
-- partir de l'horodatage serveur partagé (GlobalState.lsd_ruptureAt),
-- donc TOUS les joueurs la voient au même endroit au même moment,
-- y compris ceux qui se connectent en cours d'event.
-- ------------------------------------------------------------

-- Pré-calcul des longueurs cumulées du chemin
local wavePath, waveCumul, waveTotalLen

local function buildWavePath()
    wavePath = Config.Rupture.wave.path
    waveCumul = { 0.0 }
    local total = 0.0
    for i = 2, #wavePath do
        total = total + #(wavePath[i] - wavePath[i - 1])
        waveCumul[i] = total
    end
    waveTotalLen = total
end

-- Retourne la position de la vague pour une progression t (0..1)
local function getWavePosition(t)
    if not wavePath then buildWavePath() end
    if t <= 0.0 then return wavePath[1] end
    if t >= 1.0 then return wavePath[#wavePath] end

    local target = t * waveTotalLen
    for i = 2, #wavePath do
        if waveCumul[i] >= target then
            local segStart, segEnd = wavePath[i - 1], wavePath[i]
            local segLen = waveCumul[i] - waveCumul[i - 1]
            local local_t = segLen > 0.0 and ((target - waveCumul[i - 1]) / segLen) or 0.0
            return segStart + ((segEnd - segStart) * local_t)
        end
    end
    return wavePath[#wavePath]
end

local function waveProgress()
    local startedAt = GlobalState.lsd_ruptureAt
    if not startedAt or startedAt == 0 then return nil end
    local elapsed = os.time() - startedAt
    local t = elapsed / Config.Rupture.wave.travelTime
    if t < 0.0 or t > 1.0 then return nil end
    return t
end

local function renderWaveAt(pos)
    local cfg = Config.Rupture.ptfx
    if not HasNamedPtfxAssetLoaded(cfg.dict) then
        if not loadPtfxAsset(cfg.dict) then return end
    end

    -- Front de vague: plusieurs bursts alignés perpendiculairement au trajet
    local w = Config.Rupture.wave.width
    for i = -2, 2 do
        local offset = vector3(i * (w / 3.0), 0.0, 0.0)
        local p = pos + offset
        UseParticleFxAssetNextCall(cfg.dict)
        StartParticleFxNonLoopedAtCoord(
            cfg.effect,
            p.x, p.y, p.z,
            0.0, 0.0, 0.0,
            Config.Rupture.wave.ptfxScale,
            false, false, false
        )
    end
end

local function applyWaveImpact(pos)
    local imp = Config.Rupture.impact
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local dist = #(coords - pos)

    if dist > Config.Rupture.wave.width then return end

    -- Secousse proportionnelle à la proximité du front
    local intensity = 1.0 - (dist / Config.Rupture.wave.width)
    ShakeGameplayCam(imp.camShake, intensity * 1.2)

    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        local dir = coords - pos
        local len = #(dir)
        if len > 0.0 then
            local n = dir / len
            ApplyForceToEntity(
                veh, 1,
                n.x * imp.vehicleForce, n.y * imp.vehicleForce, imp.vehicleForce * 0.4,
                0.0, 0.0, 0.0, 0, true, true, true, false, true
            )
        end
    elseif imp.ragdollPlayers and not IsPedRagdoll(ped) then
        SetPedToRagdoll(ped, imp.ragdollDuration, imp.ragdollDuration, 0, true, true, false)
    end
end

local function runWave()
    if waveActive or not Config.Rupture.wave.enabled then return end
    waveActive = true

    while waveActive do
        local t = waveProgress()
        if not t then break end

        local pos = getWavePosition(t)
        local dist = #(GetEntityCoords(PlayerPedId()) - pos)

        -- Rendu uniquement si le joueur peut réellement voir la vague
        if dist <= Config.Rupture.ptfx.renderDistance then
            renderWaveAt(pos)
            applyWaveImpact(pos)
            Wait(150)
        else
            Wait(1000)
        end
    end

    waveActive = false
    StopGameplayCamShaking(true)
end

-- ------------------------------------------------------------
-- DÉCLENCHEMENT
-- ------------------------------------------------------------

local function triggerRupture(withBlast)
    if ruptured then return end
    ruptured = true

    if withBlast then
        playRuptureBlast()
        Wait(2500)  -- l'effondrement suit les premières charges
    end

    applyDamDestruction()
    CreateThread(runWave)
end

RegisterNetEvent('lsd_flood:damRupture', function()
    CreateThread(function() triggerRupture(true) end)
end)

-- Resynchronisation: joueur connecté APRÈS la rupture.
-- Pas d'explosion rejouée (l'événement est passé), mais le barrage
-- est bien affiché éventré et la vague reprise à sa position réelle.
RegisterNetEvent('lsd_flood:syncState', function(phase)
    if phase == 'rupture' or phase == 'rising' or phase == 'peak' or phase == 'receding' then
        CreateThread(function() triggerRupture(false) end)
    end
end)

RegisterNetEvent('lsd_flood:phaseChanged', function(phase)
    if phase == 'idle' then
        ruptured = false
        waveActive = false
        stopBreachEmitters()
        revertDamDestruction()
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() ~= resName then return end
    stopBreachEmitters()
    revertDamDestruction()
    StopGameplayCamShaking(true)
end)

-- ------------------------------------------------------------
-- OUTILS DE REPÉRAGE (développement)
-- ------------------------------------------------------------

if Config.DevCommands then
    -- Affiche les coordonnées visées et le modèle sous le viseur.
    -- Indispensable pour trouver le vrai modèle du barrage et régler
    -- la position exacte de la brèche.
    RegisterCommand('damscan', function()
        local ped = PlayerPedId()
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        local rad = vector3(math.rad(camRot.x), math.rad(camRot.y), math.rad(camRot.z))
        local dir = vector3(
            -math.sin(rad.z) * math.abs(math.cos(rad.x)),
             math.cos(rad.z) * math.abs(math.cos(rad.x)),
             math.sin(rad.x)
        )
        local dest = camCoords + (dir * 100.0)

        local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, dest.x, dest.y, dest.z, -1, ped, 0)
        local _, hit, endCoords, _, entity = GetShapeTestResult(ray)

        local mine = GetEntityCoords(ped)
        print(('[damscan] Position joueur : vector3(%.2f, %.2f, %.2f)'):format(mine.x, mine.y, mine.z))

        if hit == 1 then
            print(('[damscan] Point visé      : vector3(%.2f, %.2f, %.2f)'):format(endCoords.x, endCoords.y, endCoords.z))
            -- Le raycast peut renvoyer un handle non nul mais invalide sur de
            -- la géométrie de map : GetEntityModel plante dessus. D'où la garde.
            if entity and entity ~= 0 and DoesEntityExist(entity) then
                print(('[damscan] Modèle visé     : %s (hash)'):format(GetEntityModel(entity)))
            else
                print('[damscan] Pas d\'entité script exploitable ici.')
                print('[damscan] -> Utilisez /damhide <modele> pour tester un nom.')
            end
        else
            print('[damscan] Rien touché (visez le barrage de plus près).')
        end
    end, false)

    -- Test empirique d'un nom de modèle de map.
    -- Sur de la géométrie de map, le raycast ne renvoie pas d'entité
    -- exploitable : impossible de lire le hash. La seule façon de valider un
    -- nom, c'est d'essayer de le masquer et de regarder si ça disparaît.
    local testHidden = {}

    RegisterCommand('damhide', function(_, args)
        local name = args[1]
        local radius = tonumber(args[2]) or 40.0
        if not name then
            print('[damhide] Usage: /damhide <nom_du_modele> [rayon]')
            print('[damhide] Sans argument de modèle, teste toute la liste du config.')
            return
        end

        local p = GetEntityCoords(PlayerPedId())
        local hash = GetHashKey(name)
        CreateModelHide(p.x, p.y, p.z, radius, hash, true)
        testHidden[#testHidden + 1] = { hash = hash, x = p.x, y = p.y, z = p.z, r = radius }
        print(('[damhide] Masquage tenté : %s (rayon %.0f)'):format(name, radius))
        print('[damhide] Regardez autour de vous. /damunhide pour tout restaurer.')
    end, false)

    -- Teste d'un coup tous les noms de Config.Rupture.modelHide.models
    RegisterCommand('damhideall', function()
        local p = GetEntityCoords(PlayerPedId())
        local r = Config.Rupture.modelHide.radius or 40.0
        for _, name in ipairs(Config.Rupture.modelHide.models or {}) do
            local hash = GetHashKey(name)
            CreateModelHide(p.x, p.y, p.z, r, hash, true)
            testHidden[#testHidden + 1] = { hash = hash, x = p.x, y = p.y, z = p.z, r = r }
            print(('[damhideall] -> %s'):format(name))
        end
        print('[damhideall] Terminé. /damunhide pour restaurer.')
    end, false)

    RegisterCommand('damunhide', function()
        for _, h in ipairs(testHidden) do
            RemoveModelHide(h.x, h.y, h.z, h.r, h.hash, false)
        end
        print(('[damunhide] %d masquage(s) annulé(s).'):format(#testHidden))
        testHidden = {}
    end, false)

    -- Teste un couple dict/effet de particules à l'endroit où vous êtes.
    -- Sert à valider les assets ptfx avant de les mettre en config.
    RegisterCommand('ptfxtest', function(_, args)
        local dict = args[1]
        local effect = args[2]
        local scale = tonumber(args[3]) or 5.0
        if not dict or not effect then
            print('[ptfxtest] Usage: /ptfxtest <dict> <effet> [echelle]')
            return
        end
        if not loadPtfxAsset(dict) then
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
            print(('[ptfxtest] Échec: %s / %s'):format(dict, effect))
        end
    end, false)
end
