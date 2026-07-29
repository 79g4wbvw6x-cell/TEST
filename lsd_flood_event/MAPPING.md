# Créer le barrage éventré — guide de mapping

Objectif : obtenir un prop de barrage de Land Act **cassé**, avec une vraie
brèche traversable par l'eau, à brancher dans `Config.Rupture.modelSwap`.

> ⚠️ Avant de commencer : la moitié de ce guide dépend de ce que le barrage
> **est réellement** dans les fichiers du jeu. L'étape 1 sert à le déterminer.
> Ne saute pas cette étape, elle décide de tout le reste.

---

## Étape 0 — Les outils

| Outil | Rôle | Où |
|---|---|---|
| **CodeWalker** | Explorer la map, trouver le barrage, éditer/créer des ymap | github.com/dexyfex/CodeWalker |
| **Blender** (3.x ou 4.x) | Modéliser la brèche | blender.org |
| **Sollumz** | Addon Blender : import/export YDR, YBN, YMAP | github.com/Sollumz/Sollumz |
| **OpenIV** *(optionnel)* | Explorer les RPF du jeu | openiv.com |

Vérifie bien la **compatibilité de version entre Blender et Sollumz** — c'est
la source n°1 de "ça ne s'importe pas". Sollumz indique la version de Blender
supportée sur sa page.

---

## Étape 1 — Identifier ce qu'est le barrage (DIAGNOSTIC)

### 1a. En jeu
Lance le serveur, va au barrage, vise-le et tape :

```
/damscan
```

Deux résultats possibles :

- **"Modèle visé : <hash>"** → c'est une **entité**. Cas facile. Note le hash.
- **"Aucune entité : géométrie de map pure"** → cas plus lourd, il faudra
  remplacer le fichier de map d'origine (étape 5b).

### 1b. Dans CodeWalker
1. Ouvre CodeWalker → `World` → charge la map.
2. Barre de recherche de position : va aux coordonnées `2645, 3474, 94`.
3. Active le mode sélection (`Select` dans la toolbar), clique sur le barrage.
4. Le panneau de droite t'affiche :
   - **Archetype / Name** → le nom du modèle (ex. quelque chose comme `dam_...`)
   - **Ymap** → le fichier de map qui le place
   - **Position / Rotation** → à noter précieusement, tu en auras besoin

**Note ces 4 informations, tout le reste en dépend.**

Le barrage est probablement découpé en **plusieurs morceaux** (mur, crête,
piliers, vannes). Tu n'as besoin de casser **que le morceau où tu veux la
brèche** — pas tout le barrage. Repère celui qui est au niveau de
`Config.Dam.breach.coords`.

---

## Étape 2 — Exporter le modèle d'origine

Dans CodeWalker :
1. Sélectionne le morceau à casser.
2. Trouve son `.ydr` dans le RPF (CodeWalker → `RPF Explorer` → recherche par
   le nom d'archetype trouvé en 1b).
3. Clic droit → **Extract / Export** le `.ydr`.
4. Exporte aussi le `.ybn` correspondant (la collision) si tu le trouves —
   il porte souvent un nom proche.

---

## Étape 3 — Modéliser la brèche dans Blender

1. Blender → `File > Import > Sollumz > YDR`.
2. Importe le `.ydr` du morceau de barrage.
3. Crée la brèche. La méthode propre :
   - Ajoute un cube, place-le à l'endroit de la brèche, dimensionne-le
     (une brèche crédible fait ~15-25 m de large sur toute la hauteur).
   - Sur le mesh du barrage : `Modifier > Boolean`, opération **Difference**,
     objet = ton cube. Applique le modifier.
   - Le trou est net et carré → **c'est moche**. Casse les bords : mode Édition,
     sélectionne les arêtes du trou, `Bevel` léger + déplace quelques vertices
     à la main pour un bord irrégulier de béton arraché.
4. **Les faces intérieures** : après un boolean, l'intérieur du mur est ouvert
   et sans texture. Sélectionne ces faces et assigne-leur un matériau de béton
   (récupère-en un du modèle d'origine). Sinon tu verras à travers le mur.
5. Optionnel mais ça change tout visuellement : ajoute des **fers à béton**
   tordus qui dépassent (quelques cylindres fins courbés) et des blocs de
   béton détachés au pied de la brèche.

### Export
- Renomme l'objet racine Sollumz avec un nom **unique** : `lsd_dam_broken`
  (pas le nom d'origine — sinon tu écrases le barrage intact partout).
- `File > Export > Sollumz > YDR`.

---

## Étape 4 — La collision (PIÈGE N°1)

**Si tu ne fais que le modèle visuel, les joueurs se cogneront dans un mur
invisible au milieu de ta brèche.** La collision est un fichier séparé (`.ybn`)
ou embarquée dans le YDR, et elle n'est pas modifiée par ton boolean.

Il faut donc :
1. Dans Blender, importe le `.ybn` d'origine (`Import > Sollumz > YBN`).
2. Applique-lui **le même boolean** que sur le mesh visuel (même cube).
3. Exporte-le en `.ybn` avec un nom cohérent.

Vérification en jeu : marche dans la brèche. Si tu es bloqué par du vide, la
collision n'a pas été remplacée.

> Astuce de secours si tu galères sur la collision : la native
> `CreateModelHide` du script masque **modèle ET collision** ensemble. Tu peux
> masquer le morceau d'origine (visuel + collision partis) et poser ton prop
> cassé par-dessus. Deux fichiers à gérer en moins.

---

## Étape 5 — Streamer dans la ressource

### 5a. Cas facile (le barrage est une entité)
1. Crée un dossier `stream/` dans `lsd_flood_event/`.
2. Mets-y `lsd_dam_broken.ydr` (+ `.ybn` si tu en as un).
3. Ajoute dans `fxmanifest.lua` :
   ```lua
   files { 'stream/**' }
   ```
   (en réalité le dossier `stream/` est détecté automatiquement par FiveM,
   mais garde une structure propre)
4. Redémarre le serveur.

### 5b. Cas lourd (géométrie de map pure)
Là il faut **remplacer le ymap d'origine** :
1. Dans CodeWalker, ouvre le ymap identifié en 1b.
2. Supprime l'entité du barrage intact (ou change son archetype vers le tien).
3. Ajoute une entité pointant sur `lsd_dam_broken`, à la position/rotation
   notées en 1b.
4. Sauvegarde le ymap **sous le même nom que l'original**.
5. Mets-le dans `stream/` — FiveM donne priorité à ta version sur celle du jeu.

⚠️ Un ymap qui écrase un ymap de base peut casser d'autres objets de la zone
si tu supprimes plus que prévu. Fais une sauvegarde de l'original avant.

---

## Étape 6 — Les LOD (PIÈGE N°2)

Tu vas tester, ça marchera de près... et de loin le barrage sera **de nouveau
intact**. C'est normal : GTA affiche un modèle basse définition (LOD) au-delà
d'une certaine distance, et tu ne l'as pas modifié.

Solutions, par ordre de simplicité :
1. **Augmenter la lodDist** de ton archetype dans CodeWalker pour que le modèle
   HD reste affiché plus loin (suffisant dans beaucoup de cas).
2. **Modifier aussi le modèle LOD** (même boolean, en plus grossier).
3. **Masquer le LOD** via le ymap parent (`_lod.ymap`).

Pour un event ponctuel, l'option 1 est largement suffisante.

---

## Étape 7 — Brancher dans le script

Une fois ton prop en jeu, dans `shared/config.lua` :

```lua
modelSwap = {
    enabled   = true,
    srcModel  = 'nom_archetype_dorigine',  -- trouvé à l'étape 1b
    dstModel  = 'lsd_dam_broken',          -- ton prop
    radius    = 60.0
},
```

Puis ajuste la brèche pour que le torrent sorte pile du trou :

```lua
breach = {
    coords  = vector3(?, ?, ?),  -- /damscan en visant le centre de ta brèche
    heading = ?,                 -- direction de projection de l'eau
    width   = 18.0               -- largeur réelle de ton trou
}
```

Teste avec `/startflood`, puis affine `width` et `Config.Rupture.ptfx.scale`.

---

## Alternative sans Blender

Si tu ne veux pas modéliser : on peut simuler l'effondrement en **plaçant des
props existants du jeu** (blocs de béton, gravats, débris) par script au pied
du barrage, combinés à `CreateModelHide` pour masquer le morceau intact.

Rendu moins net qu'un vrai modèle cassé, mais :
- zéro Blender, zéro export
- aucun problème de collision ni de LOD
- réversible instantanément à la fin de l'event

Dis-moi si tu veux que je code cette version — c'est ~80 lignes et ça te donne
un résultat correct tout de suite, que tu pourras remplacer plus tard par ton
vrai modèle sans rien changer d'autre.
