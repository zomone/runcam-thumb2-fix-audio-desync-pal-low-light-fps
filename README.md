# RunCam Thumb 2 : correction du son décalé en PAL et de la chute de fps dans le noir (audio desync + low-light FPS fix)

🇫🇷 [Français](#-français) · 🇬🇧 [English](#-english)

---

## 🇫🇷 Français

### Les problèmes

1. **Le son se décale en PAL.** L'écart grandit d'environ 1 ms par seconde, soit environ 1,8 s au bout de 30 min.
2. **La vidéo saccade dans le noir.** La caméra allonge le temps de pose (« slow shutter ») et répète des images.

### Les causes

- **Son :** en PAL, le capteur filme à **50,000 i/s**, mais le firmware V1.2.2 indique dans le fichier **50000/1001**, soit 49,95 i/s. Cette erreur se trouve dans 22 modes de sa table PAL, dont le 2.7K50. L'image dure donc 0,1 % de trop par rapport au son.
- **Noir :** le firmware active le slow shutter dès que la cadence dépasse 30 i/s. Le temps de pose peut alors dépasser la durée d'une image, et le capteur ne fournit plus 50 images différentes par seconde.

### La solution : `autoexec.ash`

La caméra exécute ce fichier à chaque démarrage. **Le firmware n'est pas modifié** : tout se fait en mémoire vive et s'efface à l'extinction.

1. Il corrige la table PAL en mémoire (1001 → 1000).
2. Il relance l'image vers 7 s, **sans changer la résolution**, pour qu'elle reparte avec la table corrigée.
3. Il modifie en mémoire l'instruction qui active le slow shutter, pour que celui-ci reste toujours désactivé.

Résultat : des fichiers en **50/1** où le son reste calé du début à la fin, dans toutes les résolutions PAL, même si tu changes de réglage sans redémarrer.

### Installation

Copie `autoexec.ash` **directement à la racine de la carte SD**, au même niveau que le dossier `DCIM`, et pas dans un sous-dossier :

```
Carte SD
├── DCIM
├── autoexec.ash      ← ici
└── RunCamThumb2.ini
```

Ensuite :

1. Mets la caméra en **PAL**.
2. Allume-la, puis **attends environ 10 s avant d'enregistrer**. L'image clignote une fois : c'est la relance.

### À savoir

- ⚠️ Une vidéo lancée pendant les 10 premières secondes sera illisible. Laisse donc « Enregistrement auto au démarrage » désactivé.
- Le codec est remis en H.264 à chaque démarrage.
- Les adresses mémoire du script valent **uniquement pour le firmware V1.2.2**.
- Pour revenir à la normale, retire `autoexec.ash` de la carte.
- Dans le noir, l'image est un peu plus sombre ou bruitée, mais elle reste fluide.
- Les fichiers sont datés de 2023 parce que la caméra n'a pas de pile d'horloge : elle perd l'heure à chaque coupure de courant.

### ⚠️ Firmware modifié (jamais testé)

Le dossier `firmware-UNTESTED-NON-TESTE/` contient `Thumb2_V1.2.2_patched_UNTESTED.bin`, le firmware officiel V1.2.2 dans lequel les deux corrections de `autoexec.ash` sont écrites directement. S'il fonctionne, il supprime l'attente de 10 s et permet de formater la carte sans perdre la correction.

- **Il n'a jamais été flashé ni testé sur aucune caméra.** Seules les corrections en mémoire vive (`autoexec.ash`) ont été testées.
- Un contrôle du fichier (le mot à l'adresse `0x20`) n'a pas pu être identifié. La caméra peut donc refuser le fichier ou ne plus démarrer.
- **Le flasher est entièrement à tes risques.** Si ta caméra ne fonctionne plus, c'est ta responsabilité, pas celle de l'auteur. Aucune aide ni garantie.
- Dans le doute, utilise `autoexec.ash`, qui donne le même résultat sans risque. Lis le README du dossier avant de faire quoi que ce soit.

### Les autres fichiers

| Fichier | Rôle |
|---|---|
| `autoexec.ash` | **La solution complète** : son + noir. |
| `low-light-only/autoexec.ash` | Seulement la correction du noir, en une seule ligne : valable dans toutes les résolutions, en PAL comme en NTSC, sans relance ni délai de 10 s. À copier aussi à la racine de la carte, à la place de l'autre. |
| `firmware-UNTESTED-NON-TESTE/` | ⚠️ **Firmware modifié JAMAIS TESTÉ**, construit à partir des corrections de `autoexec.ash`. Le flasher est **à tes risques et sous ta responsabilité** : si la caméra ne fonctionne plus, c'est de ta faute. Lis son README avant tout. |
| `pc/corriger_session.bat` | Pour les **vidéos déjà filmées** : glisse le dossier `DCIM\100MEDIA` dessus. Il recolle les rushs coupés à 4 Go et remet l'image à 50 i/s, sans réencodage. Nécessite ffmpeg. |
| `pc/corriger_son.bat` | Décale le son d'une valeur fixe en ms, sans réencodage. |

### Ce qui ne marche pas

- Le réglage « Fréquence 50/60 Hz » n'enlève pas le scintillement du NTSC.

### 💬 Un retour serait cool !

Tu as testé ? Que ça marche ou pas, ton retour aide les autres. Sur GitHub, ça passe par une **Issue** :

1. En haut de la page du dépôt, clique sur l'onglet **Issues**, puis sur **New issue**.
2. Choisis **Retour de test / Test report** et remplis le petit formulaire : version du firmware, fichier testé, résolution, résultat.
3. Clique sur **Submit new issue**.

Il faut un compte GitHub, qui est gratuit.

---

## 🇬🇧 English

### The problems

1. **Audio drifts out of sync in PAL.** The gap grows by about 1 ms per second, roughly 1.8 s after 30 min.
2. **Video stutters in the dark.** The camera lengthens the exposure ("slow shutter") and repeats frames.

### The causes

- **Audio:** in PAL the sensor records at **50.000 fps**, but firmware V1.2.2 writes **50000/1001** (49.95 fps) into the file. The error is in 22 modes of its PAL table, including 2.7K50. The video therefore runs 0.1 % longer than the audio.
- **Dark:** the firmware enables slow shutter whenever the frame rate is above 30 fps. The exposure can then exceed one frame, and the sensor no longer delivers 50 distinct frames per second.

### The fix: `autoexec.ash`

The camera runs this file at every boot. **The firmware is not modified**: everything happens in RAM and is cleared at power-off.

1. It patches the PAL table in RAM (1001 → 1000).
2. It restarts the video pipeline at about 7 s, **keeping the current resolution**, so it picks up the patched table.
3. It patches in RAM the instruction that enables slow shutter, so it always stays off.

Result: **50/1** files with audio in sync from start to end, in every PAL resolution, even after you change settings without rebooting.

### Installation

Copy `autoexec.ash` **straight to the root of the SD card**, next to the `DCIM` folder, not into a subfolder:

```
SD card
├── DCIM
├── autoexec.ash      ← here
└── RunCamThumb2.ini
```

Then:

1. Set the camera to **PAL**.
2. Power it on and **wait about 10 s before recording**. The image blinks once: that is the restart.

### Good to know

- ⚠️ A recording started during the first 10 seconds will be unreadable, so keep "Auto recording on startup" off.
- The codec is set back to H.264 at every boot.
- The memory addresses in the script are valid **for firmware V1.2.2 only**.
- To go back to stock, remove `autoexec.ash` from the card.
- In the dark the image is slightly darker or noisier, but it stays smooth.
- Files are dated 2023 because the camera has no clock battery: it loses the time at every power cut.

### ⚠️ Modified firmware (never tested)

The `firmware-UNTESTED-NON-TESTE/` folder contains `Thumb2_V1.2.2_patched_UNTESTED.bin`, the official V1.2.2 firmware with both `autoexec.ash` fixes written directly into it. If it works, it removes the 10 s wait and lets you format the card without losing the fix.

- **It has never been flashed or tested on any camera.** Only the RAM fixes (`autoexec.ash`) were tested.
- One check in the file (the word at offset `0x20`) could not be identified, so the camera may reject the file or stop booting.
- **Flashing it is entirely at your own risk.** If your camera stops working, it is your responsibility, not the author's. No support, no warranty.
- When in doubt, use `autoexec.ash`, which gives the same result with no risk. Read the folder's README before doing anything.

### Other files

| File | Purpose |
|---|---|
| `autoexec.ash` | **The complete fix**: audio + dark. |
| `low-light-only/autoexec.ash` | Dark fix only, in a single line: every resolution, PAL or NTSC, no restart and no 10 s delay. Also goes to the root of the card, replacing the other one. |
| `firmware-UNTESTED-NON-TESTE/` | ⚠️ **Modified firmware, NEVER TESTED**, built from the `autoexec.ash` fixes. Flashing it is **at your own risk and your own responsibility**: if the camera stops working, it is your fault. Read its README first. |
| `pc/corriger_session.bat` | For **clips already recorded**: drag the `DCIM\100MEDIA` folder onto it. It joins the clips split at 4 GB and restores 50 fps, without re-encoding. Needs ffmpeg. |
| `pc/corriger_son.bat` | Shifts the audio by a fixed number of ms, without re-encoding. |

### What does not work

- The "Frequency 50/60 Hz" setting does not remove NTSC flicker.

### 💬 Feedback would be great!

Did you test it? Whether it works or not, your feedback helps others. On GitHub, this is done with an **Issue**:

1. At the top of the repository page, click the **Issues** tab, then **New issue**.
2. Pick **Retour de test / Test report** and fill in the short form: firmware version, file tested, resolution, result.
3. Click **Submit new issue**.

You need a GitHub account, which is free.

---

*Testé sur une RunCam Thumb 2, firmware V1.2.2. Scripts fournis sans garantie. / Tested on a RunCam Thumb 2, firmware V1.2.2. Use at your own risk.*
