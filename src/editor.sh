#!/bin/bash
#
# Éditeur de niveaux pour ASCII3D-Bash-Game
#

# Répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Importer les modules du moteur
source "$SCRIPT_DIR/engine/render.sh"
source "$SCRIPT_DIR/engine/camera.sh"
source "$SCRIPT_DIR/engine/input.sh"
source "$SCRIPT_DIR/engine/buffer.sh"
source "$SCRIPT_DIR/engine/math.sh"
source "$SCRIPT_DIR/engine/texture.sh"

# Importer les modules du jeu
source "$SCRIPT_DIR/game/world.sh"
source "$SCRIPT_DIR/game/entities.sh"

# Configuration de l'éditeur
EDITOR_NAME="ASCII3D Level Editor"
VERSION="0.1.0"
FPS=15
INTERVAL=$(bc <<< "scale=5; 1 / $FPS")

# Variables d'état de l'éditeur
EDITOR_RUNNING=true
CURRENT_LEVEL_FILE=""
EDITOR_MODE="view"      # view, place, select, edit
CURRENT_OBJECT_TYPE="cube"
CURRENT_TEXTURE="brick"
CURRENT_SCALE=1.0
GRID_SIZE=1.0
SHOW_GRID=true
SELECTED_OBJECT_ID=-1
CLIPBOARD=""

# Position du curseur 3D
CURSOR_X=0
CURSOR_Y=0
CURSOR_Z=0

# Initialisation
function initialize_editor() {
    echo "Initialisation de $EDITOR_NAME v$VERSION..."
    
    # Initialiser le moteur de rendu
    init_render
    
    # Initialiser la caméra
    init_camera 0 5 -10   # Position initiale (x, y, z)
    
    # Initialiser le système d'entrée
    init_input
    
    # Initialiser le monde
    init_world
    
    # Initialiser les textures
    init_textures
    
    # Masquer le curseur
    tput civis
    
    # Nettoyer l'écran
    clear
    
    echo "Initialisation terminée. Démarrage de l'éditeur..."
    sleep 1
}

# Nettoyage à la fin du programme
function cleanup_editor() {
    # Restaurer le terminal
    tput cnorm  # Rendre le curseur visible
    clear
    echo "Éditeur de niveaux fermé."
}

# Gestionnaires de signaux
trap cleanup_editor EXIT
trap "EDITOR_RUNNING=false" SIGINT SIGTERM

# Affichage de l'interface de l'éditeur
function display_editor_ui() {
    # Barre de titre en haut de l'écran
    tput cup 0 0
    echo -en "\e[7m $EDITOR_NAME v$VERSION - $(basename "$CURRENT_LEVEL_FILE") - Mode: $EDITOR_MODE $(printf '%*s' $((SCREEN_WIDTH - ${#EDITOR_NAME} - ${#VERSION} - ${#CURRENT_LEVEL_FILE} - ${#EDITOR_MODE} - 15)) "") \e[0m"
    
    # Barre d'état en bas de l'écran
    tput cup $((SCREEN_HEIGHT - 1)) 0
    echo -en "\e[7m Pos: ($CURSOR_X, $CURSOR_Y, $CURSOR_Z) | Objet: $CURRENT_OBJECT_TYPE | Texture: $CURRENT_TEXTURE | Échelle: $CURRENT_SCALE $(printf '%*s' $((SCREEN_WIDTH - 70)) "") \e[0m"
    
    # Coordonnées de la caméra
    tput cup 1 0
    echo "Caméra: (${CAMERA_X}, ${CAMERA_Y}, ${CAMERA_Z}) | Rot: (${CAMERA_ROT_X}, ${CAMERA_ROT_Y})"
    
    # Si un objet est sélectionné, afficher ses informations
    if (( SELECTED_OBJECT_ID >= 0 )); then
        tput cup 2 0
        echo "Objet sélectionné: ID=$SELECTED_OBJECT_ID, ${WORLD_OBJECTS[$SELECTED_OBJECT_ID]}"
    fi
    
    # Aide contextuelle
    tput cup $((SCREEN_HEIGHT - 2)) 0
    case "$EDITOR_MODE" in
        "view")
            echo "WASD/QE: Déplacer caméra | Flèches: Rotation | F1: Aide | TAB: Changer de mode | G: Afficher/masquer grille"
            ;;
        "place")
            echo "WASD/QE: Déplacer curseur | T: Changer texture | O: Changer objet | +/-: Échelle | Espace: Placer | Del: Supprimer"
            ;;
        "select")
            echo "Flèches: Naviguer | Enter: Sélectionner | C: Copier | X: Couper | V: Coller | Del: Supprimer | E: Modifier"
            ;;
        "edit")
            echo "WASD/QE: Déplacer objet | T: Changer texture | +/-: Échelle | Enter: Confirmer | Esc: Annuler"
            ;;
    esac
}

# Dessiner la grille
function draw_grid() {
    if ! $SHOW_GRID; then
        return
    fi
    
    local grid_size=10
    local grid_step=$GRID_SIZE
    
    for ((i=-grid_size; i<=grid_size; i+=grid_step)); do
        for ((j=-grid_size; j<=grid_size; j+=grid_step)); do
            # Dessiner les lignes de la grille XZ (sol)
            draw_line_3d $i 0 -$grid_size $i 0 $grid_size
            draw_line_3d -$grid_size 0 $j $grid_size 0 $j
        done
    done
}

# Dessiner le curseur 3D
function draw_cursor() {
    if [[ "$EDITOR_MODE" == "place" || "$EDITOR_MODE" == "edit" ]]; then
        # Dessiner un marqueur à la position du curseur
        local cursor_size=0.2
        
        # Dessiner des lignes pour marquer la position
        draw_line_3d $(bc -l <<< "$CURSOR_X - $cursor_size") $CURSOR_Y $CURSOR_Z $(bc -l <<< "$CURSOR_X + $cursor_size") $CURSOR_Y $CURSOR_Z
        draw_line_3d $CURSOR_X $(bc -l <<< "$CURSOR_Y - $cursor_size") $CURSOR_Z $CURSOR_X $(bc -l <<< "$CURSOR_Y + $cursor_size") $CURSOR_Z
        draw_line_3d $CURSOR_X $CURSOR_Y $(bc -l <<< "$CURSOR_Z - $cursor_size") $CURSOR_X $CURSOR_Y $(bc -l <<< "$CURSOR_Z + $cursor_size")
        
        # Dessiner une prévisualisation de l'objet actuel
        if [[ "$EDITOR_MODE" == "place" ]]; then
            draw_textured_model "$CURRENT_OBJECT_TYPE" "$CURRENT_TEXTURE" $CURSOR_X $CURSOR_Y $CURSOR_Z $CURRENT_SCALE
        elif [[ "$EDITOR_MODE" == "edit" && $SELECTED_OBJECT_ID >= 0 ]]; then
            local obj_data=${WORLD_OBJECTS[$SELECTED_OBJECT_ID]}
            local type=$(echo $obj_data | cut -d' ' -f1)
            local scale=$(echo $obj_data | cut -d' ' -f5)
            draw_textured_model "$type" "$CURRENT_TEXTURE" $CURSOR_X $CURSOR_Y $CURSOR_Z $scale
        fi
    elif [[ "$EDITOR_MODE" == "select" && $SELECTED_OBJECT_ID >= 0 ]]; then
        # Dessiner un cadre autour de l'objet sélectionné
        local obj_data=${WORLD_OBJECTS[$SELECTED_OBJECT_ID]}
        local type=$(echo $obj_data | cut -d' ' -f1)
        local x=$(echo $obj_data | cut -d' ' -f2)
        local y=$(echo $obj_data | cut -d' ' -f3)
        local z=$(echo $obj_data | cut -d' ' -f4)
        local scale=$(echo $obj_data | cut -d' ' -f5)
        
        # Dessiner un cadre plus grand que l'objet
        local box_scale=$(bc -l <<< "$scale * 1.2")
        draw_wireframe_box $x $y $z $box_scale
    fi
}

# Dessiner une boîte filaire
function draw_wireframe_box() {
    local x=$1
    local y=$2
    local z=$3
    local scale=${4:-1.0}
    
    # Définir les 8 sommets du cube
    local half=$(bc -l <<< "$scale / 2")
    
    # Sommets du cube
    local x1=$(bc -l <<< "$x - $half")
    local y1=$(bc -l <<< "$y - $half")
    local z1=$(bc -l <<< "$z - $half")
    
    local x2=$(bc -l <<< "$x + $half")
    local y2=$(bc -l <<< "$y - $half")
    local z2=$(bc -l <<< "$z - $half")
    
    local x3=$(bc -l <<< "$x + $half")
    local y3=$(bc -l <<< "$y + $half")
    local z3=$(bc -l <<< "$z - $half")
    
    local x4=$(bc -l <<< "$x - $half")
    local y4=$(bc -l <<< "$y + $half")
    local z4=$(bc -l <<< "$z - $half")
    
    local x5=$(bc -l <<< "$x - $half")
    local y5=$(bc -l <<< "$y - $half")
    local z5=$(bc -l <<< "$z + $half")
    
    local x6=$(bc -l <<< "$x + $half")
    local y6=$(bc -l <<< "$y - $half")
    local z6=$(bc -l <<< "$z + $half")
    
    local x7=$(bc -l <<< "$x + $half")
    local y7=$(bc -l <<< "$y + $half")
    local z7=$(bc -l <<< "$z + $half")
    
    local x8=$(bc -l <<< "$x - $half")
    local y8=$(bc -l <<< "$y + $half")
    local z8=$(bc -l <<< "$z + $half")
    
    # Dessiner les 12 arêtes du cube
    draw_line_3d $x1 $y1 $z1 $x2 $y2 $z2
    draw_line_3d $x2 $y2 $z2 $x3 $y3 $z3
    draw_line_3d $x3 $y3 $z3 $x4 $y4 $z4
    draw_line_3d $x4 $y4 $z4 $x1 $y1 $z1
    
    draw_line_3d $x5 $y5 $z5 $x6 $y6 $z6
    draw_line_3d $x6 $y6 $z6 $x7 $y7 $z7
    draw_line_3d $x7 $y7 $z7 $x8 $y8 $z8
    draw_line_3d $x8 $y8 $z8 $x5 $y5 $z5
    
    draw_line_3d $x1 $y1 $z1 $x5 $y5 $z5
    draw_line_3d $x2 $y2 $z2 $x6 $y6 $z6
    draw_line_3d $x3 $y3 $z3 $x7 $y7 $z7
    draw_line_3d $x4 $y4 $z4 $x8 $y8 $z8
}

# Placer un objet à la position du curseur
function place_object() {
    add_object "$CURRENT_OBJECT_TYPE" $CURSOR_X $CURSOR_Y $CURSOR_Z $CURRENT_SCALE
}

# Supprimer l'objet sélectionné
function delete_selected_object() {
    if (( SELECTED_OBJECT_ID >= 0 )); then
        remove_object $SELECTED_OBJECT_ID
        SELECTED_OBJECT_ID=-1
    fi
}

# Changer de type d'objet
function cycle_object_type() {
    case "$CURRENT_OBJECT_TYPE" in
        "cube")
            CURRENT_OBJECT_TYPE="sphere"
            ;;
        "sphere")
            CURRENT_OBJECT_TYPE="cube"
            ;;
    esac
}

# Changer de texture
function cycle_texture() {
    local textures=("brick" "wood" "stone" "grass" "water" "metal" "lava")
    local current_idx=0
    
    # Trouver l'index actuel
    for i in "${!textures[@]}"; do
        if [[ "${textures[$i]}" == "$CURRENT_TEXTURE" ]]; then
            current_idx=$i
            break
        fi
    done
    
    # Passer à la suivante
    current_idx=$(( (current_idx + 1) % ${#textures[@]} ))
    CURRENT_TEXTURE="${textures[$current_idx]}"
}

# Copier l'objet sélectionné
function copy_selected_object() {
    if (( SELECTED_OBJECT_ID >= 0 )); then
        CLIPBOARD="${WORLD_OBJECTS[$SELECTED_OBJECT_ID]}"
    fi
}

# Couper l'objet sélectionné
function cut_selected_object() {
    if (( SELECTED_OBJECT_ID >= 0 )); then
        CLIPBOARD="${WORLD_OBJECTS[$SELECTED_OBJECT_ID]}"
        remove_object $SELECTED_OBJECT_ID
        SELECTED_OBJECT_ID=-1
    fi
}

# Coller l'objet du presse-papier
function paste_object() {
    if [[ -n "$CLIPBOARD" ]]; then
        local type=$(echo $CLIPBOARD | cut -d' ' -f1)
        local scale=$(echo $CLIPBOARD | cut -d' ' -f5)
        add_object "$type" $CURSOR_X $CURSOR_Y $CURSOR_Z $scale
    fi
}

# Sélectionner l'objet le plus proche du curseur
function select_closest_object() {
    local closest_id=-1
    local closest_distance=999999
    
    for obj_id in "${!WORLD_OBJECTS[@]}"; do
        local obj_data=${WORLD_OBJECTS[$obj_id]}
        
        # Extraire les données de l'objet
        local x=$(echo $obj_data | cut -d' ' -f2)
        local y=$(echo $obj_data | cut -d' ' -f3)
        local z=$(echo $obj_data | cut -d' ' -f4)
        
        # Calculer la distance au curseur
        local dx=$(bc -l <<< "$x - $CURSOR_X")
        local dy=$(bc -l <<< "$y - $CURSOR_Y")
        local dz=$(bc -l <<< "$z - $CURSOR_Z")
        local distance=$(bc -l <<< "sqrt($dx^2 + $dy^2 + $dz^2)")
        
        # Mettre à jour si c'est plus proche
        if (( $(bc -l <<< "$distance < $closest_distance") )); then
            closest_distance=$distance
            closest_id=$obj_id
        fi
    done
    
    SELECTED_OBJECT_ID=$closest_id
    
    # Si un objet a été sélectionné, mettre à jour le curseur
    if (( SELECTED_OBJECT_ID >= 0 )); then
        local obj_data=${WORLD_OBJECTS[$SELECTED_OBJECT_ID]}
        CURSOR_X=$(echo $obj_data | cut -d' ' -f2)
        CURSOR_Y=$(echo $obj_data | cut -d' ' -f3)
        CURSOR_Z=$(echo $obj_data | cut -d' ' -f4)
        CURRENT_SCALE=$(echo $obj_data | cut -d' ' -f5)
        CURRENT_OBJECT_TYPE=$(echo $obj_data | cut -d' ' -f1)
    fi
}

# Traiter les entrées pour l'éditeur
function process_editor_input() {
    # Lire les entrées clavier
    read_input
    
    # Gérer les entrées communes à tous les modes
    if $KEY_TAB_PRESSED; then
        # Changer de mode
        case "$EDITOR_MODE" in
            "view")
                EDITOR_MODE="place"
                ;;
            "place")
                EDITOR_MODE="select"
                ;;
            "select")
                EDITOR_MODE="view"
                ;;
            "edit")
                EDITOR_MODE="view"
                ;;
        esac
    fi
    
    if $KEY_G_PRESSED; then
        # Afficher/masquer la grille
        SHOW_GRID=!$SHOW_GRID
    fi
    
    if $KEY_F1_PRESSED; then
        # Afficher l'aide
        display_help
    }
    
    # Gérer les entrées spécifiques au mode
    case "$EDITOR_MODE" in
        "view")
            # Dans ce mode, les touches déplacent la caméra
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
            ;;
            
        "place")
            # Dans ce mode, les touches déplacent le curseur 3D
            if $KEY_W_PRESSED; then
                CURSOR_Z=$(bc -l <<< "$CURSOR_Z + $GRID_SIZE")
            fi
            
            if $KEY_S_PRESSED; then
                CURSOR_Z=$(bc -l <<< "$CURSOR_Z - $GRID_SIZE")
            fi
            
            if $KEY_A_PRESSED; then
                CURSOR_X=$(bc -l <<< "$CURSOR_X - $GRID_SIZE")
            fi
            
            if $KEY_D_PRESSED; then
                CURSOR_X=$(bc -l <<< "$CURSOR_X + $GRID_SIZE")
            fi
            
            if $KEY_Q_PRESSED; then
                CURSOR_Y=$(bc -l <<< "$CURSOR_Y - $GRID_SIZE")
            fi
            
            if $KEY_E_PRESSED; then
                CURSOR_Y=$(bc -l <<< "$CURSOR_Y + $GRID_SIZE")
            fi
            
            if $KEY_PLUS_PRESSED; then
                CURRENT_SCALE=$(bc -l <<< "$CURRENT_SCALE + 0.1")
            fi
            
            if $KEY_MINUS_PRESSED; then
                CURRENT_SCALE=$(bc -l <<< "$CURRENT_SCALE - 0.1")
                if (( $(bc -l <<< "$CURRENT_SCALE < 0.1") )); then
                    CURRENT_SCALE=0.1
                fi
            fi
            
            if $KEY_T_PRESSED; then
                cycle_texture
            fi
            
            if $KEY_O_PRESSED; then
                cycle_object_type
            fi
            
            if $KEY_SPACE_PRESSED; then
                place_object
            fi
            
            if $KEY_DEL_PRESSED; then
                select_closest_object
                delete_selected_object
            fi
            ;;
            
        "select")
            # Dans ce mode, les touches permettent de sélectionner et manipuler des objets
            if $KEY_UP_PRESSED || $KEY_DOWN_PRESSED || $KEY_LEFT_PRESSED || $KEY_RIGHT_PRESSED; then
                # Déplacer le curseur
                if $KEY_UP_PRESSED; then
                    CURSOR_Z=$(bc -l <<< "$CURSOR_Z + $GRID_SIZE")
                fi
                
                if $KEY_DOWN_PRESSED; then
                    CURSOR_Z=$(bc -l <<< "$CURSOR_Z - $GRID_SIZE")
                fi
                
                if $KEY_LEFT_PRESSED; then
                    CURSOR_X=$(bc -l <<< "$CURSOR_X - $GRID_SIZE")
                fi
                
                if $KEY_RIGHT_PRESSED; then
                    CURSOR_X=$(bc -l <<< "$CURSOR_X + $GRID_SIZE")
                fi
            fi
            
            if $KEY_ENTER_PRESSED; then
                select_closest_object
            fi
            
            if $KEY_C_PRESSED; then
                copy_selected_object
            fi
            
            if $KEY_X_PRESSED; then
                cut_selected_object
            fi
            
            if $KEY_V_PRESSED; then
                paste_object
            fi
            
            if $KEY_DEL_PRESSED; then
                delete_selected_object
            fi
            
            if $KEY_E_PRESSED && (( SELECTED_OBJECT_ID >= 0 )); then
                EDITOR_MODE="edit"
            fi
            ;;
            
        "edit")
            # Dans ce mode, les touches modifient l'objet sélectionné
            if (( SELECTED_OBJECT_ID >= 0 )); then
                if $KEY_W_PRESSED; then
                    CURSOR_Z=$(bc -l <<< "$CURSOR_Z + $GRID_SIZE")
                fi
                
                if $KEY_S_PRESSED; then
                    CURSOR_Z=$(bc -l <<< "$CURSOR_Z - $GRID_SIZE")
                fi
                
                if $KEY_A_PRESSED; then
                    CURSOR_X=$(bc -l <<< "$CURSOR_X - $GRID_SIZE")
                fi
                
                if $KEY_D_PRESSED; then
                    CURSOR_X=$(bc -l <<< "$CURSOR_X + $GRID_SIZE")
                fi
                
                if $KEY_Q_PRESSED; then
                    CURSOR_Y=$(bc -l <<< "$CURSOR_Y - $GRID_SIZE")
                fi
                
                if $KEY_E_PRESSED; then
                    CURSOR_Y=$(bc -l <<< "$CURSOR_Y + $GRID_SIZE")
                fi
                
                if $KEY_PLUS_PRESSED; then
                    CURRENT_SCALE=$(bc -l <<< "$CURRENT_SCALE + 0.1")
                fi
                
                if $KEY_MINUS_PRESSED; then
                    CURRENT_SCALE=$(bc -l <<< "$CURRENT_SCALE - 0.1")
                    if (( $(bc -l <<< "$CURRENT_SCALE < 0.1") )); then
                        CURRENT_SCALE=0.1
                    fi
                fi
                
                if $KEY_T_PRESSED; then
                    cycle_texture
                }
                
                if $KEY_ENTER_PRESSED; then
                    # Appliquer les modifications
                    update_object_position $SELECTED_OBJECT_ID $CURSOR_X $CURSOR_Y $CURSOR_Z $CURRENT_SCALE
                    EDITOR_MODE="select"
                fi
                
                if $KEY_ESC_PRESSED; then
                    # Annuler les modifications
                    local obj_data=${WORLD_OBJECTS[$SELECTED_OBJECT_ID]}
                    CURSOR_X=$(echo $obj_data | cut -d' ' -f2)
                    CURSOR_Y=$(echo $obj_data | cut -d' ' -f3)
                    CURSOR_Z=$(echo $obj_data | cut -d' ' -f4)
                    CURRENT_SCALE=$(echo $obj_data | cut -d' ' -f5)
                    EDITOR_MODE="select"
                fi
            else
                EDITOR_MODE="select"
            fi
            ;;
    esac
    
    # Gérer les raccourcis de fichier
    if $KEY_CTRL_S_PRESSED; then
        save_level_dialog
    fi
    
    if $KEY_CTRL_O_PRESSED; then
        load_level_dialog
    fi
    
    if $KEY_CTRL_N_PRESSED; then
        new_level_dialog
    fi
}

# Afficher une boîte de dialogue
function display_dialog() {
    local title=$1
    local message=$2
    local input_prompt=${3:-""}
    local default_value=${4:-""}
    
    # Sauvegarder le contenu de l'écran
    tput smcup
    
    # Calculer les dimensions et position de la boîte
    local dialog_width=60
    local dialog_height=6
    local dialog_x=$(( (SCREEN_WIDTH - dialog_width) / 2 ))
    local dialog_y=$(( (SCREEN_HEIGHT - dialog_height) / 2 ))
    
    # Dessiner la boîte
    for ((y=0; y<dialog_height; y++)); do
        tput cup $((dialog_y + y)) $dialog_x
        
        if ((y == 0)); then
            # Ligne du haut
            echo -n "+"
            printf "%${dialog_width}s" | tr ' ' '-'
            echo -n "+"
        elif ((y == dialog_height-1)); then
            # Ligne du bas
            echo -n "+"
            printf "%${dialog_width}s" | tr ' ' '-'
            echo -n "+"
        else
            # Lignes du milieu
            echo -n "|"
            printf "%${dialog_width}s" | tr ' ' ' '
            echo -n "|"
        fi
    done
    
    # Afficher le titre
    tput cup $((dialog_y + 1)) $((dialog_x + 2))
    echo "$title"
    
    # Afficher le message
    tput cup $((dialog_y + 2)) $((dialog_x + 2))
    echo "$message"
    
    # Afficher le prompt d'entrée si nécessaire
    if [[ -n "$input_prompt" ]]; then
        tput cup $((dialog_y + 3)) $((dialog_x + 2))
        echo -n "$input_prompt "
        tput cup $((dialog_y + 3)) $((dialog_x + 2 + ${#input_prompt} + 1))
        echo -n "$default_value"
        
        # Activer le curseur
        tput cnorm
        
        # Lire l'entrée
        local input
        read -e input
        
        # Désactiver le curseur
        tput civis
        
        # Restaurer l'écran
        tput rmcup
        
        # Retourner l'entrée
        echo "$input"
    else
        # Afficher un message "Appuyez sur une touche pour continuer"
        tput cup $((dialog_y + 4)) $((dialog_x + 2))
        echo "Appuyez sur une touche pour continuer..."
        
        # Lire une touche
        read -n 1
        
        # Restaurer l'écran
        tput rmcup
    fi
}

# Boîte de dialogue pour sauvegarder un niveau
function save_level_dialog() {
    local default_file="$CURRENT_LEVEL_FILE"
    if [[ -z "$default_file" ]]; then
        default_file="level1.lvl"
    fi
    
    local filename=$(display_dialog "Sauvegarder le niveau" "Entrez le nom du fichier:" "Nom du fichier:" "$default_file")
    
    if [[ -n "$filename" ]]; then
        # Ajouter le chemin du répertoire
        local full_path="$SCRIPT_DIR/../assets/levels/$filename"
        
        # Créer le répertoire si nécessaire
        mkdir -p "$SCRIPT_DIR/../assets/levels"
        
        # Sauvegarder le niveau
        save_level "$full_path"
        
        # Mettre à jour le nom du fichier courant
        CURRENT_LEVEL_FILE="$filename"
        
        # Afficher un message de confirmation
        display_dialog "Niveau sauvegardé" "Le niveau a été sauvegardé dans $full_path"
    fi
}

# Boîte de dialogue pour charger un niveau
function load_level_dialog() {
    local default_file="$CURRENT_LEVEL_FILE"
    if [[ -z "$default_file" ]]; then
        default_file="level1.lvl"
    fi
    
    local filename=$(display_dialog "Charger un niveau" "Entrez le nom du fichier:" "Nom du fichier:" "$default_file")
    
    if [[ -n "$filename" ]]; then
        # Ajouter le chemin du répertoire
        local full_path="$SCRIPT_DIR/../assets/levels/$filename"
        
        # Vérifier si le fichier existe
        if [[ -f "$full_path" ]]; then
            # Charger le niveau
            load_level "$full_path"
            
            # Mettre à jour le nom du fichier courant
            CURRENT_LEVEL_FILE="$filename"
            
            # Afficher un message de confirmation
            display_dialog "Niveau chargé" "Le niveau a été chargé depuis $full_path"
        else
            # Afficher un message d'erreur
            display_dialog "Erreur" "Le fichier $full_path n'existe pas."
        fi
    fi
}

# Boîte de dialogue pour créer un nouveau niveau
function new_level_dialog() {
    local response=$(display_dialog "Nouveau niveau" "Voulez-vous créer un nouveau niveau? Toutes les modifications non sauvegardées seront perdues." "Confirmer (o/n):" "o")
    
    if [[ "$response" == "o" || "$response" == "O" || "$response" == "oui" || "$response" == "Oui" || "$response" == "y" || "$response" == "Y" || "$response" == "yes" || "$response" == "Yes" ]]; then
        # Réinitialiser le monde
        WORLD_OBJECTS=()
        
        # Réinitialiser le nom du fichier courant
        CURRENT_LEVEL_FILE=""
        
        # Réinitialiser le curseur
        CURSOR_X=0
        CURSOR_Y=0
        CURSOR_Z=0
        
        # Afficher un message de confirmation
        display_dialog "Nouveau niveau" "Un nouveau niveau vide a été créé."
    fi
}

# Afficher l'aide
function display_help() {
    # Sauvegarder l'écran actuel
    tput smcup
    
    # Effacer l'écran
    clear
    
    # Afficher l'aide
    echo "===== $EDITOR_NAME - Aide ====="
    echo ""
    echo "Raccourcis généraux:"
    echo "  TAB          : Changer de mode (Vue -> Placement -> Sélection -> Vue)"
    echo "  F1           : Afficher cette aide"
    echo "  G            : Afficher/masquer la grille"
    echo "  Ctrl+S       : Sauvegarder le niveau"
    echo "  Ctrl+O       : Charger un niveau"
    echo "  Ctrl+N       : Nouveau niveau"
    echo "  Échap        : Quitter l'éditeur"
    echo ""
    echo "Mode Vue:"
    echo "  WASD         : Déplacer la caméra horizontalement"
    echo "  Q/E          : Monter/descendre la caméra"
    echo "  Flèches      : Rotation de la caméra"
    echo ""
    echo "Mode Placement:"
    echo "  WASD         : Déplacer le curseur horizontalement"
    echo "  Q/E          : Monter/descendre le curseur"
    echo "  T            : Changer de texture"
    echo "  O            : Changer de type d'objet"
    echo "  +/-          : Augmenter/réduire l'échelle"
    echo "  Espace       : Placer un objet"
    echo "  Del          : Supprimer l'objet sous le curseur"
    echo ""
    echo "Mode Sélection:"
    echo "  Flèches      : Déplacer le curseur"
    echo "  Entrée       : Sélectionner l'objet le plus proche"
    echo "  C            : Copier l'objet sélectionné"
    echo "  X            : Couper l'objet sélectionné"
    echo "  V            : Coller l'objet à la position du curseur"
    echo "  Del          : Supprimer l'objet sélectionné"
    echo "  E            : Éditer l'objet sélectionné"
    echo ""
    echo "Mode Édition:"
    echo "  WASD         : Déplacer l'objet horizontalement"
    echo "  Q/E          : Monter/descendre l'objet"
    echo "  T            : Changer de texture"
    echo "  +/-          : Augmenter/réduire l'échelle"
    echo "  Entrée       : Confirmer les modifications"
    echo "  Échap        : Annuler les modifications"
    echo ""
    echo "Appuyez sur une touche pour revenir à l'éditeur..."
    
    # Attendre une touche
    read -n 1
    
    # Restaurer l'écran
    tput rmcup
}

# Boucle principale de l'éditeur
function editor_loop() {
    while $EDITOR_RUNNING; do
        # Effacer le buffer
        clear_buffer
        
        # Traiter les entrées utilisateur
        process_editor_input
        
        # Dessiner la grille
        draw_grid
        
        # Dessiner les objets du monde
        draw_world_objects
        
        # Dessiner le curseur 3D
        draw_cursor
        
        # Afficher l'interface utilisateur
        display_editor_ui
        
        # Afficher le buffer à l'écran
        render_buffer
        
        # Attendre pour maintenir le FPS
        sleep $INTERVAL
    done
}

# Point d'entrée du programme
function main() {
    initialize_editor
    editor_loop
    cleanup_editor
}

# Lancer l'éditeur
main
