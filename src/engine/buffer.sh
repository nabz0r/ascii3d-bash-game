#!/bin/bash
#
# Système de gestion du buffer d'écran
#

# Importer le script de compatibilité
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/compat.sh"

# Buffer pour stocker les caractères à afficher
declare_A SCREEN_BUFFER

# Initialiser le buffer
function init_buffer() {
    # Effacer le buffer
    clear_buffer
    
    echo "Buffer d'écran initialisé (${SCREEN_WIDTH}x${SCREEN_HEIGHT})"
}

# Effacer le buffer
function clear_buffer() {
    for ((y=0; y<SCREEN_HEIGHT; y++)); do
        for ((x=0; x<SCREEN_WIDTH; x++)); do
            associative_set SCREEN_BUFFER "$x,$y" " "
        done
    done
}

# Dessiner un caractère dans le buffer
function draw_to_buffer() {
    local x=$1
    local y=$2
    local char=$3
    
    # Vérifier que les coordonnées sont dans les limites
    if (( x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT )); then
        associative_set SCREEN_BUFFER "$x,$y" "$char"
    fi
}

# Afficher le contenu du buffer à l'écran
function render_buffer() {
    # Position du curseur en haut à gauche
    tput cup 0 0
    
    # Construire la sortie ligne par ligne pour optimiser les performances
    local output=""
    for ((y=0; y<SCREEN_HEIGHT; y++)); do
        local line=""
        for ((x=0; x<SCREEN_WIDTH; x++)); do
            line+="$(associative_get SCREEN_BUFFER "$x,$y")"
        done
        output+="$line"
        
        # Ajouter un saut de ligne sauf pour la dernière ligne
        if (( y < SCREEN_HEIGHT - 1 )); then
            output+=$'\n'
        fi
    done
    
    # Afficher tout le buffer en une seule fois
    echo -n "$output"
}

# Dessiner un texte dans le buffer
function draw_text() {
    local x=$1
    local y=$2
    local text=$3
    
    local len=${#text}
    for ((i=0; i<len; i++)); do
        local char="${text:$i:1}"
        draw_to_buffer $((x+i)) $y "$char"
    done
}

# Dessiner un rectangle dans le buffer
function draw_rectangle() {
    local x=$1
    local y=$2
    local width=$3
    local height=$4
    local char=${5:-"#"}
    
    # Dessiner les bords horizontaux
    for ((i=0; i<width; i++)); do
        draw_to_buffer $((x+i)) $y "$char"
        draw_to_buffer $((x+i)) $((y+height-1)) "$char"
    done
    
    # Dessiner les bords verticaux
    for ((i=0; i<height; i++)); do
        draw_to_buffer $x $((y+i)) "$char"
        draw_to_buffer $((x+width-1)) $((y+i)) "$char"
    done
}

# Dessiner un rectangle plein dans le buffer
function draw_filled_rectangle() {
    local x=$1
    local y=$2
    local width=$3
    local height=$4
    local char=${5:-"#"}
    
    for ((j=0; j<height; j++)); do
        for ((i=0; i<width; i++)); do
            draw_to_buffer $((x+i)) $((y+j)) "$char"
        done
    done
}

# Afficher une barre de progression
function draw_progress_bar() {
    local x=$1
    local y=$2
    local width=$3
    local percent=$4  # 0-100
    local filled_char=${5:-"#"}
    local empty_char=${6:-"."}
    
    # Calculer le nombre de caractères remplis
    local filled_width=$(bc <<< "scale=0; $width * $percent / 100 / 1")
    
    # Dessiner la partie remplie
    for ((i=0; i<filled_width; i++)); do
        draw_to_buffer $((x+i)) $y "$filled_char"
    done
    
    # Dessiner la partie vide
    for ((i=filled_width; i<width; i++)); do
        draw_to_buffer $((x+i)) $y "$empty_char"
    done
}
