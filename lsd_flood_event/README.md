# lsd_flood_event — Tsunami sur Los Santos

Event d'ouverture de serveur ESX : alerte, tsunami visible au large qui
approche pendant plusieurs minutes, impact sur la côte, montée d'eau
progressive sur toute la ville, décrue, panel admin complet et menu
contextuel RP.

## Installation

1. Copiez le dossier `lsd_flood_event` dans `resources/`.
2. Ajoutez `ensure lsd_flood_event` dans votre `server.cfg`, après `es_extended`.
3. Donnez la permission ACE à vos admins :
   ```
   add_ace group.admin command.startflood allow
   add_principal identifier.xxxx group.admin
   ```

## Déclenchement

- `/startflood` : lance la séquence complète (alerte → tsunami → crue → pic → décrue).
- `/stopflood` : interrompt l'event et revient à l'état normal.
- **F6** : panel admin complet (contrôle de l'event, météo/heure, blackout,
  véhicules, armes, outils joueur).
- **ALT** : menu contextuel RP (soi-même, joueur ciblé, véhicule, sol/admin).

## Comment ça marche

### Le tsunami
Un front d'eau part du large (`Config.Tsunami.origin`) et voyage jusqu'à la
ville en suivant `Config.Tsunami.path`, sur `Config.Tsunami.travelTime`
secondes (4 min par défaut). Sa position est calculée depuis un horodatage
serveur partagé, donc tous les joueurs le voient au même endroit au même
instant — y compris un joueur qui se connecte en cours d'event.

**Bug corrigé** : la première version plaçait l'origine à x=-5800, en
dehors de la zone réellement chargée par le jeu (~x -4200..4700), donc rien
ne s'affichait — le tsunami existait en théorie mais était rendu dans le
vide. Les coordonnées sont maintenant dans la carte.

Le mur est composé de plusieurs marqueurs empilés (corps + crête d'écume +
deux vaguelettes secondaires derrière) dont la hauteur grandit de façon non
linéaire à mesure que le tsunami approche — petit à l'horizon, jusqu'à
`wallHeight` (140m par défaut) au moment de l'impact — plus un panache de
particules continu pendant toute l'approche, pas seulement à l'impact.
Un grondement s'intensifie avec la proximité.

Pendant la première partie du trajet (`landfallProgress`, 40% par défaut),
la vague est **visible mais sans impact physique**. Une fois ce seuil
atteint, elle produit un vrai impact (ragdoll des joueurs, poussée des
véhicules) pour quiconque se trouve dans sa largeur.

### Le pic et la décrue — décision du staff
Après la montée, l'eau se stabilise **indéfiniment**. La séquence
automatique ne fait plus avancer vers la décrue toute seule : c'est au
staff de la déclencher, via le panel F6 (Événement > Forcer une phase >
Décrue). Les joueurs normaux ne reçoivent aucune information sur ce
statut — seul le staff (permission ACE) est notifié quand le niveau se
stabilise et qu'une décision est attendue.

### La montée d'eau
Indépendante du tsunami : `client/water.lua` recharge des fichiers
`water.xml` pré-générés (un par palier de hauteur) via `LoadWaterFromPath`,
la seule méthode qui force réellement le moteur à re-rendre l'eau — les
natives `SetWaterQuadLevel` seules ne suffisent pas, elles changent les
données mais pas l'affichage.

Ces fichiers sont dans `stream/water_lvl_XX.xml`, générés depuis un
`water.xml` extrait du jeu par `tools/generate_water_levels.py`. Ils
couvrent toute la carte (pas seulement les zones déjà aquatiques d'origine),
donc l'eau monte vraiment sur la ville, pas juste sur les plages.

Pour régénérer avec un autre `water.xml` ou d'autres paliers :
```
python3 tools/generate_water_levels.py water.xml --min 0 --max 150 --step 5
```
Puis recopiez la ligne `levels = {...}` affichée dans `Config.Water.levels`.

### La noyade
100% scriptée (comparaison de coordonnées Z par rapport au niveau d'eau +
zones inondées définies dans `Config.FloodZones`), pas basée sur la
physique d'eau native.

### La synchro
`GlobalState` (statebags), pas des events spammés en boucle : chaque
client lit l'état à son propre rythme, ce qui garde le serveur stable même
avec beaucoup de joueurs connectés.

### Le blackout Sud/Nord
GTA n'a qu'un interrupteur global pour les lumières artificielles (pas de
version par zone dans le moteur). L'effet "Sud coupé, Nord épargné" est
donc simulé par position : chaque client active/désactive SES lumières
selon l'endroit où IL se trouve. Réglable dans
`Config.Spectacle.blackout.boundaryY`.

## Configuration

Tout se règle dans `shared/config.lua` :
- `Config.Phases` : durée de chaque phase.
- `Config.Tsunami` : trajet, vitesse, largeur, hauteur du mur visuel, impact.
- `Config.WaterLevel` / `Config.Water.levels` : niveau de crue et paliers pré-générés.
- `Config.FloodZones` : quartiers touchés (dégâts, blips).
- `Config.EvacPoints` : points hauts sûrs affichés sur la carte.
- `Config.Survival` : dégâts de noyade.
- `Config.Spectacle` : blackout, météo, panique PNJ, débris, hélicoptères, messages.
- `Config.SelfAnimations` : animations du menu ALT.
- `Config.VehicleCatalog` / `Config.WeaponCatalog` : catalogues du panel F6.

## Commandes développeur

Activables/désactivables via `Config.DevCommands`.

- `/ptfxtest <dict> <effet> [echelle]` : teste un effet de particules.
- `/tsunamiinfo` : progression du tsunami, distance, statut landfall.
- `/watertest <niveau>` / `/waterreset` / `/waterinfo` : teste la montée d'eau sans lancer l'event.
- `/animtest <dict> <clip>` : teste une animation avant de l'ajouter à `Config.SelfAnimations`.

## Points d'honnêteté technique à connaître

- Les noms d'assets de particules (`water_splash_ped_in`) et les animations
  du menu ALT sont des choix raisonnablement fiables mais **non testés en
  jeu de mon côté** — validez-les avec les commandes ci-dessus avant de
  compter dessus pour un event en production.
- Le mur visuel du tsunami est un `DrawMarker`, pas un modèle 3D custom :
  fiable et sans dépendance, mais moins détaillé qu'un asset dédié. C'est
  un choix assumé pour éviter la fragilité du mapping (Blender, collision,
  LOD) qu'on a abandonnée pour ce projet.
