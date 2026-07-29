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

## Trouver la bonne configuration d'eau (IMPORTANT — à faire avant tout)

Le premier test a montré une eau "en l'air", sans volume, visible seulement
près des plages : ça vient des flags de quad (`NoStencil`, `Type`, alpha)
que GTA utilise pour décider où l'eau peut réellement s'afficher au-dessus
du terrain. Je ne peux pas connaître la bonne combinaison sans tester en
jeu, donc `tools/generate_water_levels.py` génère maintenant 6 variantes de
diagnostic (`stream/water_var_v1.xml` à `v6`), toutes à 30m de haut.

**Faites ça en premier :**

```
/watervariant v1
```

Regardez le résultat (volume sous la surface ? eau en ville ou juste aux
plages ?), puis testez `v2`, `v3`, etc. Notez laquelle donne une vraie nappe
d'eau qui recouvre le terrain avec du volume dessous.

Une fois la bonne variante identifiée, régénérez tous les paliers avec :

```
python3 tools/generate_water_levels.py water.xml --variant v3
```

(remplacez `v3` par celle qui a marché), puis recopiez la ligne `levels = {...}`
affichée dans `Config.Water.levels`.

## La rupture du barrage — ce qui est possible, et ce qui ne l'est pas

**Le barrage de Land Act ne peut pas être réellement détruit par script.**
C'est de la géométrie de map statique : aucune native ne permet de la casser,
de la déformer ou d'y percer un trou en runtime. Toute ressource qui prétend
le contraire fait en réalité l'une des trois choses ci-dessous.

Ce script combine les trois pour obtenir l'illusion la plus convaincante
possible :

### 1. Explosions en cascade (`Config.Rupture.explosions`)
5 charges déclenchées en séquence sur la crête, avec secousse de caméra et
vibration manette **ressenties dans toute la ville**, atténuées avec la
distance. C'est le moment "le barrage vient de céder". Fonctionne
immédiatement, sans aucun asset.

### 2. Effondrement visuel (`modelSwap` / `modelHide`) — **désactivé par défaut**
Deux options, toutes deux à activer manuellement :

- **`modelHide`** : masque un morceau du barrage avec `CreateModelHide`, ce
  qui crée un trou visuel par lequel le torrent jaillit. Ne nécessite aucun
  asset — mais ne fonctionne **que si le morceau visé est une entité**, pas
  de la géométrie baked.
- **`modelSwap`** : remplace le barrage intact par une version éventrée avec
  `CreateModelSwap`. **Nécessite votre propre prop de barrage cassé** streamé
  dans la ressource. C'est la seule méthode qui donne un vrai rendu "béton
  arraché". Un modeleur 3D ou un asset payant est requis ici.

👉 **Pour créer le prop de barrage cassé, suivez [MAPPING.md](MAPPING.md)** —
guide pas à pas (CodeWalker, Blender/Sollumz, collision, LOD, streaming).

**Comment savoir laquelle marche chez vous** : en jeu, visez le barrage et
tapez `/damscan`. La console vous dira si vous visez une entité (→ hide/swap
possible, le hash est affiché) ou de la géométrie de map pure (→ il faut un
override de ymap/ydr streamé).

### 3. Le torrent + la vague déferlante
- **Torrent permanent** : des émetteurs de particules répartis sur la largeur
  de la brèche (`Config.Dam.breach.width`), créés uniquement quand un joueur
  est à portée et détruits dès qu'il s'éloigne → zéro coût FPS en ville.
- **Vague déferlante** : un front d'eau qui voyage du barrage jusqu'à Rancho
  en suivant `Config.Rupture.wave.path` (3 min par défaut). Les joueurs pris
  dedans sont **ragdollés**, et les véhicules **projetés** par une force
  physique. Sa position est calculée depuis l'horodatage serveur partagé,
  donc tout le monde la voit au même endroit au même instant — y compris un
  joueur qui se connecte en pleine crue.

### Valider les ptfx ⚠️
Les noms d'assets de particules dans `Config.Rupture.ptfx` sont des
**candidats à vérifier en jeu** — je ne peux pas garantir de mémoire qu'un
couple dict/effet existe dans votre build. Utilisez la commande fournie :

```
/ptfxtest core water_splash_ped_in 6.0
```

Elle joue l'effet à vos pieds pendant 10s et affiche OK ou Échec en console.
Testez plusieurs candidats, gardez le plus impressionnant, et reportez-le
dans `Config.Rupture.ptfx`. Quelques pistes à essayer : `water_splash_ped_in`,
`water_splash_veh_in`, `ent_amb_waterfall`.

## Configuration

Tout se règle dans `shared/config.lua` :
- `Config.Phases` : durée de chaque phase.
- `Config.WaterLevel` : niveau de base et niveau max de la crue.
- `Config.FloodZones` : quartiers touchés (centre + rayon) pour les dégâts et blips.
- `Config.EvacPoints` : points hauts sûrs affichés sur la carte.
- `Config.Survival` : intervalle de vérification, dégâts, tolérance de submersion.
- `Config.Dam.breach` : position/orientation/largeur de la brèche (réglez avec `/damscan`).
- `Config.Rupture` : explosions, effondrement, particules, trajet et impact de la vague.

## Commandes développeur

Activables/désactivables via `Config.DevCommands`.

- `/damscan` : affiche vos coordonnées, le point visé et le modèle sous le
  viseur. Sert à régler la brèche et à identifier le modèle du barrage.
- `/ptfxtest <dict> <effet> [echelle]` : teste un effet de particules.
