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
├── src/                  # Code source
│   ├── engine/           # Moteur de rendu et fonctionnalités de base
│   │   ├── render.sh     # Système de rendu ASCII
│   │   ├── camera.sh     # Gestion de la caméra
│   │   ├── math.sh       # Opérations mathématiques 3D
│   │   ├── input.sh      # Gestion des entrées clavier
│   │   └── buffer.sh     # Gestion du buffer d'écran
│   ├── game/             # Logique de jeu
│   │   ├── entities.sh   # Définition des entités du jeu
│   │   ├── world.sh      # Gestion du monde de jeu
│   │   └── physics.sh    # Physique simplifié
│   └── main.sh           # Point d'entrée du programme
├── assets/               # Ressources
│   └── models/           # Modèles 3D en ASCII
└── docs/                 # Documentation supplémentaire
```

🛠️ Comment ça marche

Le moteur utilise les principes de base de l'infographie 3D :

Définition d'objets 3D avec des coordonnées dans l'espace
Transformation de ces coordonnées (rotation, translation)
Projection en 2D sur l'écran du terminal
Z-buffer pour gérer la profondeur des objets
Rendu ASCII avec différents caractères selon la profondeur et l'orientation

Le tout est implémenté en Bash pur, en utilisant :

Des tableaux associatifs pour stocker les données
bc pour les calculs mathématiques
tput pour manipuler le terminal
Boucles d'affichage optimisées pour les performances

Optimisations
Pour améliorer les performances et maintenir un framerate acceptable :

Précalcul des fonctions trigonométriques
Utilisation de buffers pour minimiser les appels à tput
Techniques d'occlusion pour éviter de dessiner des objets cachés
Limites de distances de rendu

🤝 Contribution
Les contributions sont les bienvenues ! Voici quelques domaines qui pourraient être améliorés :

Optimisation des performances
Ajout de nouveaux modèles 3D
Amélioration du système de physique
Implémentation d'un système de textures ASCII
Création de niveaux et gameplay

📄 Licence
Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.

📚 Ressources

Techniques de rendu ASCII
Principes de base du rendu 3D
Programmation Bash avancée

📋 TODO

 Améliorer les performances du rendu
 Ajouter un système de textures ASCII
 Implémenter un éditeur de niveaux
 Ajouter un menu principal
 Implémenter la sauvegarde/chargement de parties
 Ajouter des effets sonores (si possible)
