# lsd_flood_event — Rupture du barrage de Land Act

Event d'ouverture de serveur ESX : sirènes, alerte, montée d'eau progressive,
évacuation et système de survie (noyade) synchronisé pour tous les joueurs.

## Installation

1. Copiez le dossier `lsd_flood_event` dans `resources/`.
2. Ajoutez `ensure lsd_flood_event` dans votre `server.cfg`, après `es_extended`.
3. Donnez la permission ACE à vos admins :
   ```
   add_ace group.admin command.startflood allow
   add_principal identifier.xxxx group.admin
   ```

## Déclenchement

- `/startflood` : lance la séquence complète (alerte → crue → pic → décrue).
- `/stopflood` : interrompt l'event et revient à l'état normal.
- Pour un déclenchement automatique à l'ouverture du serveur, ajoutez dans
  `server/main.lua` un appel `runFloodSequence()` dans un `CreateThread` au
  démarrage de la ressource plutôt que d'attendre la commande.

## Points importants à savoir (honnêteté technique)

- **L'eau réelle de GTA V (heightmap native) n'est pas modifiable en temps
  réel côté client.** Ce script simule donc la crue avec un objet translucide
  (`Config.WaterProp`) qui suit `GlobalState.lsd_waterLevel`. Pour un rendu
  premium, remplacez `Config.WaterProp.model` par votre propre asset eau
  (ymap/shader) — c'est le point d'extension prévu pour "la claque visuelle".
- **La logique de noyade/dégâts est 100% scriptée** (comparaison de
  coordonnées Z par rapport au niveau d'eau + zones inondées définies dans
  `Config.FloodZones`), pas basée sur la physique d'eau native — ce qui la
  rend fiable même avec l'eau "fake".
- **La synchro utilise des `GlobalState` (statebags)**, pas des events
  spammés en boucle : chaque client lit l'état à son rythme, ce qui garde
  le serveur stable même avec beaucoup de joueurs connectés.
- **Sirènes** : utilise `xsound` si présent (recommandé, mettez l'URL de
  votre fichier audio de sirène dans `Config.Sirens.url`) sinon fallback sur
  un son natif en boucle.

## Configuration

Tout se règle dans `shared/config.lua` :
- `Config.Phases` : durée de chaque phase.
- `Config.WaterLevel` : niveau de base et niveau max de la crue.
- `Config.FloodZones` : quartiers touchés (centre + rayon) pour les dégâts et blips.
- `Config.EvacPoints` : points hauts sûrs affichés sur la carte.
- `Config.Survival` : intervalle de vérification, dégâts, tolérance de submersion.
