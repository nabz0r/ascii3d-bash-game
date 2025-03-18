#!/bin/bash
#
# Système de sauvegarde et chargement pour ASCII3D-Bash-Game
#

# Répertoire des sauvegardes
SAVE_DIR="$SCRIPT_DIR/../saves"

# Fonction pour sauvegarder l'état du jeu
function save_game() {
    local save_name=$1
    
    # Créer le répertoire de sauvegarde s'il n'existe pas
    mkdir -p "$SAVE_DIR"
    
    # Chemin du fichier de sauvegarde
    local save_file="$SAVE_DIR/${save_name}.save"
    
    # Créer un fichier temporaire
    local temp_file=$(mktemp)
    
    # Écrire les informations d'en-tête
    echo "# ASCII3D-Bash-Game - Fichier de sauvegarde" > "$temp_file"
    echo "# Date: $(date)" >> "$temp_file"
    echo "# Version: $VERSION" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Sauvegarder la position et rotation de la caméra
    echo "[CAMERA]" >> "$temp_file"
    echo "CAMERA_X=$CAMERA_X" >> "$temp_file"
    echo "CAMERA_Y=$CAMERA_Y" >> "$temp_file"
    echo "CAMERA_Z=$CAMERA_Z" >> "$temp_file"
    echo "CAMERA_ROT_X=$CAMERA_ROT_X" >> "$temp_file"
    echo "CAMERA_ROT_Y=$CAMERA_ROT_Y" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Sauvegarder les objets du monde
    echo "[WORLD_OBJECTS]" >> "$temp_file"
    for obj_id in "${!WORLD_OBJECTS[@]}"; do
        echo "WORLD_OBJECTS[$obj_id]=${WORLD_OBJECTS[$obj_id]}" >> "$temp_file"
    done
    echo "" >> "$temp_file"
    
    # Sauvegarder les entités
    echo "[ENTITIES]" >> "$temp_file"
    for key in "${!ENTITIES[@]}"; do
        echo "ENTITIES[$key]=${ENTITIES[$key]}" >> "$temp_file"
    done
    echo "" >> "$temp_file"
    
    # Sauvegarder les statistiques du joueur
    echo "[PLAYER_STATS]" >> "$temp_file"
    echo "PLAYER_HEALTH=$PLAYER_HEALTH" >> "$temp_file"
    echo "PLAYER_SCORE=$PLAYER_SCORE" >> "$temp_file"
    echo "PLAYER_LEVEL=$PLAYER_LEVEL" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Sauvegarder l'inventaire du joueur
    echo "[PLAYER_INVENTORY]" >> "$temp_file"
    for item_id in "${!PLAYER_INVENTORY[@]}"; do
        echo "PLAYER_INVENTORY[$item_id]=${PLAYER_INVENTORY[$item_id]}" >> "$temp_file"
    done
    echo "" >> "$temp_file"
    
    # Sauvegarder l'état des quêtes
    echo "[QUESTS]" >> "$temp_file"
    for quest_id in "${!QUESTS[@]}"; do
        echo "QUESTS[$quest_id]=${QUESTS[$quest_id]}" >> "$temp_file"
    done
    echo "" >> "$temp_file"
    
    # Sauvegarder le temps de jeu
    echo "[GAME_TIME]" >> "$temp_file"
    echo "GAME_TIME=$GAME_TIME" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Déplacer le fichier temporaire vers le fichier de sauvegarde
    mv "$temp_file" "$save_file"
    
    echo "Partie sauvegardée dans $save_file"
    return 0
}

# Fonction pour charger l'état du jeu depuis une sauvegarde
function load_game() {
    local save_name=$1
    
    # Chemin du fichier de sauvegarde
    local save_file="$SAVE_DIR/${save_name}.save"
    
    # Vérifier si le fichier existe
    if [ ! -f "$save_file" ]; then
        echo "Erreur: Fichier de sauvegarde non trouvé: $save_file"
        return 1
    fi
    
    # Réinitialiser les variables du jeu
    WORLD_OBJECTS=()
    ENTITIES=()
    PLAYER_INVENTORY=()
    QUESTS=()
    
    # Variables pour suivre la section en cours
    local current_section=""
    
    # Lire le fichier ligne par ligne
    while IFS= read -r line; do
        # Ignorer les lignes vides et les commentaires
        if [[ -z "$line" || "$line" == \#* ]]; then
            continue
        fi
        
        # Vérifier si c'est une ligne de section
        if [[ "$line" == \[*\] ]]; then
            current_section="${line:1:${#line}-2}"
            continue
        fi
        
        # Traiter la ligne en fonction de la section
        case "$current_section" in
            "CAMERA")
                # Charger les données de la caméra
                eval "$line"
                ;;
            "WORLD_OBJECTS")
                # Charger les objets du monde
                eval "$line"
                ;;
            "ENTITIES")
                # Charger les entités
                eval "$line"
                ;;
            "PLAYER_STATS")
                # Charger les statistiques du joueur
                eval "$line"
                ;;
            "PLAYER_INVENTORY")
                # Charger l'inventaire du joueur
                eval "$line"
                ;;
            "QUESTS")
                # Charger l'état des quêtes
                eval "$line"
                ;;
            "GAME_TIME")
                # Charger le temps de jeu
                eval "$line"
                ;;
        esac
    done < "$save_file"
    
    echo "Partie chargée depuis $save_file"
    return 0
}

# Fonction pour lister les fichiers de sauvegarde disponibles
function list_save_files() {
    # Créer le répertoire de sauvegarde s'il n'existe pas
    mkdir -p "$SAVE_DIR"
    
    # Lister tous les fichiers .save dans le répertoire
    for file in "$SAVE_DIR"/*.save; do
        if [ -f "$file" ]; then
            # Extraire le nom de base (sans le chemin ni l'extension)
            basename "${file%.save}" "${file##*/}"
        fi
    done
}

# Fonction pour obtenir les informations sur une sauvegarde
function get_save_info() {
    local save_name=$1
    
    # Chemin du fichier de sauvegarde
    local save_file="$SAVE_DIR/${save_name}.save"
    
    # Vérifier si le fichier existe
    if [ ! -f "$save_file" ]; then
        echo "$save_name (Fichier non trouvé)"
        return 1
    fi
    
    # Extraire les informations de base
    local date_line=$(grep "# Date:" "$save_file" | head -n 1)
    local date_info=${date_line#"# Date: "}
    
    # Extraire d'autres informations utiles
    local level_line=$(grep "PLAYER_LEVEL=" "$save_file" | head -n 1)
    local level_info=${level_line#"PLAYER_LEVEL="}
    
    local score_line=$(grep "PLAYER_SCORE=" "$save_file" | head -n 1)
    local score_info=${score_line#"PLAYER_SCORE="}
    
    local time_line=$(grep "GAME_TIME=" "$save_file" | head -n 1)
    local time_info=${time_line#"GAME_TIME="}
    
    # Formater les informations
    echo "$save_name - Niveau $level_info - Score $score_info - $date_info"
}

# Fonction pour supprimer une sauvegarde
function delete_save() {
    local save_name=$1
    
    # Chemin du fichier de sauvegarde
    local save_file="$SAVE_DIR/${save_name}.save"
    
    # Vérifier si le fichier existe
    if [ ! -f "$save_file" ]; then
        echo "Erreur: Fichier de sauvegarde non trouvé: $save_file"
        return 1
    fi
    
    # Supprimer le fichier
    rm "$save_file"
    
    echo "Sauvegarde supprimée: $save_file"
    return 0
}

# Fonction pour afficher une boîte de dialogue de sauvegarde
function save_game_dialog() {
    # Sauvegarder l'écran
    tput smcup
    
    # Effacer l'écran
    clear
    
    # Dessiner l'en-tête
    local header="Sauvegarder la partie"
    local header_x=$((SCREEN_WIDTH / 2 - ${#header} / 2))
    
    echo -e "\n\n"
    echo -e "$(printf '%*s' $header_x '')$header"
    echo -e "$(printf '%*s' $header_x '')$(printf '%*s' ${#header} '' | tr ' ' '=')"
    echo -e "\n\n"
    
    # Demander le nom de la sauvegarde
    local prompt="Entrez un nom pour cette sauvegarde:"
    local prompt_x=$((SCREEN_WIDTH / 2 - ${#prompt} / 2))
    
    echo -e "$(printf '%*s' $prompt_x '')$prompt"
    echo -e "\n"
    
    # Afficher un champ de saisie
    local input_field="[                              ]"
    local input_x=$((SCREEN_WIDTH / 2 - ${#input_field} / 2))
    
    echo -e "$(printf '%*s' $input_x '')$input_field"
    
    # Positionner le curseur dans le champ
    tput cup $((SCREEN_HEIGHT / 2 + 2)) $((input_x + 1))
    
    # Rendre le curseur visible
    tput cnorm
    
    # Lire l'entrée
    local save_name
    read -e save_name
    
    # Masquer le curseur
    tput civis
    
    # Vérifier si le nom est vide
    if [ -z "$save_name" ]; then
        # Afficher un message d'erreur
        local error="Le nom de sauvegarde ne peut pas être vide."
        local error_x=$((SCREEN_WIDTH / 2 - ${#error} / 2))
        
        echo -e "\n\n"
        echo -e "$(printf '%*s' $error_x '')$error"
        
        # Attendre une touche
        echo -e "\n"
        echo -e "$(printf '%*s' $error_x '')Appuyez sur une touche pour continuer..."
        read -n 1 -s
        
        # Restaurer l'écran
        tput rmcup
        return 1
    fi
    
    # Sauvegarder la partie
    save_game "$save_name"
    
    # Afficher un message de confirmation
    local confirm="Partie sauvegardée avec succès!"
    local confirm_x=$((SCREEN_WIDTH / 2 - ${#confirm} / 2))
    
    echo -e "\n\n"
    echo -e "$(printf '%*s' $confirm_x '')$confirm"
    
    # Attendre une touche
    echo -e "\n"
    echo -e "$(printf '%*s' $confirm_x '')Appuyez sur une touche pour continuer..."
    read -n 1 -s
    
    # Restaurer l'écran
    tput rmcup
    return 0
}

# Fonction pour automatiser les sauvegardes
function auto_save() {
    local auto_save_file="autosave"
    
    # Sauvegarder silencieusement
    save_game "$auto_save_file" > /dev/null
}

# Créer le répertoire de sauvegarde s'il n'existe pas
mkdir -p "$SAVE_DIR"
