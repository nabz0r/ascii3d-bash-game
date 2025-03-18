#!/bin/bash
#
# Système de gestion des entrées clavier
#

# Variables pour les touches pressées
KEY_W_PRESSED=false
KEY_A_PRESSED=false
KEY_S_PRESSED=false
KEY_D_PRESSED=false
KEY_Q_PRESSED=false
KEY_E_PRESSED=false
KEY_UP_PRESSED=false
KEY_DOWN_PRESSED=false
KEY_LEFT_PRESSED=false
KEY_RIGHT_PRESSED=false
KEY_SPACE_PRESSED=false
KEY_ESC_PRESSED=false

# Initialiser le système d'entrée
function init_input() {
    # Configuration du terminal pour la lecture non-bloquante des touches
    stty -echo -icanon time 0 min 0
    
    echo "Système d'entrée initialisé"
}

# Lire les entrées clavier de manière non-bloquante
function read_input() {
    # Réinitialiser les états des touches
    KEY_W_PRESSED=false
    KEY_A_PRESSED=false
    KEY_S_PRESSED=false
    KEY_D_PRESSED=false
    KEY_Q_PRESSED=false
    KEY_E_PRESSED=false
    KEY_UP_PRESSED=false
    KEY_DOWN_PRESSED=false
    KEY_LEFT_PRESSED=false
    KEY_RIGHT_PRESSED=false
    KEY_SPACE_PRESSED=false
    KEY_ESC_PRESSED=false
    
    # Lire jusqu'à 10 caractères à la fois pour gérer plusieurs touches
    local key
    for ((i=0; i<10; i++)); do
        IFS= read -r -s -n1 key
        
        # Si aucune touche n'est pressée, sortir de la boucle
        if [[ -z "$key" ]]; then
            break
        fi
        
        # Séquences d'échappement pour les touches spéciales
        if [[ "$key" == $'\e' ]]; then
            IFS= read -r -s -n2 -t 0.01 seq
            
            case "$seq" in
                "[A") KEY_UP_PRESSED=true ;;
                "[B") KEY_DOWN_PRESSED=true ;;
                "[C") KEY_RIGHT_PRESSED=true ;;
                "[D") KEY_LEFT_PRESSED=true ;;
                *) KEY_ESC_PRESSED=true ;;
            esac
        else
            # Touches régulières
            case "$key" in
                w|W) KEY_W_PRESSED=true ;;
                a|A) KEY_A_PRESSED=true ;;
                s|S) KEY_S_PRESSED=true ;;
                d|D) KEY_D_PRESSED=true ;;
                q|Q) KEY_Q_PRESSED=true ;;
                e|E) KEY_E_PRESSED=true ;;
                " ") KEY_SPACE_PRESSED=true ;;
                $'\x1b') KEY_ESC_PRESSED=true ;;  # Échap
            esac
        fi
    done
}

# Traiter les entrées et mettre à jour l'état du jeu
function process_input() {
    # Lire les entrées clavier
    read_input
    
    # Gérer les mouvements de la caméra
    if $KEY_W_PRESSED; then
        move_camera_forward
    fi
    
    if $KEY_S_PRESSED; then
        move_camera_backward
    fi
    
    if $KEY_A_PRESSED; then
        move_camera_left
    fi
    
    if $KEY_D_PRESSED; then
        move_camera_right
    fi
    
    if $KEY_Q_PRESSED; then
        move_camera_up
    fi
    
    if $KEY_E_PRESSED; then
        move_camera_down
    fi
    
    # Gérer les rotations de la caméra
    if $KEY_UP_PRESSED; then
        rotate_camera_up
    fi
    
    if $KEY_DOWN_PRESSED; then
        rotate_camera_down
    fi
    
    if $KEY_LEFT_PRESSED; then
        rotate_camera_left
    fi
    
    if $KEY_RIGHT_PRESSED; then
        rotate_camera_right
    fi
    
    # Gérer les autres touches
    if $KEY_SPACE_PRESSED; then
        # Action spécifique au jeu
        :
    fi
    
    if $KEY_ESC_PRESSED; then
        # Quitter le jeu
        RUNNING=false
    fi
}
