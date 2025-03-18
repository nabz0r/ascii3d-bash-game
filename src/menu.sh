#!/bin/bash
#
# Menu principal pour ASCII3D-Bash-Game
#

# Répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Importer les modules nécessaires
source "$SCRIPT_DIR/engine/buffer.sh"
source "$SCRIPT_DIR/engine/input.sh"
source "$SCRIPT_DIR/game/save.sh"

# Configuration du menu
GAME_TITLE="ASCII3D-Bash-Game"
VERSION="0.1.0"
FPS=30
INTERVAL=$(bc <<< "scale=5; 1 / $FPS")

# Variables d'état du menu
MENU_RUNNING=true
CURRENT_OPTION=0
MENU_OPTIONS=("Nouvelle partie" "Charger partie" "Éditeur de niveaux" "Options" "À propos" "Quitter")
NUM_OPTIONS=${#MENU_OPTIONS[@]}

# Logo ASCII du jeu
read -r -d '' GAME_LOGO << 'EOF'
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
EOF

# Options du jeu
declare -A GAME_OPTIONS
GAME_OPTIONS["soundfx"]=true
GAME_OPTIONS["musique"]=true
GAME_OPTIONS["fullscreen"]=true
GAME_OPTIONS["difficulte"]="normal"  # facile, normal, difficile

# Initialiser le menu
function init_menu() {
    # Initialiser le buffer et les entrées
    init_buffer
    init_input
    
    # Masquer le curseur
    tput civis
    
    # Effacer l'écran
    clear
}

# Nettoyer à la sortie
function cleanup_menu() {
    # Restaurer le terminal
    tput cnorm  # Rendre le curseur visible
    tput sgr0   # Réinitialiser les attributs
    clear
}

# Gestionnaires de signaux
trap cleanup_menu EXIT
trap "MENU_RUNNING=false" SIGINT SIGTERM

# Dessiner le logo du jeu
function draw_logo() {
    local start_y=2
    local start_x=$((SCREEN_WIDTH / 2 - 30))  # Centrer approximativement
    
    local line_num=$start_y
    while IFS= read -r line; do
        draw_text $start_x $line_num "$line"
        ((line_num++))
    done <<< "$GAME_LOGO"
}

# Dessiner le titre et la version
function draw_title() {
    local title="$GAME_TITLE v$VERSION"
    local title_x=$((SCREEN_WIDTH / 2 - ${#title} / 2))
    
    draw_text $title_x 10 "$title"
}

# Dessiner les options du menu
function draw_menu_options() {
    local start_y=14
    local option_spacing=2
    
    for ((i=0; i<NUM_OPTIONS; i++)); do
        local option="${MENU_OPTIONS[$i]}"
        local option_x=$((SCREEN_WIDTH / 2 - ${#option} / 2))
        local option_y=$((start_y + i * option_spacing))
        
        # Mettre en surbrillance l'option sélectionnée
        if [ $i -eq $CURRENT_OPTION ]; then
            # Dessiner un indicateur de sélection
            draw_text $((option_x - 2)) $option_y ">>"
            draw_text $((option_x + ${#option} + 1)) $option_y "<<"
            
            # Dessiner l'option en surbrillance
            tput bold
            draw_text $option_x $option_y "$option"
            tput sgr0
        else
            # Dessiner l'option normale
            draw_text $option_x $option_y "$option"
        fi
    done
}

# Dessiner la note de bas de page
function draw_footer() {
    local footer1="Utilisez les flèches Haut/Bas pour naviguer, Entrée pour sélectionner"
    local footer2="© 2025 - Un jeu entièrement en Bash"
    
    local footer1_x=$((SCREEN_WIDTH / 2 - ${#footer1} / 2))
    local footer2_x=$((SCREEN_WIDTH / 2 - ${#footer2} / 2))
    
    draw_text $footer1_x $((SCREEN_HEIGHT - 3)) "$footer1"
    draw_text $footer2_x $((SCREEN_HEIGHT - 2)) "$footer2"
}

# Traiter les entrées du menu
function process_menu_input() {
    # Lire les entrées
    read_input
    
    # Naviguer dans le menu
    if $KEY_UP_PRESSED; then
        ((CURRENT_OPTION--))
        if [ $CURRENT_OPTION -lt 0 ]; then
            CURRENT_OPTION=$((NUM_OPTIONS - 1))
        fi
    fi
    
    if $KEY_DOWN_PRESSED; then
        ((CURRENT_OPTION++))
        if [ $CURRENT_OPTION -ge $NUM_OPTIONS ]; then
            CURRENT_OPTION=0
        fi
    fi
    
    # Sélectionner une option
    if $KEY_ENTER_PRESSED; then
        execute_menu_option
    fi
    
    # Quitter
    if $KEY_ESC_PRESSED; then
        MENU_RUNNING=false
    fi
}

# Exécuter l'option sélectionnée
function execute_menu_option() {
    case "${MENU_OPTIONS[$CURRENT_OPTION]}" in
        "Nouvelle partie")
            start_new_game
            ;;
        "Charger partie")
            load_game_menu
            ;;
        "Éditeur de niveaux")
            start_level_editor
            ;;
        "Options")
            show_options_menu
            ;;
        "À propos")
            show_about_screen
            ;;
        "Quitter")
            MENU_RUNNING=false
            ;;
    esac
}

# Démarrer une nouvelle partie
function start_new_game() {
    # Sauvegarder l'écran
    tput smcup
    
    # Effacer l'écran
    clear
    
    # Afficher un message de chargement
    local message="Démarrage d'une nouvelle partie..."
    local msg_x=$((SCREEN_WIDTH / 2 - ${#message} / 2))
    local msg_y=$((SCREEN_HEIGHT / 2))
    
    echo -e "\n\n\n\n"
    echo -e "$(printf '%*s' $msg_x '')$message"
    
    # Pause pour l'effet
    sleep 1
    
    # Quitter le menu et lancer le jeu
    cleanup_menu
    MENU_RUNNING=false
    
    # Exécuter le jeu
    "$SCRIPT_DIR/main.sh"
    
    # Une fois le jeu terminé, revenir au menu
    init_menu
    MENU_RUNNING=true
    
    # Restaurer l'écran
    tput rmcup
}

# Afficher le menu de chargement de partie
function load_game_menu() {
    # Sauvegarder l'écran
    tput smcup
    
    # Variables du menu de chargement
    local load_menu_running=true
    local current_save=0
    local saves=()
    
    # Obtenir la liste des sauvegardes
    mapfile -t saves < <(list_save_files)
    local num_saves=${#saves[@]}
    
    # S'il n'y a pas de sauvegardes, afficher un message
    if [ $num_saves -eq 0 ]; then
        # Effacer l'écran
        clear
        
        # Afficher un message
        local message="Aucune sauvegarde trouvée !"
        local msg_x=$((SCREEN_WIDTH / 2 - ${#message} / 2))
        local msg_y=$((SCREEN_HEIGHT / 2))
        
        echo -e "\n\n\n\n"
        echo -e "$(printf '%*s' $msg_x '')$message"
        
        # Pause pour l'effet
        sleep 2
        
        # Restaurer l'écran
        tput rmcup
        return
    fi
    
    # Boucle du menu de chargement
    while $load_menu_running; do
        # Effacer l'écran
        clear
        
        # Dessiner l'en-tête
        local header="Charger une partie sauvegardée"
        local header_x=$((SCREEN_WIDTH / 2 - ${#header} / 2))
        
        echo -e "\n\n"
        echo -e "$(printf '%*s' $header_x '')$header"
        echo -e "$(printf '%*s' $header_x '')$(printf '%*s' ${#header} '' | tr ' ' '=')"
        echo -e "\n\n"
        
        # Dessiner la liste des sauvegardes
        for ((i=0; i<num_saves; i++)); do
            local save="${saves[$i]}"
            local save_info=$(get_save_info "$save")
            local save_x=$((SCREEN_WIDTH / 2 - ${#save_info} / 2))
            
            # Mettre en surbrillance la sauvegarde sélectionnée
            if [ $i -eq $current_save ]; then
                echo -e "$(printf '%*s' $((save_x - 2)) '')>> $save_info <<"
            else
                echo -e "$(printf '%*s' $save_x '')$save_info"
            fi
            
            echo -e ""
        done
        
        # Dessiner les instructions
        echo -e "\n\n"
        echo -e "$(printf '%*s' $((SCREEN_WIDTH / 2 - 25)) '')Utilisez les flèches Haut/Bas pour naviguer"
        echo -e "$(printf '%*s' $((SCREEN_WIDTH / 2 - 25)) '')Entrée pour charger, Échap pour revenir"
        
        # Lire l'entrée
        read -n 1 -s key
        
        # Traiter l'entrée
        case "$key" in
            A|k) # Flèche haut
                ((current_save--))
                if [ $current_save -lt 0 ]; then
                    current_save=$((num_saves - 1))
                fi
                ;;
            B|j) # Flèche bas
                ((current_save++))
                if [ $current_save -ge $num_saves ]; then
                    current_save=0
                fi
                ;;
            "") # Entrée
                # Charger la sauvegarde sélectionnée
                load_game "${saves[$current_save]}"
                load_menu_running=false
                ;;
            $'\e') # Échap
                load_menu_running=false
                ;;
        esac
    done
    
    # Restaurer l'écran
    tput rmcup
}

# Démarrer l'éditeur de niveaux
function start_level_editor() {
    # Sauvegarder l'écran
    tput smcup
    
    # Effacer l'écran
    clear
    
    # Afficher un message de chargement
    local message="Démarrage de l'éditeur de niveaux..."
    local msg_x=$((SCREEN_WIDTH / 2 - ${#message} / 2))
    local msg_y=$((SCREEN_HEIGHT / 2))
    
    echo -e "\n\n\n\n"
    echo -e "$(printf '%*s' $msg_x '')$message"
    
    # Pause pour l'effet
    sleep 1
    
    # Quitter le menu et lancer l'éditeur
    cleanup_menu
    MENU_RUNNING=false
    
    # Exécuter l'éditeur
    "$SCRIPT_DIR/editor.sh"
    
    # Une fois l'éditeur terminé, revenir au menu
    init_menu
    MENU_RUNNING=true
    
    # Restaurer l'écran
    tput rmcup
}

# Afficher le menu des options
function show_options_menu() {
    # Sauvegarder l'écran
    tput smcup
    
    # Variables du menu d'options
    local options_menu_running=true
    local current_option=0
    local options_list=("Effets sonores: ${GAME_OPTIONS["soundfx"]}" 
                         "Musique: ${GAME_OPTIONS["musique"]}" 
                         "Plein écran: ${GAME_OPTIONS["fullscreen"]}" 
                         "Difficulté: ${GAME_OPTIONS["difficulte"]}" 
                         "Retour")
    local num_options=${#options_list[@]}
    
    # Boucle du menu d'options
    while $options_menu_running; do
        # Mettre à jour les textes des options
        options_list[0]="Effets sonores: ${GAME_OPTIONS["soundfx"]}"
        options_list[1]="Musique: ${GAME_OPTIONS["musique"]}"
        options_list[2]="Plein écran: ${GAME_OPTIONS["fullscreen"]}"
        options_list[3]="Difficulté: ${GAME_OPTIONS["difficulte"]}"
        
        # Effacer l'écran
        clear
        
        # Dessiner l'en-tête
        local header="Options du jeu"
        local header_x=$((SCREEN_WIDTH / 2 - ${#header} / 2))
        
        echo -e "\n\n"
        echo -e "$(printf '%*s' $header_x '')$header"
        echo -e "$(printf '%*s' $header_x '')$(printf '%*s' ${#header} '' | tr ' ' '=')"
        echo -e "\n\n"
        
        # Dessiner les options
        for ((i=0; i<num_options; i++)); do
            local option="${options_list[$i]}"
            local option_x=$((SCREEN_WIDTH / 2 - ${#option} / 2))
            
            # Mettre en surbrillance l'option sélectionnée
            if [ $i -eq $current_option ]; then
                echo -e "$(printf '%*s' $((option_x - 2)) '')>> $option <<"
            else
                echo -e "$(printf '%*s' $option_x '')$option"
            fi
            
            echo -e ""
        done
        
        # Dessiner les instructions
        echo -e "\n\n"
        echo -e "$(printf '%*s' $((SCREEN_WIDTH / 2 - 30)) '')Utilisez les flèches Haut/Bas pour naviguer, Gauche/Droite pour changer les valeurs"
        echo -e "$(printf '%*s' $((SCREEN_WIDTH / 2 - 20)) '')Entrée pour sélectionner, Échap pour revenir"
        
        # Lire l'entrée
        read -n 1 -s key
        
        # Traiter l'entrée
        case "$key" in
            A|k) # Flèche haut
                ((current_option--))
                if [ $current_option -lt 0 ]; then
                    current_option=$((num_options - 1))
                fi
                ;;
            B|j) # Flèche bas
                ((current_option++))
                if [ $current_option -ge $num_options ]; then
                    current_option=0
                fi
                ;;
            C|l) # Flèche droite
                # Modifier l'option sélectionnée
                case $current_option in
                    0) # Effets sonores
                        if [ "${GAME_OPTIONS["soundfx"]}" = true ]; then
                            GAME_OPTIONS["soundfx"]=false
                        else
                            GAME_OPTIONS["soundfx"]=true
                        fi
                        ;;
                    1) # Musique
                        if [ "${GAME_OPTIONS["musique"]}" = true ]; then
                            GAME_OPTIONS["musique"]=false
                        else
                            GAME_OPTIONS["musique"]=true
                        fi
                        ;;
                    2) # Plein écran
                        if [ "${GAME_OPTIONS["fullscreen"]}" = true ]; then
                            GAME_OPTIONS["fullscreen"]=false
                        else
                            GAME_OPTIONS["fullscreen"]=true
                        fi
                        ;;
                    3) # Difficulté
                        case "${GAME_OPTIONS["difficulte"]}" in
                            "facile")
                                GAME_OPTIONS["difficulte"]="normal"
                                ;;
                            "normal")
                                GAME_OPTIONS["difficulte"]="difficile"
                                ;;
                            "difficile")
                                GAME_OPTIONS["difficulte"]="facile"
                                ;;
                        esac
                        ;;
                esac
                ;;
            D|h) # Flèche gauche
                # Modifier l'option sélectionnée
                case $current_option in
                    0) # Effets sonores
                        if [ "${GAME_OPTIONS["soundfx"]}" = true ]; then
                            GAME_OPTIONS["soundfx"]=false
                        else
                            GAME_OPTIONS["soundfx"]=true
                        fi
                        ;;
                    1) # Musique
                        if [ "${GAME_OPTIONS["musique"]}" = true ]; then
                            GAME_OPTIONS["musique"]=false
                        else
                            GAME_OPTIONS["musique"]=true
                        fi
                        ;;
                    2) # Plein écran
                        if [ "${GAME_OPTIONS["fullscreen"]}" = true ]; then
                            GAME_OPTIONS["fullscreen"]=false
                        else
                            GAME_OPTIONS["fullscreen"]=true
                        fi
                        ;;
                    3) # Difficulté
                        case "${GAME_OPTIONS["difficulte"]}" in
                            "facile")
                                GAME_OPTIONS["difficulte"]="difficile"
                                ;;
                            "normal")
                                GAME_OPTIONS["difficulte"]="facile"
                                ;;
                            "difficile")
                                GAME_OPTIONS["difficulte"]="normal"
                                ;;
                        esac
                        ;;
                esac
                ;;
            "") # Entrée
                if [ $current_option -eq $((num_options - 1)) ]; then
                    # Option "Retour"
                    options_menu_running=false
                    save_options
                fi
                ;;
            $'\e') # Échap
                options_menu_running=false
                save_options
                ;;
        esac
    done
    
    # Restaurer l'écran
    tput rmcup
}

# Sauvegarder les options
function save_options() {
    # Créer le répertoire si nécessaire
    mkdir -p "$SCRIPT_DIR/../config"
    
    # Sauvegarder les options dans un fichier
    local options_file="$SCRIPT_DIR/../config/options.conf"
    
    # Écrire les options
    > "$options_file"  # Vider le fichier
    
    for option in "${!GAME_OPTIONS[@]}"; do
        echo "$option=${GAME_OPTIONS[$option]}" >> "$options_file"
    done
    
    echo "Options sauvegardées dans $options_file"
}

# Charger les options
function load_options() {
    # Vérifier si le fichier existe
    local options_file="$SCRIPT_DIR/../config/options.conf"
    
    if [ -f "$options_file" ]; then
        # Lire les options
        while IFS='=' read -r key value; do
            GAME_OPTIONS["$key"]="$value"
        done < "$options_file"
        
        echo "Options chargées depuis $options_file"
    else
        echo "Fichier d'options non trouvé, utilisation des valeurs par défaut"
    fi
}

# Afficher l'écran "À propos"
function show_about_screen() {
    # Sauvegarder l'écran
    tput smcup
    
    # Variables
    local about_running=true
    
    # Contenu de l'écran "À propos"
    local about_text=(
        "ASCII3D-Bash-Game v$VERSION"
        ""
        "Un moteur de jeu 3D en ASCII implémenté entièrement en Bash pour le terminal."
        ""
        "Fonctionnalités:"
        "- Rendu 3D en temps réel avec des caractères ASCII"
        "- Système de caméra avec perspective"
        "- Gestion des objets 3D (cubes, sphères, etc.)"
        "- Détection de collisions et physique simple"
        "- Système de textures ASCII"
        "- Éditeur de niveaux intégré"
        "- Sauvegarde et chargement de parties"
        ""
        "Créé avec passion par @nabz0r"
        "Licence: MIT"
        ""
        "Appuyez sur une touche pour revenir au menu principal..."
    )
    
    # Effacer l'écran
    clear
    
    # Calculer la position de départ pour centrer le texte
    local start_y=$((SCREEN_HEIGHT / 2 - ${#about_text[@]} / 2))
    
    # Dessiner le texte
    for ((i=0; i<${#about_text[@]}; i++)); do
        local line="${about_text[$i]}"
        local line_x=$((SCREEN_WIDTH / 2 - ${#line} / 2))
        local line_y=$((start_y + i))
        
        echo -e "\033[${line_y};${line_x}H$line"
    done
    
    # Attendre une touche
    read -n 1 -s
    
    # Restaurer l'écran
    tput rmcup
}

# Boucle principale du menu
function menu_loop() {
    while $MENU_RUNNING; do
        # Effacer le buffer
        clear_buffer
        
        # Dessiner le contenu du menu
        draw_logo
        draw_title
        draw_menu_options
        draw_footer
        
        # Afficher le buffer
        render_buffer
        
        # Traiter les entrées du menu
        process_menu_input
        
        # Attendre pour maintenir le FPS
        sleep $INTERVAL
    done
}

# Point d'entrée du programme
function main() {
    # Initialiser le menu
    init_menu
    
    # Charger les options
    load_options
    
    # Lancer la boucle du menu
    menu_loop
    
    # Nettoyer à la sortie
    cleanup_menu
}

# Exécuter le programme
main
