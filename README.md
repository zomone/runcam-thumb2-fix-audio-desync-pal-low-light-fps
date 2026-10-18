# RunCam Thumb 2 : correction du son décalé en PAL et de la chute de fps dans le noir (audio desync + low-light FPS fix)

🇫🇷 [Français](#-français) · 🇬🇧 [English](#-english)

---

## 🇫🇷 Français

### Les problèmes

1. **Le son se décale en PAL.** L'écart grandit d'environ 1 ms par seconde, soit environ 1,8 s au bout de 30 min.
2. **La vidéo saccade dans le noir.** La caméra allonge le temps de pose (« slow shutter ») et répète des images.

### Les causes

- **Son :** en PAL, le capteur filme à **50,000 i/s**, mais le firmware V1.2.2 indique dans le fichier **50000/1001**, soit 49,95 i/s. Cette erreur se trouve dans 22 modes de sa table PAL, dont le 2.7K50. L'image dure donc 0,1 % de trop par rapport au son.
- **Noir :** l'exposition automatique active le slow shutter. Le temps de pose dépasse alors la durée d'une image, et le capteur ne peut plus fournir 50 images différentes par seconde.

### La solution : `autoexec.ash`

La caméra exécute ce fichier à chaque démarrage. **Le firmware n'est pas modifié** : tout se fait en mémoire vive et s'efface à l'extinction.

1. Il corrige la table PAL en mémoire (1001 → 1000).
2. Il relance l'image vers 7 s, **sans changer la résolution**, pour qu'elle reparte avec la table corrigée.
3. Il désactive le slow shutter toutes les 2 s.

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

### Les autres fichiers

| Fichier | Rôle |
|---|---|
| `autoexec.ash` | **La solution complète** : son + noir. |
| `variante-noir-seulement/autoexec.ash` | Seulement la correction du noir, valable dans toutes les résolutions, en PAL comme en NTSC. Pas de délai de 10 s. À copier aussi à la racine de la carte, à la place de l'autre. |
| `pc/corriger_session.bat` | Pour les **vidéos déjà filmées** : glisse le dossier `DCIM\100MEDIA` dessus. Il recolle les rushs coupés à 4 Go et remet l'image à 50 i/s, sans réencodage. Nécessite ffmpeg. |
| `pc/corriger_son.bat` | Décale le son d'une valeur fixe en ms, sans réencodage. |

### Ce qui ne marche pas

- Le réglage « Fréquence 50/60 Hz » n'enlève pas le scintillement du NTSC.

---

## 🇬🇧 English

### The problems

1. **Audio drifts out of sync in PAL.** The gap grows by about 1 ms per second, roughly 1.8 s after 30 min.
2. **Video stutters in the dark.** The camera lengthens the exposure ("slow shutter") and repeats frames.

### The causes

- **Audio:** in PAL the sensor records at **50.000 fps**, but firmware V1.2.2 writes **50000/1001** (49.95 fps) into the file. The error is in 22 modes of its PAL table, including 2.7K50. The video therefore runs 0.1 % longer than the audio.
- **Dark:** auto exposure enables slow shutter. The exposure becomes longer than one frame, so the sensor can no longer deliver 50 distinct frames per second.

### The fix: `autoexec.ash`

The camera runs this file at every boot. **The firmware is not modified**: everything happens in RAM and is cleared at power-off.

1. It patches the PAL table in RAM (1001 → 1000).
2. It restarts the video pipeline at about 7 s, **keeping the current resolution**, so it picks up the patched table.
3. It disables slow shutter every 2 s.

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

### Other files

| File | Purpose |
|---|---|
| `autoexec.ash` | **The complete fix**: audio + dark. |
| `variante-noir-seulement/autoexec.ash` | Dark fix only, in every resolution, PAL or NTSC. No 10 s delay. Also goes to the root of the card, replacing the other one. |
| `pc/corriger_session.bat` | For **clips already recorded**: drag the `DCIM\100MEDIA` folder onto it. It joins the clips split at 4 GB and restores 50 fps, without re-encoding. Needs ffmpeg. |
| `pc/corriger_son.bat` | Shifts the audio by a fixed number of ms, without re-encoding. |

### What does not work

- The "Frequency 50/60 Hz" setting does not remove NTSC flicker.

---

*Testé sur une RunCam Thumb 2, firmware V1.2.2. Scripts fournis sans garantie. / Tested on a RunCam Thumb 2, firmware V1.2.2. Use at your own risk.*
