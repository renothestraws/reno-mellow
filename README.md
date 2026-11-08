# ReNo Mellow – plugins gratuits pour REAPER

Collection de compresseurs, processeurs de dynamique et égaliseurs en JSFX pour REAPER.

## Dynamique

| Plugin | Description |
|---|---|
| **RM1176** | Compresseur/limiteur FET (inspiré du 1176) |
| **RM2A** | Leveler optique (inspiré du LA-2A) |
| **RM3A** | Leveler optique transistorisé (inspiré du LA-3A) |
| **RMEL8** | Compresseur de caractère (inspiré du Distressor) |
| **RMGbuss** | Compresseur de bus VCA (inspiré du bus SSL série G) |
| **RM160A** | Compresseur VCA à RMS vrai (inspiré du dbx 160A) |
| **RM670** | Limiteur stéréo variable-mu à lampes (inspiré du Fairchild 670) |
| **RM9000JDYN** | Dynamiques de tranche (inspirées de la SSL 9000J) |
| **RM33609** | Limiteur/compresseur à pont de diodes (inspiré du Neve 33609) |
| **RM1982** | Compresseur/expandeur original « à fenêtre » |

## Égaliseurs

| Plugin | Description |
|---|---|
| **RMeqp1A** | Égaliseur passif à lampes (inspiré du Pultec EQP-1A) |
| **RM1373** | Égaliseur de préampli classe A à 3 médiums (inspiré du Neve 1073) |
| **RM9000JEQ** | EQ et filtres de tranche (inspirés de la SSL 9000J) |
| **RMeq4** | Égaliseur 6 bandes à Air Band (inspiré du Maag EQ4) |
| **RM360** | Égaliseur graphique stéréo 2 x 30 bandes (inspiré du Klark Teknik DN360) |
| **RM550b** | Égaliseur 4 bandes à Q proportionnel (inspiré de l'API 550b) |
| **RMvioletQ** | Égaliseur passif stéréo de mastering (inspiré du Manley Massive Passive Mastering) |
| **RMdevilQ** | Égaliseur 4 bandes très coloré (inspiré du Chandler Little Devil) |
| **RMtownQ** | Égaliseur graphique passif 7 bandes (inspiré de l'EQ Motown) |
| **RM1982Q** | Égaliseur original à un bouton (courbes de Fletcher-Munson) |

Points communs : calibration 0 VU = +4 dBu = −18 dBFS, trim CALIB compensé en sortie,
interface redimensionnable (75 / 100 / 125 / 150 %), écrêteur de sécurité invisible à 0 dBFS.
Égaliseurs : aucune latence par défaut, bouton HQ (suréchantillonnage x2, 46 échantillons de latence).

## Installation avec ReaPack (recommandé)

1. Installer ReaPack si nécessaire : <https://reapack.com>
2. Dans REAPER : **Extensions > ReaPack > Import repositories...**
3. Coller l'adresse :
   ```
   https://raw.githubusercontent.com/renothestraws/reno-mellow/main/index.xml
   ```
4. **Extensions > ReaPack > Browse packages**, chercher « RM », clic droit > Install, puis Apply.

Les mises à jour arrivent ensuite automatiquement (Extensions > ReaPack > Synchronize packages).

## Installation manuelle

Copier les fichiers des dossiers `Dynamics` et `EQ` dans le dossier `Effects` de REAPER
(Options > Show REAPER resource path), puis rescanner les JSFX.

## Licence

Gratuit pour tout usage, y compris commercial.

Les noms de marques cités (1176, LA-2A, LA-3A, Distressor, SSL, dbx, Fairchild, Neve, Pultec,
Maag, Klark Teknik, API, Manley, Massive Passive, Chandler, Little Devil, Motown, MotorCity)
appartiennent à leurs propriétaires respectifs et servent uniquement à décrire l'inspiration
des plugins. ReNo Mellow n'est affilié à aucune de ces marques.
