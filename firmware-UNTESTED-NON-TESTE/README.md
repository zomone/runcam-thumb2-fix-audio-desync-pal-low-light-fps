# ⚠️ Firmware modifié : JAMAIS TESTÉ / Modified firmware: NEVER TESTED

🇫🇷 [Français](#-français) · 🇬🇧 [English](#-english)

---

## 🇫🇷 Français

### ⚠️ Avertissement

- **Ce firmware n'a jamais été flashé ni testé sur aucune caméra.**
- Il reprend uniquement les corrections du fichier `autoexec.ash`, qui, elles, ont été testées en mémoire vive.
- **Le flasher est entièrement à tes risques.** Si ta caméra ne démarre plus ou ne se met plus à jour, **c'est ta responsabilité, pas celle de l'auteur**. Aucune aide ni garantie n'est fournie.
- Pour la plupart des gens, le fichier `autoexec.ash` à la racine du dépôt suffit, et il est sans risque.

### Ce qui est modifié

Base : `Thumb2.bin` officiel **V1.2.2** de RunCam (SHA-256 `97c51baf0607181e9722a0c58a92cc02591641d95b1f3fe228458b5b638f36e6`).

| Changement | Effet |
|---|---|
| 22 lignes de la table PAL : 50000/**1001** → 50000/**1000** | Son synchro en PAL, dès l'allumage, sans attendre 10 s |
| Instruction à l'adresse RAM `0x112100` : `movgt r3,#1` → `movgt r3,#0` | Slow shutter toujours désactivé, plus de chute de fps dans le noir |

Au total, 55 octets changent. Les CRC connus ont été recalculés : celui de la section 1, la table des CRC cumulés à `0x30`-`0x58`, le CRC global à `0x24` et son inverse à `0x5C`.

**Inconnu :** le mot de 4 octets à l'adresse `0x20` (`0x8732DFE6`). Sa fonction n'a pas été trouvée. S'il sert de contrôle, la caméra peut refuser le fichier ou rester bloquée.

Fichier : `Thumb2_V1.2.2_patched_UNTESTED.bin`, SHA-256 `4edf554d607cce33111cd000415dc5f2b3cd3aacd86cfbc6dc0e034d2528d0c8`.

### Avantages par rapport à `autoexec.ash`, s'il fonctionne

- Pas d'attente de 10 s au démarrage, et l'enregistrement automatique au démarrage est possible.
- Rien à mettre sur la carte : on peut la formater depuis la caméra ou l'appli sans perdre la correction.
- Le codec n'est plus forcé en H.264.

### Si tu décides quand même de le flasher

Suis la procédure officielle de RunCam. Renomme le fichier en `Thumb2.bin`, copie-le à la racine de la carte SD, puis allume la caméra et ne coupe pas l'alimentation pendant 2 à 3 minutes. Pour revenir en arrière, flashe le `Thumb2.bin` officiel V1.2.2 de la même façon, si la caméra démarre encore.

---

## 🇬🇧 English

### ⚠️ Warning

- **This firmware has never been flashed or tested on any camera.**
- It only contains the fixes from the `autoexec.ash` file, which were tested in RAM.
- **Flashing it is entirely at your own risk.** If your camera no longer boots or updates, **it is your responsibility, not the author's**. No support or warranty is provided.
- For most people, the `autoexec.ash` file at the root of the repository is enough, and it carries no risk.

### What is changed

Base: official RunCam `Thumb2.bin` **V1.2.2** (SHA-256 `97c51baf0607181e9722a0c58a92cc02591641d95b1f3fe228458b5b638f36e6`).

| Change | Effect |
|---|---|
| 22 rows of the PAL table: 50000/**1001** → 50000/**1000** | Audio in sync in PAL, right from power-on, no 10 s wait |
| Instruction at RAM address `0x112100`: `movgt r3,#1` → `movgt r3,#0` | Slow shutter always off, no more FPS drop in the dark |

55 bytes change in total. The known CRCs were recomputed: section 1, the cumulative CRC table at `0x30`-`0x58`, and the global CRC at `0x24` with its inverse at `0x5C`.

**Unknown:** the 4-byte word at offset `0x20` (`0x8732DFE6`). Its purpose was not found. If it is a check, the camera may reject the file or get stuck.

File: `Thumb2_V1.2.2_patched_UNTESTED.bin`, SHA-256 `4edf554d607cce33111cd000415dc5f2b3cd3aacd86cfbc6dc0e034d2528d0c8`.

### Advantages over `autoexec.ash`, if it works

- No 10 s wait at boot, and auto recording on startup is possible.
- Nothing on the card: you can format it from the camera or the app without losing the fix.
- The codec is no longer forced to H.264.

### If you still decide to flash it

Follow RunCam's official procedure. Rename the file to `Thumb2.bin`, copy it to the root of the SD card, then power on the camera and do not cut power for 2 to 3 minutes. To go back, flash the official V1.2.2 `Thumb2.bin` the same way, if the camera still boots.
