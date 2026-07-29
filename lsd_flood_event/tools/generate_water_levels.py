#!/usr/bin/env python3
"""
Génère les variantes de water.xml utilisées pour la montée d'eau.

POURQUOI CE SCRIPT
------------------
GTA V définit son eau dans water.xml : une liste de quads rectangulaires
(minX/maxX/minY/maxY) portant chacun une hauteur z.

Deux pièges que ce script contourne :

 1. Les natives SetWaterQuadLevel modifient les quads en mémoire mais ne
    forcent aucun re-rendu : l'eau reste affichée à sa hauteur d'origine.
    Seul LoadWaterFromPath, qui recharge un water.xml complet, met à jour
    l'affichage. D'où la pré-génération d'un fichier par palier.

 2. Les quads d'origine ne couvrent QUE les zones déjà aquatiques. Relever
    leur z fait monter l'eau uniquement à l'intérieur de ces rectangles —
    donc rien au-dessus de la ville. Pour inonder Los Santos il faut créer
    de nouveaux quads couvrant les terres.

Ce script génère donc, pour chaque palier, une grille de quads couvrant
toute la carte à la hauteur voulue. Le terrain fait le reste : les points
bas disparaissent sous l'eau, les hauteurs émergent.

USAGE
-----
    python3 generate_water_levels.py water.xml
    python3 generate_water_levels.py water.xml --min 0 --max 80 --step 2

Le script affiche la liste des paliers à recopier dans Config.Water.levels.
"""

import argparse
import os
import re
import sys

# Emprise de la carte jouable, déduite des quads d'origine avec une marge.
MAP_MIN_X, MAP_MAX_X = -4200.0, 4700.0
MAP_MIN_Y, MAP_MAX_Y = -4200.0, 8200.0

QUAD_TEMPLATE = """    <Item>
      <minX value="{minx:.0f}" />
      <maxX value="{maxx:.0f}" />
      <minY value="{miny:.0f}" />
      <maxY value="{maxy:.0f}" />
      <Type value="0" />
      <IsInvisible value="false" />
      <HasLimitedDepth value="false" />
      <z value="{z:.3f}" />
      <a1 value="26" />
      <a2 value="26" />
      <a3 value="26" />
      <a4 value="26" />
      <NoStencil value="false" />
    </Item>
"""


def extract_section(xml: str, tag: str) -> str:
    """Retourne le contenu brut d'une section, ou '' si absente."""
    m = re.search(rf'<{tag}>(.*?)</{tag}>', xml, re.DOTALL)
    return m.group(1) if m else ''


def build_grid(level: float, cell: float) -> str:
    """Grille de quads couvrant la carte à la hauteur `level`."""
    out = []
    y = MAP_MIN_Y
    while y < MAP_MAX_Y:
        x = MAP_MIN_X
        y2 = min(y + cell, MAP_MAX_Y)
        while x < MAP_MAX_X:
            x2 = min(x + cell, MAP_MAX_X)
            out.append(QUAD_TEMPLATE.format(minx=x, maxx=x2, miny=y, maxy=y2, z=level))
            x = x2
        y = y2
    return ''.join(out)


def build_file(level: float, cell: float, calming: str, waves: str) -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<WaterData>\n'
        '  <WaterQuads>\n'
        f'{build_grid(level, cell)}'
        '  </WaterQuads>\n'
        f'  <CalmingQuads>{calming}</CalmingQuads>\n'
        f'  <WaveQuads>{waves}</WaveQuads>\n'
        '</WaterData>\n'
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('source', help='water.xml extrait du jeu (common.rpf/data/levels/gta5)')
    ap.add_argument('--min', type=float, default=0.0)
    ap.add_argument('--max', type=float, default=80.0)
    ap.add_argument('--step', type=float, default=2.0)
    ap.add_argument('--cell', type=float, default=1000.0,
                    help='taille des quads de la grille (defaut 1000)')
    ap.add_argument('--out', default=None)
    args = ap.parse_args()

    if not os.path.isfile(args.source):
        print(f'ERREUR: fichier introuvable: {args.source}')
        return 1

    with open(args.source, 'r', encoding='utf-8', errors='replace') as fh:
        base = fh.read()

    if '<WaterQuads>' not in base:
        print("ERREUR: pas de section <WaterQuads>. Est-ce bien le water.xml de GTA V ?")
        return 1

    n_base = base.count('<z value=')
    calming = extract_section(base, 'CalmingQuads')
    waves = extract_section(base, 'WaveQuads')
    print(f'{n_base} quads d\'eau lus dans {os.path.basename(args.source)}')
    print(f'CalmingQuads et WaveQuads d\'origine preserves')

    out_dir = args.out or os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'stream')
    out_dir = os.path.abspath(out_dir)
    os.makedirs(out_dir, exist_ok=True)

    n_grid = len(build_grid(0.0, args.cell).strip().split('</Item>')) - 1
    print(f'Grille: {n_grid} quads de {args.cell:.0f}x{args.cell:.0f} par palier')

    levels = []
    lvl = args.min
    while lvl <= args.max + 1e-9:
        name = f'water_lvl_{int(round(lvl)):02d}.xml'
        with open(os.path.join(out_dir, name), 'w', encoding='utf-8') as fh:
            fh.write(build_file(lvl, args.cell, calming, waves))
        levels.append(int(round(lvl)))
        lvl += args.step

    print(f'\n{len(levels)} fichiers ecrits dans {out_dir}')
    print('\n--- a recopier dans shared/config.lua ---')
    print('    levels = { ' + ', '.join(str(v) for v in levels) + ' },')
    return 0


if __name__ == '__main__':
    sys.exit(main())
