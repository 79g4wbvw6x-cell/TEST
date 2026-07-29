#!/usr/bin/env python3
"""
Génère les variantes de water.xml utilisées pour la montée d'eau.

Principe : GTA V définit son eau dans water.xml (une liste de quads avec
une hauteur z). Les natives SetWaterQuadLevel modifient ces données en
mémoire mais ne forcent pas le re-rendu de l'eau. En revanche, la native
LoadWaterFromPath recharge un water.xml complet et applique le résultat
immédiatement.

On pré-génère donc un fichier par palier de hauteur, et le script client
charge le palier correspondant au niveau de crue courant.

USAGE
-----
    python3 generate_water_levels.py chemin/vers/water.xml

    # paliers personnalisés (min, max, pas) :
    python3 generate_water_levels.py water.xml --min 0 --max 60 --step 2

Les fichiers sont écrits dans ../stream/ sous la forme water_lvl_XX.xml
(XX = hauteur, deux chiffres). Le script affiche ensuite la liste des
paliers à recopier dans Config.Water.levels.
"""

import argparse
import os
import re
import sys

# Balises de hauteur rencontrées dans water.xml. On les traite toutes :
# selon la version du fichier, la hauteur est portée par <z> et/ou par des
# attributs value sur les items de quad.
Z_TAG_RE = re.compile(r'(<z[^>]*>)([^<]*)(</z>)', re.IGNORECASE)
Z_ATTR_RE = re.compile(r'(<z\s+value=")([^"]*)(")', re.IGNORECASE)


def retarget(xml: str, level: float) -> str:
    """Réécrit toutes les hauteurs de quad à `level`."""
    txt, n1 = Z_TAG_RE.subn(lambda m: f'{m.group(1)}{level:.6f}{m.group(3)}', xml)
    txt, n2 = Z_ATTR_RE.subn(lambda m: f'{m.group(1)}{level:.6f}{m.group(3)}', txt)
    return txt, n1 + n2


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('source', help='water.xml extrait du jeu')
    ap.add_argument('--min', type=float, default=0.0)
    ap.add_argument('--max', type=float, default=60.0)
    ap.add_argument('--step', type=float, default=2.0)
    ap.add_argument('--out', default=None, help='dossier de sortie (defaut: ../stream)')
    args = ap.parse_args()

    if not os.path.isfile(args.source):
        print(f'ERREUR: fichier introuvable: {args.source}')
        return 1

    with open(args.source, 'r', encoding='utf-8', errors='replace') as fh:
        base = fh.read()

    _, found = retarget(base, 0.0)
    if found == 0:
        print('ERREUR: aucune hauteur <z> trouvee dans ce fichier.')
        print("Verifiez qu'il s'agit bien du water.xml de GTA V, converti en XML.")
        return 1
    print(f'{found} hauteurs de quad detectees dans {os.path.basename(args.source)}')

    out_dir = args.out or os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'stream')
    out_dir = os.path.abspath(out_dir)
    os.makedirs(out_dir, exist_ok=True)

    levels = []
    lvl = args.min
    while lvl <= args.max + 1e-9:
        content, _ = retarget(base, lvl)
        name = f'water_lvl_{int(round(lvl)):02d}.xml'
        with open(os.path.join(out_dir, name), 'w', encoding='utf-8') as fh:
            fh.write(content)
        levels.append(int(round(lvl)))
        lvl += args.step

    print(f'{len(levels)} fichiers ecrits dans {out_dir}')
    print()
    print('--- a recopier dans shared/config.lua ---')
    print('    levels = { ' + ', '.join(str(v) for v in levels) + ' },')
    print()
    print('--- a verifier dans fxmanifest.lua ---')
    print("    files { 'stream/water_lvl_*.xml' }")
    return 0


if __name__ == '__main__':
    sys.exit(main())
