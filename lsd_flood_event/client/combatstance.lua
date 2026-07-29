-- ============================================================
-- FIX: démarche "combat stance" figée après un tir
--
-- Ce que GTA fait par défaut: après avoir tiré, le ped bascule en
-- "Action Mode" — la posture où l'arme est tenue à deux mains, prête,
-- même en marchant normalement sans viser. C'est ça qui donne la
-- démarche raide et bizarre.
--
-- Fix, en continu et sans délai tant que le joueur n'est ni en train
-- de viser ni de tirer:
--   - SetPedUsingActionMode(ped, false, ...) coupe directement la
--     posture "prêt au combat" qui cause ce comportement.
--   - ResetPedMovementClipset ramène le clipset de mouvement standard
--     en complément, au cas où un clipset combat serait resté actif.
--   - ClearPedSecondaryTask nettoie une éventuelle tâche d'overlay
--     (bras/visée) qui traînerait.
--
-- Appliqué CHAQUE FRAME (pas une seule fois) tant que la condition est
-- vraie: si ça ne suffit toujours pas en jeu, dites-moi précisément ce
-- que vous voyez (idéalement une vidéo courte) — je n'ai pas pu tester
-- ça en jeu moi-même, donc j'itère sur votre retour plutôt qu'à l'aveugle.
-- ============================================================

local S = Config.CombatStanceFix
if not (S and S.enabled) then return end

CreateThread(function()
    while true do
        Wait(0)  -- immédiat: on ne laisse plus la posture s'installer

        local ped = PlayerPedId()
        local playerId = PlayerId()

        local aiming = IsPlayerFreeAiming(playerId)
        local shooting = IsPedShooting(ped)
        local weapon = GetSelectedPedWeapon(ped)
        local armed = weapon ~= GetHashKey('WEAPON_UNARMED')

        if armed and not aiming and not shooting then
            SetPedUsingActionMode(ped, false, -1, 'DEFAULT_ACTION')
            ResetPedMovementClipset(ped, 0.0)
            ClearPedSecondaryTask(ped)
        end
    end
end)
