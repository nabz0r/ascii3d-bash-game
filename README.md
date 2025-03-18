# ASCII3D-Bash-Game

```
    _    ____   ____ ___ ___ ____  ____  
   / \  / ___| / ___|_ _|_ _|___ \|  _ \ 
  / _ \ \___ \| |    | | | |  __) | | | |
 / ___ \ ___) | |___ | | | | / __/| |_| |
/_/   \_\____/ \____|___|___|_____|____/ 
                                        
 ____   _    ____  _   _    ____    _    __  __ _____ 
| __ ) / \  / ___|| | | |  / ___|  / \  |  \/  | ____|
|  _ \/ _ \ \___ \| |_| | | |  _  / _ \ | |\/| |  _|  
| |_) / ___ \ ___) |  _  | | |_| |/ ___ \| |  | | |___ 
|____/_/   \_\____/|_| |_|  \____/_/   \_\_|  |_|_____|
```

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Bash Version](https://img.shields.io/badge/bash-4.0%2B-orange.svg)

Un moteur de jeu 3D en ASCII implémenté entièrement en Bash pour le terminal. Explorez des donjons générés procéduralement, combattez des ennemis, interagissez avec des PNJ et tout ça sans quitter votre terminal !

## 📋 Table des matières

- [Prérequis](#prérequis)
- [Installation](#installation)
- [Comment jouer](#comment-jouer)
- [Fonctionnalités](#fonctionnalités)
- [Architecture](#architecture)
- [Développement](#développement)
- [Contribution](#contribution)
- [Licence](#licence)

## 🛠️ Prérequis

- Bash 4.0 ou supérieur
- Utilitaires Unix standards (`bc`, `tput`, etc.)
- Terminal supportant les séquences d'échappement ANSI
- Au moins 80x24 caractères de dimensions de terminal

Optionnel (pour les effets sonores) :
- `beep`, `play` (de SoX), `aplay`, ou `mpg123`

## 📥 Installation

### Option 1 : Cloner le dépôt

```bash
# Cloner le dépôt
git clone https://github.com/nabz0r/ascii3d-bash-game.git
cd ascii3d-bash-game

# Rendre les scripts exécutables
chmod +x src/main.sh
chmod +x src/menu.sh
chmod +x src/editor.sh
```

### Option 2 : Installer en tant que package

```bash
# Bientôt disponible
```

## 🎮 Comment jouer

```bash
# Lancer le menu principal
./src/menu.sh

# Ou lancer directement le jeu
./src/main.sh

# Ou lancer l'éditeur de niveaux
./src/editor.sh
```

### Contrôles

- **Déplacement** : `W` (avant), `S` (arrière), `A` (gauche), `D` (droite)
- **Regard** : Flèches directionnelles
- **Actions** : 
  - `E` - Interagir (PNJ, objets)
  - `Space` - Attaquer / Action principale
  - `Q` - Monter
  - `Z` - Descendre
  - `I` - Inventaire
  - `M` - Carte / Minimap
  - `Tab` - Menu de quêtes
  - `Esc` - Menu pause

## ✨ Fonctionnalités

- **Moteur 3D en ASCII** - Rendu 3D complet réalisé avec des caractères ASCII
- **Exploration** - Explorez des donjons générés procéduralement ou des mondes construits manuellement
- **Combat** - Système de combat au tour par tour avec différentes capacités
- **Inventory** - Collectez, utilisez et équipez des objets
- **Quêtes** - Système de quêtes avec objectifs et récompenses
- **Dialogues** - Interactions avec des PNJ
- **Marchands** - Achetez et vendez des objets
- **Donjons** - Génération procédurale de donjons avec pièges, coffres et ennemis
- **HUD** - Interface utilisateur avec informations de jeu
- **Sauvegarde/Chargement** - Système pour sauvegarder et charger votre progression
- **Menu** - Menu principal pour naviguer dans les fonctionnalités
- **Éditeur** - Créez vos propres niveaux

## 🏗️ Architecture

Le projet est organisé selon la structure suivante :

```
ascii3d-bash-game/
├── assets/                # Ressources du jeu
│   ├── levels/            # Niveaux pré-construits
│   ├── models/            # Modèles 3D ASCII
│   └── sounds/            # Effets sonores (si disponibles)
├── config/                # Configuration du jeu
├── docs/                  # Documentation
├── saves/                 # Sauvegardes de jeu
└── src/                   # Code source
    ├── engine/            # Moteur de jeu
    │   ├── buffer.sh      # Gestion du buffer d'écran
    │   ├── camera.sh      # Système de caméra
    │   ├── hud.sh         # Interface utilisateur
    │   ├── input.sh       # Gestion des entrées
    │   ├── math.sh        # Fonctions mathématiques
    │   ├── optimize.sh    # Optimisations de performance
    │   ├── render.sh      # Système de rendu
    │   ├── sound.sh       # Système sonore
    │   └── texture.sh     # Gestion des textures
    ├── game/              # Logique de jeu
    │   ├── combat.sh      # Système de combat
    │   ├── dungeon.sh     # Générateur de donjons
    │   ├── entities.sh    # Entités du jeu
    │   ├── inventory.sh   # Système d'inventaire
    │   ├── npc.sh         # Personnages non-joueurs
    │   ├── physics.sh     # Physique simplifiée
    │   ├── quest.sh       # Système de quêtes
    │   ├── save.sh        # Sauvegarde/chargement
    │   └── world.sh       # Gestion du monde
    ├── editor.sh          # Éditeur de niveaux
    ├── main.sh            # Point d'entrée du jeu
    └── menu.sh            # Menu principal
```

## 🚀 Développement

Le projet est en développement actif. Voici quelques fonctionnalités en cours de développement :

- Amélioration des performances de rendu
- Système avancé de dialogues arborescents
- Plus de types d'ennemis et d'objets
- Effets visuels ASCII plus sophistiqués
- Mode multijoueur local

## 🤝 Contribution

Les contributions sont les bienvenues ! Voici comment vous pouvez aider :

1. **Fork** le projet
2. Créez votre branche de fonctionnalité (`git checkout -b feature/amazing-feature`)
3. Committez vos changements (`git commit -m 'Add some amazing feature'`)
4. Poussez vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrez une **Pull Request**

Veuillez lire [CONTRIBUTING.md](docs/CONTRIBUTING.md) pour plus de détails sur notre code de conduite et le processus de soumission des pull requests.

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

Créé avec ❤️ par [nabz0r](https://github.com/nabz0r)

```
              .,-:;//;:=,
          . :H@@@MM@M#H/.,+%;,
       ,/X+ +M@@M@MM%=,-%HMMM@X/,
     -+@MM; $M@@MH+-,;XMMMM@MMMM@+-
    ;@M@@M- XM@X;. -+XXXXXHHH@M@M#@/.
  ,%MM@@MH ,@%=             .---=-=:=,.
  =@#@@@MX.,                -%HX$$%%%:;
 =-./@M@M$                   .;@MMMM@MM:
 X@/ -$MM/                    . +MM@@@M$
,@M@H: :@:                    . =X#@@@@-
,@@@MMX, .                    /H- ;@M@M=
.H@@@@M@+,                    %MM+..%#$.
 /MMMM@MMH/.                  XM@MH; =;
  /%+%$XHH@$=              , .H@@@@MX,
   .=--------.           -%H.,@@@@@MX,
   .%MM@@@HHHXX$$$%+- .:$MMX =M@@MM%.
     =XMMM@MM@MM#H;,-+HMM@M+ /MMMX=
       =%@M@M#@$-.=$@MM@@@M; %M%=
         ,:+$+-,/H#MMMMMMM@= =,
               =++%%%%+/:-.
```
