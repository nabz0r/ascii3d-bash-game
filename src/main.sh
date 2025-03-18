#!/bin/bash
#
# ASCII3D-Bash-Game
# Un moteur de jeu 3D en ASCII implémenté entièrement en Bash
#
# Auteur: nabz0r
# Licence: MIT
# Date: 2025-03-18
#

# Répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Importer les modules du moteur
source "$SCRIPT_DIR/engine/render.sh"
source "$SCRIPT_DIR/engine/camera.sh"
source "$SCRIPT_DIR/engine/input.sh"
source "$SCRIPT_DIR/engine/buffer.sh"
source "$SCRIPT_DIR/engine/math.sh"

# Importer les modules du jeu
source "$SCRIPT_DIR/game/entities.sh"
source "$SCRIPT_DIR/game/world.sh"
source "$SCRIPT_DIR/game/physics.sh"

# Configuration du jeu
GAME_NAME="ASCII3D Game"
VERSION="0.1.0"
FPS=15
INTERVAL=$(bc <<< "scale=5; 1 / $FPS")

# Variables d'état du jeu
RUNNING=true
PAUSED=false

# Initialisation
function initialize() {
    echo "Initialisation de $GAME_NAME v$VERSION..."
    
    # Initialiser le moteur de rendu
    init_render
    
    # Initialiser la caméra
    init_camera 0 0 -5   # Position initiale (x, y, z)
    
    # Initialiser le système d'entrée
    init_input
    
    # Initialiser le monde
    init_world
    
    # Masquer le curseur
    tput civis
    
    # Nettoyer l'écran
    clear
    
    echo "Initialisation terminée. Démarrage du jeu..."
    sleep 1
}

# Nettoyage à la fin du programme
function cleanup() {
    # Restaurer le terminal
    tput cnorm  # Rendre le curseur visible
    clear
    echo "Merci d'avoir joué à $GAME_NAME!"
}

# Gestionnaires de signaux
trap cleanup EXIT
trap "RUNNING=false" SIGINT SIGTERM

# Affichage des informations de débogage
function display_debug_info() {
    local fps=$1
    
    tput cup 0 0
    echo -e "FPS: ${fps} | Cam: (${CAMERA_X}, ${CAMERA_Y}, ${CAMERA_Z}) | Rot: (${CAMERA_ROT_X}, ${CAMERA_ROT_Y})"
}

# Boucle principale du jeu
function game_loop() {
    local frame_count=0
    local second_start=$(date +%s%N)
    local current_fps=0
    
    while $RUNNING; do
        # Calcul FPS
        local current_time=$(date +%s%N)
        local elapsed=$((current_time - second_start))
        
        if [ $elapsed -ge 1000000000 ]; then
            current_fps=$frame_count
            frame_count=0
            second_start=$current_time
        fi
        
        # Effacer le buffer
        clear_buffer
        
        # Mise à jour des entrées
        process_input
        
        # Mise à jour de la logique de jeu (seulement si non pausé)
        if ! $PAUSED; then
            update_physics
            update_world
        fi
        
        # Rendu
        render_world
        
        # Afficher des informations de débogage
        display_debug_info $current_fps
        
        # Afficher le buffer à l'écran
        render_buffer
        
        # Incrémenter le compteur de frames
        ((frame_count++))
        
        # Attendre pour maintenir le FPS
        sleep $INTERVAL
    done
}

# Point d'entrée du programme
function main() {
    initialize
    game_loop
    cleanup
}

# Lancer le programme
main
