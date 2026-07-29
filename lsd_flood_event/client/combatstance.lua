-- ============================================================
-- FIX: démarche "combat stance" figée après un tir
--
-- Comportement par défaut de GTA: après avoir tiré, le ped reste en
-- posture d'alerte (arme tenue à deux mains, démarche raide) même une
-- fois qu'on relâche la visée et qu'on marche normalement. C'est le
-- clipset de mouvement "combat" qui reste actif au lieu de revenir au
-- clipset normal.
--
-- Fix: dès que le joueur ne vise plus et ne tire plus depuis un court
-- délai, on force le retour au clipset de mouvement par défaut via
-- ResetPedMovementClipset (native FiveM documentée pour exactement ce
-- cas). Pas de désactivation du mode combat lui-même (le joueur peut
-- toujours viser/tirer normalement) — seule la démarche qui traîne
-- après coup est corrigée.
-- ============================================================

local S = Config.CombatStanceFix
if not (S and S.enabled) then return end

local wasInStance = false
local stillTimer = 0

CreateThread(function()
    while true do
        Wait(S.checkInterval or 150)

        local ped = PlayerPedId()
        local playerId = PlayerId()

        local aiming = IsPlayerFreeAiming(playerId)
        local shooting = IsPedShooting(ped)
        local weapon = GetSelectedPedWeapon(ped)
        local armed = weapon ~= GetHashKey('WEAPON_UNARMED')

        if armed and not aiming and not shooting then
            stillTimer = stillTimer + (S.checkInterval or 150)
            if stillTimer >= (S.graceMs or 250) then
                ResetPedMovementClipset(ped, 0.0)
                stillTimer = 0
            end
        else
            stillTimer = 0
        end
    end
end)
