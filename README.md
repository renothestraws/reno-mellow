# ReNo Mellow – plugins gratuits pour REAPER

Collection de compresseurs, processeurs de dynamique, égaliseurs, effets de couleur, utilitaires et instruments en JSFX pour REAPER.

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
| **RM1982dynawindow** | Compresseur/expandeur original « à fenêtre » |
| **RM1982comp** | Compresseur polyvalent et transparent (FF/FB, 3 courbes d'attaque et de release, RMS, side-chain) |
| **RM1982clip** | Clipper |
| **RM1982Gate** | Gate / expandeur (inspiré du FabFilter Pro-G) |
| **RM1982debleed** | Débleeder : gate/expandeur au-dessus d'un crossover |
| **RM1982De-ess** | De-esser (inspiré du FabFilter Pro-DS) |
| **RM1982Transient** | Transient designer |

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
| **RM1982Fletcher** | Égaliseur original à un bouton (courbes de Fletcher-Munson) |

## Couleur

| Plugin | Description |
|---|---|
| **RM1982REC** | Simulateur de supports d'enregistrement (cire, laque, bande 1/4", bande 2", numérique 16 bits, flottant) |
| **RM1982Bass** | Basse psycho-acoustique (harmoniques qui recréent la fondamentale) |
| **RM1982Pre** | Étage de préampli coloré : DRIVE + GAIN, 5 couleurs (1073, 512, 610, 4000, 32) |
| **RM1982Sum** | Couleur de bus de sommation : DRIVE + GAIN, 5 couleurs (80, 4000, 2448, 2B, 32) |

## Instruments

| Plugin | Description |
|---|---|
| **RMdrumachine** ([manuel PDF](Instruments/RMdrumachine/RMdrumachine_Manual.pdf)) | Boîte à rythmes 16 pads avec 4 kits fournis, 8 motifs, step séquenceur (accent, ghost, découpe des pas, swing, play style), MIDI et CV, 8 sorties |
| **RMoneshot** | Lecteur one-shot intelligent (snare, kick) : la vélocité, le hasard et le rythme de jeu font varier niveau, timbre, résonance et pitch d'un seul sample |

## Utilitaires

| Plugin | Description |
|---|---|
| **RM1982Gain** | Étage de gain avec VU-mètre RMS calibrable et crête-mètre |
| **RM1982Trig** | Trigger to MIDI (transitoires audio -> notes MIDI) |
| **RM1982Meter** | Mètre crête / RMS / plage dynamique avec seuils de couleur réglables |
| **RM1982gen** | Tone gate : générateur (sinus, carré, scie, bruit rose / blanc) déclenché par l'entrée, avec glissement de pitch |

Points communs : calibration 0 VU = +4 dBu = −18 dBFS, trim CALIB compensé en sortie,
interface redimensionnable (75 / 100 / 125 / 150 %), interface en anglais.
Écrêteur de sécurité invisible à 0 dBFS sur les clones (pas sur RM1982comp, RM1982Gain, RM1982Meter et RM1982REC,
qui restent sans clipper interne).
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

Copier les fichiers des dossiers `Dynamics`, `EQ`, `Color`, `Utility` et `Instruments` dans le dossier `Effects` de REAPER
(Options > Show REAPER resource path), puis rescanner les JSFX.
Pour les sons par défaut du RMdrumachine, copier aussi le dossier `Instruments/RMdrumachine`
(les 4 dossiers de kits et le fichier de noms de notes) dans le dossier `Data` de REAPER : `Data/RMdrumachine/Doves/01_kick.ogg`, etc.

## Licence

Gratuit pour tout usage, y compris commercial.

Les noms de marques cités (1176, LA-2A, LA-3A, Distressor, SSL, dbx, Fairchild, Neve, Pultec,
Maag, Klark Teknik, API, Manley, Massive Passive, Chandler, Little Devil, Motown, MotorCity,
FabFilter, Pro-G, Pro-DS)
appartiennent à leurs propriétaires respectifs et servent uniquement à décrire l'inspiration
des plugins. ReNo Mellow n'est affilié à aucune de ces marques.
