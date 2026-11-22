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
| **RMMultidyn** | Compresseur / expandeur multibande transparent (6 bandes, crossovers 6-48 dB/oct, Mid/Side, side-chain 3/4 et 5/6, sorties séparées, analyseur) |
| **RM1982clip** | Clipper |
| **RM1982Gate** | Gate / expandeur (inspiré du FabFilter Pro-G) |
| **RM1982debleed** | Débleeder : gate/expandeur au-dessus d'un crossover |
| **RM1982De-ess** | De-esser (inspiré du FabFilter Pro-DS) |
| **RM1982Transient** | Transient designer |
| **RMtrancegate** | Gate programmable synchronisée au tempo (inspirée du Kilohearts Trance Gate) : 8 patterns de 1 à 32 pas avec liaisons, ADSR, résolution 1/2 à 1/64, mix, changement de pattern par MIDI |
| **RMsidekicker** | Shaper type sidechain / ducking (inspiré de Slate Digital Submerge) : sync ou Hz, déclenchement auto / MIDI / audio avec seuil et délai, formes Natural / Extreme / Special inversables, morph, depth, 8 effets (gain M/S, high / low duck, sample rate, HP, LP, HP+LP, HP-LP) avec tweak |

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
| **RMcleanEQ** | EQ précise et transparente inspirée du Pro-Q 3 : 10 bandes, cuts jusqu'à 96 dB/oct, Mid/Side, solo, analyseur |

## Couleur

| Plugin | Description |
|---|---|
| **RM1982REC** | Simulateur de supports d'enregistrement (cire, laque, bande 1/4", bande 2", numérique 16 bits, flottant) |
| **RM1982Bass** | Basse psycho-acoustique (harmoniques qui recréent la fondamentale) |
| **RM1982Pre** | Étage de préampli coloré : DRIVE + GAIN, 5 couleurs (1073, 512, 610, 4000, 32) |
| **RMdrumsat** | Saturation pour la batterie : couleur 4000 encadrée par une EQ miroir (low shelf 1 kHz −12 dB avant, +12 dB après) pour colorer les attaques sans faire baver le grave ; DRIVE à volume constant, GAIN, VU-mètres, crête-mètre, HQ |
| **RM1982Sum** | Couleur de bus de sommation : DRIVE + GAIN, 5 couleurs (80, 4000, 2448, 2B, 32) |
| **RM1982maximizer** | Sonic maximizer façon BBE : LOW CONTOUR + PROCESS (aigu dynamique piloté par CV), d'après Sonic Enhancer (GPL) |
| **RM1982Inflat** | Inflator (comportement du Sonnox Oxford Inflator, Band Split compris), d'après RCInflator 2 de lewloiwc / RCJacH |
| **RMfreqshifter** | Décaleur de fréquence sans latence (inspiré du Kilohearts Frequency Shifter) : ±5 kHz, réglage fin autour de 0 Hz, saisie au clavier, mix |

## Réverbération et multi-effet

| Plugin | Description |
|---|---|
| **RM90X** | Multi-effet numérique inspiré de la Yamaha SPX90II : les 30 programmes d'usine (réverbes calées sur des IR de l'appareil, early reflections, gate, delay, chorus, flanger, pitch, freeze…), mémoires 31 à 90, face avant opérationnelle, MIDI, traitement interne 31,25 kHz / 16 bits sans latence |

## MIDI

| Plugin | Description |
|---|---|
| **RMdrumhumanizer** | Humaniseur MIDI de batterie : vélocité et timing en trois groupes (Tight, Pocket, Loose), mode Laid Back (latence nulle) ou Rush (anticipation compensée) |
| **RMarpeggio** | Arpégiateur MIDI synchronisé au tempo : 11 modes (Up, Down, Converge, Random, Walk, As Played, Chord…), 1/1 à 1/32 pointés et triolets, 1 à 4 octaves, séquenceur 16 pas (niveau, liaisons, octave par pas), swing, humanize, latch, 14 presets d'usine et 8 mémoires utilisateur |

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
Écrêteur de sécurité invisible à 0 dBFS sur les clones (pas sur RM1982comp, RMMultidyn, RM1982Gain, RM1982Meter et RM1982REC,
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

**Couleur de l'interface :** sur tous les plug-ins dont l'interface a un accent orange, un double-clic sur le nom du plug-in bascule entre orange et vert (réglage mémorisé dans le projet, par instance).

## Installation individuelle (sans ReaPack)

Chaque plug-in existe aussi en paquet REAPER `.ReaperPkg` (un fichier par plug-in, Windows / macOS / Linux) : voir la liste des liens de téléchargement dans [packages/LIENS.md](packages/LIENS.md). Glisser le fichier téléchargé dans la fenêtre de REAPER pour l'installer.
