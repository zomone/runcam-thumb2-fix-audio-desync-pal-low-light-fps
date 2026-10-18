# RunCam Thumb 2 : correction du décalage son / image en PAL (audio desync fix)

> **EN:** RunCam Thumb 2 (firmware V1.2.2): in **PAL** the audio slowly drifts out of sync with the video (about 1 ms per second, 1.8 s per 30 min), and the frame rate drops in the dark. Cause: the firmware labels PAL video as 50000/**1001** (49.95 fps) while the IMX586 sensor really runs at **50.000 fps**. This repo gives an `autoexec.ash` for the SD card that patches the table in RAM at every boot (no firmware flashing). It works in every PAL resolution, survives menu changes, and keeps the 50 Hz anti-flicker benefit of PAL. It also includes a lossless PC tool for already-recorded clips.

Mots-clés : RunCam Thumb 2, désynchronisation audio, son décalé, son en retard, audio drift, audio out of sync, PAL 50 fps, 49.95 fps, 1001, scintillement NTSC, chute de fps dans le noir, slow shutter, autoexec.ash, Ambarella S5L.

---

## Les symptômes

1. **Le son se décale petit à petit** de l'image, en PAL. Au début du rush tout est calé, puis l'écart grandit d'environ **1 ms par seconde** : 0,27 s au bout de 4 min 30, 1,8 s au bout de 30 min. Quand les rushs coupés à 4 Go sont recollés, l'écart continue de s'accumuler.
2. **Les images par seconde chutent dans le noir.** La caméra allonge le temps de pose (slow shutter), et la vidéo devient saccadée.
3. **Passer en NTSC règle le son, mais l'image scintille** sous les lumières à 50 Hz (en France ou en Europe, par exemple). Il faut donc rester en PAL.

## La cause (trouvée dans le firmware V1.2.2)

- En PAL, le capteur IMX586 filme à **50,000 images/s exactement** : 1728 MHz ÷ (10000 × 3456).
- Le firmware a une table des modes vidéo PAL. Dans **22 de ses lignes**, la cadence est notée **50000/1001**, soit 49,95 images/s, au lieu de 50000/1000. C'est le cas notamment du 2.7K (2688×1512) 50 i/s.
- Le fichier MP4 annonce donc 49,95 i/s, alors que les images arrivent à 50 i/s. L'image dure 0,1 % de trop par rapport au son, d'où l'écart d'environ 1 ms par seconde.
- En NTSC, le capteur tourne bien à 59,94 i/s, ce qui correspond à l'étiquette 60000/1001. C'est pour ça que le NTSC n'a pas de décalage.

## La solution : `camera/autoexec.ash`

À chaque démarrage, la caméra exécute le fichier `autoexec.ash` placé à la racine de la carte SD. **Le firmware n'est jamais modifié** : tout se passe en mémoire vive et s'efface à l'extinction. Sans la carte, la caméra redevient d'origine.

Le script fait trois choses :

1. **Il corrige la table PAL en mémoire** (22 commandes `writel ... 0x3e8`) : chaque 1001 faux devient 1000.
2. **Il relance l'image** vers 7 s (`t app test chg_enctype H264`). Au démarrage, la caméra a configuré l'image avant la correction. Cette relance la reconfigure avec la table corrigée, **en gardant la résolution de la dernière fois**. Elle passe par le même chemin que le menu.
3. **Il désactive le slow shutter** en boucle (`t imgproc -slowshutter 0 0`), pour que les images par seconde ne chutent plus dans le noir.

Résultat vérifié : le fichier sort en **50/1**, la durée de l'image et celle du son coïncident à quelques millisecondes près sur 4 minutes, les claps restent synchro du début à la fin, et ça marche aussi après un changement de résolution dans le menu, sans redémarrer.

### Installation

1. Copie `camera/autoexec.ash` à la **racine** de la carte SD, à côté du dossier `DCIM`.
2. Mets la caméra en **PAL**.
3. Allume la caméra et **attends environ 10 secondes avant d'enregistrer**. L'image « clignote » une fois vers 7 s : c'est la relance.

### À savoir

- ⚠️ **N'enregistre pas pendant les 10 premières secondes.** Une vidéo lancée avant la relance serait illisible. Pour la même raison, laisse « Enregistrement auto au démarrage » désactivé.
- Le script remet le codec en **H.264** à chaque démarrage.
- Les adresses mémoire valent **uniquement pour le firmware V1.2.2** (`Thumb2.bin`). Sur une autre version, n'utilise pas ce script tel quel.
- Pour revenir à la normale, il suffit de retirer `autoexec.ash` de la carte.
- La caméra date ses fichiers du 31/12/2023, et c'est normal : elle n'a pas de pile d'horloge. Scanner un QR code de l'appli RunCam remet l'heure, jusqu'à la prochaine coupure de courant.

## Les autres fichiers

| Fichier | À quoi il sert |
|---|---|
| `camera/autoexec.ash` | **La solution complète** : correction PAL dans toutes les résolutions, résolution de la dernière fois conservée, pas de chute de fps dans le noir. |
| `camera/variantes/autoexec_force_2k7.ash` | Même correction, mais la caméra démarre toujours en 2.7K50 (`t app test chg_res 70`, où 70 est le numéro de ligne dans la table PAL). Version de secours. |
| `camera/variantes/autoexec_capteur_2k7.ash` | Autre méthode : elle ralentit le capteur à 49,95 i/s pile pour coller à l'étiquette (`t sensor write 0 1 0x343 0x1a`, longueur de ligne 10000 → 10010). **Valable seulement en 2.7K50 PAL.** |
| `camera/variantes/autoexec_noir_seul.ash` | Seulement l'anti-chute de fps dans le noir, sans correction du son. |
| `pc/corriger_session.bat` + `.ps1` | Pour les **rushs déjà filmés** : glisse le dossier `DCIM\100MEDIA` sur le `.bat`. Il regroupe les rushs coupés à 4 Go en séances (tu peux choisir lesquels), les recolle et remet l'image à 50 i/s (`ffmpeg -itsscale 0.999000999`), **sans réencodage ni perte de qualité**. Nécessite ffmpeg. |
| `pc/corriger_son.bat` | Décale le son d'une valeur fixe en millisecondes (trouvée par exemple dans VLC), sans réencodage. |

## Ce qui ne marche pas (pour éviter de perdre du temps)

- **Le réglage « Fréquence 50/60 Hz »** ne change rien au scintillement en NTSC.
- **Modifier l'appli RunCam ne peut rien corriger.** Elle ne fait que générer un QR code avec 22 réglages du menu (2 chiffres chacun), et aucun ne touche à la cadence.
- `t app test chg_res 4` : l'argument est le **numéro de ligne dans la table**, pas le numéro du menu. La ligne 4 n'a pas de mode capteur, et la caméra redémarre en boucle. Si ça arrive, retire la carte.
- `t app test vf off` / `vf on` : provoque une erreur capteur (lumière verte qui clignote vite). Débranche puis rebranche l'alimentation pour en sortir.

## Avertissement

Ces scripts passent par des commandes de test du firmware Ambarella. Ils ne modifient pas la mémoire flash, mais tu les utilises à tes risques. Testé sur une RunCam Thumb 2 en firmware V1.2.2.
