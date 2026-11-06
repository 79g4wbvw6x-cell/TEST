# Studio vert sapin : visite 3D

Le studio de 16 m² rénové, modélisé en 3D avec three.js.

- `index.html` : la scène 3D. Elle propose une visite automatique, une balade libre et une vue maquette avec les cotes.
- `render.cjs` : exporte la visite image par image avec Playwright. Usage : `node render.cjs frames 720 1280 25`, puis assembler les images avec ffmpeg.
- `visite-vert-sapin.mp4` : la vidéo de la visite.

Les dimensions sont estimées à partir de la vidéo et des photos. Elles sont définies en haut du script (`W`, `L`, `H`, etc.) et sont à remplacer par les vraies mesures.
