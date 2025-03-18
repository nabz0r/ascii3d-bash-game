# ASCII3D-Bash-Game

Un moteur de jeu 3D en ASCII implémenté entièrement en Bash pour le terminal.

![Licence](https://img.shields.io/github/license/nabz0r/ascii3d-bash-game)

## 📖 Description

ASCII3D-Bash-Game est un moteur de jeu expérimental qui implémente le rendu 3D directement dans le terminal en utilisant uniquement des caractères ASCII. Le projet est écrit entièrement en Bash, sans dépendances externes autres que les utilitaires standard de Unix.

## ✨ Fonctionnalités

- Rendu 3D en temps réel avec des caractères ASCII
- Système de caméra avec perspective
- Gestion des objets 3D (cubes, sphères, etc.)
- Détection de collisions simple
- Contrôles clavier intuitifs
- Mode plein écran dans le terminal

## 🔧 Installation

```bash
# Cloner le dépôt
git clone https://github.com/nabz0r/ascii3d-bash-game.git
cd ascii3d-bash-game

# Rendre les scripts exécutables
chmod +x src/main.sh
```

## 🎮 Utilisation

```bash
# Lancer le jeu
./src/main.sh
```

Commandes :
- `W`, `A`, `S`, `D` : Déplacer la caméra
- `Q`, `E` : Monter/descendre la caméra
- Flèches : Rotation de la caméra
- `Espace` : Action
- `Echap` : Quitter

## 🏗️ Architecture

Le projet est organisé selon la structure suivante :

```
ascii3d-bash-game/
├── src/              # Code source
│   ├── engine/       # Moteur de rendu et fonctionnalités de base
│   ├── game/         # Logique de jeu spécifique
│   └── main.sh       # Point d'entrée du programme
├── assets/           # Ressources (modèles 3D en ASCII, etc.)
└── docs/             # Documentation supplémentaire
```

## 🛠️ Comment ça marche

Le moteur utilise des principes de base de l'infographie 3D :

1. Définition d'objets 3D avec des coordonnées dans l'espace
2. Transformation de ces coordonnées (rotation, translation)
3. Projection en 2D sur l'écran du terminal
4. Rendu avec différents caractères ASCII selon la profondeur et l'orientation

Le tout est implémenté en Bash pur, en utilisant des tableaux associatifs pour la gestion des données et des boucles d'affichage optimisées.

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou proposer une pull request.

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.