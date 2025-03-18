#!/bin/bash
#
# Système d'affichage HUD (Heads-Up Display) pour ASCII3D-Bash-Game
#

# Configuration du HUD
HUD_ENABLED=true
HUD_STYLE="minimal"  # Options: minimal, full, off
HUD_COLOR=true
HUD_OPACITY=100  # En pourcentage (0-100)

# Positions des éléments du HUD
HUD_STATS_TOP=0
HUD_STATS_LEFT=0
HUD_QUEST_TOP=0
HUD_QUEST_RIGHT=0
HUD_MINIMAP_BOTTOM=3
HUD_MINIMAP_RIGHT=3
HUD_FPS_BOTTOM=0
HUD_FPS_RIGHT=0
HUD_COMPASS_TOP=1
HUD_COMPASS_CENTER=1

# Couleurs pour le HUD (codes ANSI)
declare -A HUD_COLORS
HUD_COLORS["health"]="\e[31m"    # Rouge
HUD_COLORS["mana"]="\e[34m"      # Bleu
HUD_COLORS["stamina"]="\e[32m"   # Vert
HUD_COLORS["xp"]="\e[33m"        # Jaune
HUD_COLORS["gold"]="\e[33m"      # Jaune
HUD_COLORS["quest"]="\e[35m"     # Magenta
HUD_COLORS["warning"]="\e[31m"   # Rouge
HUD_COLORS["info"]="\e[36m"      # Cyan
HUD_COLORS["title"]="\e[1;37m"   # Blanc gras
HUD_COLORS["normal"]="\e[0m"     # Normal (réinitialisation)

# Messages et notifications du HUD
declare -a HUD_NOTIFICATIONS
HUD_NOTIFICATION_DURATION=5  # En secondes
HUD_NOTIFICATION_TIME=0

# Initialisation du HUD
function init_hud() {
    echo "Initialisation du système HUD..."
    
    # Calculer les positions en fonction de la taille de l'écran
    HUD_STATS_LEFT=2
    HUD_STATS_TOP=2
    
    HUD_QUEST_RIGHT=$((SCREEN_WIDTH - 2))
    HUD_QUEST_TOP=2
    
    HUD_MINIMAP_RIGHT=$((SCREEN_WIDTH - 2))
    HUD_MINIMAP_BOTTOM=$((SCREEN_HEIGHT - 10))
    
    HUD_FPS_RIGHT=$((SCREEN_WIDTH - 10))
    HUD_FPS_BOTTOM=$((SCREEN_HEIGHT - 2))
    
    HUD_COMPASS_TOP=3
    HUD_COMPASS_CENTER=$((SCREEN_WIDTH / 2))
    
    # Vérifier les options du jeu
    if [[ -n "${GAME_OPTIONS["hud_style"]}" ]]; then
        HUD_STYLE=${GAME_OPTIONS["hud_style"]}
    fi
    
    if [[ -n "${GAME_OPTIONS["hud_color"]}" ]]; then
        HUD_COLOR=${GAME_OPTIONS["hud_color"]}
    fi
    
    if [[ -n "${GAME_OPTIONS["hud_opacity"]}" ]]; then
        HUD_OPACITY=${GAME_OPTIONS["hud_opacity"]}
    fi
    
    echo "Système HUD initialisé. Style: $HUD_STYLE, Couleur: $HUD_COLOR"
}

# Fonction utilitaire pour appliquer une couleur si activé
function hud_color() {
    local color_key=$1
    local text=$2
    
    if $HUD_COLOR; then
        echo -n "${HUD_COLORS[$color_key]}$text${HUD_COLORS["normal"]}"
    else
        echo -n "$text"
    fi
}

# Afficher le HUD des statistiques du joueur
function display_hud_stats() {
    if ! $HUD_ENABLED || [[ "$HUD_STYLE" == "off" ]]; then
        return
    fi
    
    local x=$HUD_STATS_LEFT
    local y=$HUD_STATS_TOP
    
    # Statistiques de base (toujours affichées)
    local health_bar=$(create_bar $PLAYER_HEALTH $PLAYER_MAX_HEALTH 15 "█" "░" "health")
    local mana_bar=$(create_bar $PLAYER_MANA $PLAYER_MAX_MANA 15 "█" "░" "mana")
    
    # Afficher les statistiques
    tput cup $y $x
    echo -n "$(hud_color "title" "PV:") $health_bar"
    
    tput cup $((y+1)) $x
    echo -n "$(hud_color "title" "MP:") $mana_bar"
    
    if [[ "$HUD_STYLE" == "full" ]]; then
        # Style complet : afficher plus de statistiques
        local xp_bar=$(create_bar $PLAYER_XP $PLAYER_NEXT_LEVEL_XP 15 "█" "░" "xp")
        
        tput cup $((y+2)) $x
        echo -n "$(hud_color "title" "Nv:") $(hud_color "info" "$PLAYER_LEVEL")"
        
        tput cup $((y+3)) $x
        echo -n "$(hud_color "title" "XP:") $xp_bar"
        
        tput cup $((y+4)) $x
        echo -n "$(hud_color "title" "Or:") $(hud_color "gold" "$PLAYER_GOLD")"
        
        tput cup $((y+5)) $x
        echo -n "$(hud_color "title" "ATT:") $(hud_color "normal" "$PLAYER_DAMAGE")"
        
        tput cup $((y+6)) $x
        echo -n "$(hud_color "title" "DEF:") $(hud_color "normal" "$PLAYER_DEFENSE")"
    else
        # Style minimal : seulement le niveau et l'or
        tput cup $((y+2)) $x
        echo -n "$(hud_color "title" "Nv:") $(hud_color "info" "$PLAYER_LEVEL") $(hud_color "title" "Or:") $(hud_color "gold" "$PLAYER_GOLD")"
    fi
}

# Créer une barre de progression
function create_bar() {
    local current=$1
    local maximum=$2
    local length=$3
    local fill_char=$4
    local empty_char=$5
    local color_key=$6
    
    # Calculer le nombre de caractères pleins
    local fill_length=$(bc <<< "scale=0; $current * $length / $maximum / 1")
    
    # S'assurer que la longueur est valide
    if (( fill_length > length )); then
        fill_length=$length
    elif (( fill_length < 0 )); then
        fill_length=0
    fi
    
    # Calculer le nombre de caractères vides
    local empty_length=$((length - fill_length))
    
    # Construire la barre
    local bar=""
    
    if $HUD_COLOR; then
        bar="${HUD_COLORS[$color_key]}"
        bar+=$(printf "%*s" $fill_length | tr ' ' "$fill_char")
        bar+="${HUD_COLORS["normal"]}"
        bar+=$(printf "%*s" $empty_length | tr ' ' "$empty_char")
    else
        bar+=$(printf "%*s" $fill_length | tr ' ' "$fill_char")
        bar+=$(printf "%*s" $empty_length | tr ' ' "$empty_char")
    fi
    
    local percent=$(bc <<< "scale=0; $current * 100 / $maximum / 1")
    
    echo -n "$bar $current/$maximum ($percent%)"
}

# Afficher le HUD des quêtes
function display_hud_quests() {
    if ! $HUD_ENABLED || [[ "$HUD_STYLE" == "off" ]]; then
        return
    fi
    
    # Obtenir les quêtes actives
    local active_quests=($(get_active_quests))
    
    if [[ ${#active_quests[@]} -eq 0 ]]; then
        return
    fi
    
    local y=$HUD_QUEST_TOP
    
    # Afficher le titre
    tput cup $y $((HUD_QUEST_RIGHT - 20))
    echo -n "$(hud_color "title" "QUÊTES ACTIVES")"
    
    # Si style minimal, montrer seulement la première quête
    local quest_limit=1
    if [[ "$HUD_STYLE" == "full" ]]; then
        quest_limit=3  # Montrer jusqu'à 3 quêtes en mode complet
    fi
    
    local quest_count=0
    
    for quest_id in "${active_quests[@]}"; do
        if (( quest_count >= quest_limit )); then
            break
        fi
        
        local quest_name=${QUESTS["$quest_id,name"]}
        
        tput cup $((y + quest_count + 1)) $((HUD_QUEST_RIGHT - 20))
        echo -n "$(hud_color "quest" "• $quest_name")"
        
        # Afficher le premier objectif non terminé
        local obj_count=${QUESTS["$quest_id,objective_count"]}
        
        for ((i=1; i<=obj_count; i++)); do
            if [[ "${QUEST_OBJECTIVES["$quest_id,$i,completed"]}" != "true" ]]; then
                local obj_desc=${QUEST_OBJECTIVES["$quest_id,$i,description"]}
                local obj_progress=${QUEST_OBJECTIVES["$quest_id,$i,progress"]}
                local obj_target=${QUEST_OBJECTIVES["$quest_id,$i,target"]}
                
                # Tronquer la description si nécessaire
                if (( ${#obj_desc} > 30 )); then
                    obj_desc="${obj_desc:0:27}..."
                fi
                
                tput cup $((y + quest_count + 2)) $((HUD_QUEST_RIGHT - 18))
                echo -n "$(hud_color "normal" "$obj_desc ($obj_progress/$obj_target)")"
                
                break
            fi
        done
        
        ((quest_count++))
    done
    
    # Si en mode complet et qu'il y a plus de quêtes que le nombre affiché
    if [[ "$HUD_STYLE" == "full" && ${#active_quests[@]} -gt $quest_limit ]]; then
        tput cup $((y + quest_count + 2)) $((HUD_QUEST_RIGHT - 20))
        echo -n "$(hud_color "info" "...et ${#active_quests[@]} - $quest_limit autres.")"
    fi
}

# Afficher une mini-carte
function display_hud_minimap() {
    if ! $HUD_ENABLED || [[ "$HUD_STYLE" == "off" ]]; then
        return
    fi
    
    if [[ "$HUD_STYLE" == "minimal" ]]; then
        return  # Pas de mini-carte en mode minimal
    fi
    
    local map_width=15
    local map_height=8
    
    local x=$((HUD_MINIMAP_RIGHT - map_width))
    local y=$((SCREEN_HEIGHT - HUD_MINIMAP_BOTTOM - map_height))
    
    # Cadre de la mini-carte
    tput cup $y $x
    echo -n "┌$(printf "%*s" $map_width | tr ' ' '─')┐"
    
    for ((i=1; i<=map_height; i++)); do
        tput cup $((y+i)) $x
        echo -n "│$(printf "%*s" $map_width)│"
    done
    
    tput cup $((y+map_height+1)) $x
    echo -n "└$(printf "%*s" $map_width | tr ' ' '─')┘"
    
    # Titre de la mini-carte
    tput cup $y $((x + (map_width - 10) / 2))
    echo -n "$(hud_color "title" " MINI-CARTE ")"
    
    # Position du joueur (au centre)
    local player_map_x=$((x + map_width / 2))
    local player_map_y=$((y + map_height / 2))
    
    tput cup $player_map_y $player_map_x
    echo -n "$(hud_color "info" "P")"
    
    # Placer les objets proches sur la carte
    for obj_id in "${!WORLD_OBJECTS[@]}"; do
        local obj_data=${WORLD_OBJECTS[$obj_id]}
        
        # Extraire les données de l'objet
        local obj_x=$(echo $obj_data | cut -d' ' -f2)
        local obj_z=$(echo $obj_data | cut -d' ' -f4)
        
        # Calculer la position relative
        local rel_x=$(bc <<< "scale=0; ($obj_x - $CAMERA_X) / $GRID_SIZE / 1")
        local rel_z=$(bc <<< "scale=0; ($obj_z - $CAMERA_Z) / $GRID_SIZE / 1")
        
        # Limiter à la taille de la carte
        if (( rel_x >= -map_width/2 && rel_x <= map_width/2 && rel_z >= -map_height/2 && rel_z <= map_height/2 )); then
            local map_obj_x=$((player_map_x + rel_x))
            local map_obj_y=$((player_map_y + rel_z))
            
            tput cup $map_obj_y $map_obj_x
            echo -n "$(hud_color "normal" "o")"
        fi
    done
    
    # Placer les ennemis sur la carte
    for key in "${!ACTIVE_ENEMIES[@]}"; do
        if [[ "$key" == *",active" && "${ACTIVE_ENEMIES[$key]}" == "true" ]]; then
            local enemy_id="${key%,active}"
            
            # Obtenir la position de l'ennemi
            local enemy_x=${ACTIVE_ENEMIES["$enemy_id,x"]}
            local enemy_z=${ACTIVE_ENEMIES["$enemy_id,z"]}
            
            # Calculer la position relative
            local rel_x=$(bc <<< "scale=0; ($enemy_x - $CAMERA_X) / $GRID_SIZE / 1")
            local rel_z=$(bc <<< "scale=0; ($enemy_z - $CAMERA_Z) / $GRID_SIZE / 1")
            
            # Limiter à la taille de la carte
            if (( rel_x >= -map_width/2 && rel_x <= map_width/2 && rel_z >= -map_height/2 && rel_z <= map_height/2 )); then
                local map_enemy_x=$((player_map_x + rel_x))
                local map_enemy_y=$((player_map_y + rel_z))
                
                tput cup $map_enemy_y $map_enemy_x
                echo -n "$(hud_color "warning" "X")"
            fi
        fi
    done
}

# Afficher une boussole
function display_hud_compass() {
    if ! $HUD_ENABLED || [[ "$HUD_STYLE" == "off" ]]; then
        return
    fi
    
    local compass_width=9
    local x=$((HUD_COMPASS_CENTER - compass_width / 2))
    local y=$HUD_COMPASS_TOP
    
    # Convertir l'angle en degrés (de 0 à 360)
    local degrees=$(bc <<< "scale=0; ($CAMERA_ROT_Y * 180 / 3.14159) % 360 / 1")
    
    # Déterminer la direction principale
    local direction=""
    if (( degrees >= 337 || degrees < 22 )); then
        direction="N"
    elif (( degrees >= 22 && degrees < 67 )); then
        direction="NE"
    elif (( degrees >= 67 && degrees < 112 )); then
        direction="E"
    elif (( degrees >= 112 && degrees < 157 )); then
        direction="SE"
    elif (( degrees >= 157 && degrees < 202 )); then
        direction="S"
    elif (( degrees >= 202 && degrees < 247 )); then
        direction="SO"
    elif (( degrees >= 247 && degrees < 292 )); then
        direction="O"
    elif (( degrees >= 292 && degrees < 337 )); then
        direction="NO"
    fi
    
    # Afficher la boussole
    tput cup $y $x
    echo -n "$(hud_color "normal" "[")"
    
    for ((i=0; i<compass_width; i++)); do
        local compass_char=""
        
        if (( i == compass_width / 2 )); then
            compass_char="$(hud_color "info" "$direction")"
        else
            compass_char="$(hud_color "normal" "·")"
        fi
        
        echo -n "$compass_char"
    done
    
    echo -n "$(hud_color "normal" "]")"
    
    # Afficher les degrés en dessous
    tput cup $((y+1)) $((x + compass_width/2 - 1))
    echo -n "$(hud_color "normal" "${degrees}°")"
}

# Afficher le FPS
function display_hud_fps() {
    if ! $HUD_ENABLED || [[ "$HUD_STYLE" == "off" ]]; then
        return
    fi
    
    local x=$((SCREEN_WIDTH - 10))
    local y=$((SCREEN_HEIGHT - 2))
    
    tput cup $y $x
    echo -n "$(hud_color "normal" "FPS: $current_fps")"
}

# Afficher une notification
function display_hud_notification() {
    if ! $HUD_ENABLED; then
        return
    fi
    
    local current_time=$(date +%s)
    
    # Supprimer les notifications expirées
    local i=0
    while (( i < ${#HUD_NOTIFICATIONS[@]} )); do
        local notification=${HUD_NOTIFICATIONS[$i]}
        local time_str=$(echo "$notification" | cut -d';' -f1)
        
        if (( current_time - time_str > HUD_NOTIFICATION_DURATION )); then
            # Supprimer cette notification
            unset HUD_NOTIFICATIONS[$i]
            HUD_NOTIFICATIONS=("${HUD_NOTIFICATIONS[@]}")
        else
            ((i++))
        fi
    done
    
    # Afficher les notifications actives
    local max_notifications=3
    local notification_width=40
    local notification_x=$((SCREEN_WIDTH / 2 - notification_width / 2))
    local notification_y=5
    
    for ((i=0; i<max_notifications && i<${#HUD_NOTIFICATIONS[@]}; i++)); do
        local notification=${HUD_NOTIFICATIONS[$i]}
        local time_str=$(echo "$notification" | cut -d';' -f1)
        local type=$(echo "$notification" | cut -d';' -f2)
        local message=$(echo "$notification" | cut -d';' -f3)
        
        # Calculer l'opacité en fonction du temps restant
        local time_left=$((HUD_NOTIFICATION_DURATION - (current_time - time_str)))
        local opacity=1.0
        
        if (( time_left <= 1 )); then
            opacity=0.5
        fi
        
        # Tronquer le message si nécessaire
        if (( ${#message} > notification_width )); then
            message="${message:0:notification_width-3}..."
        fi
        
        # Afficher la notification
        tput cup $((notification_y + i*2)) $notification_x
        
        case "$type" in
            "info")
                echo -n "$(hud_color "info" "ℹ️ $message")"
                ;;
            "warning")
                echo -n "$(hud_color "warning" "⚠️ $message")"
                ;;
            "success")
                echo -n "$(hud_color "normal" "✅ $message")"
                ;;
            *)
                echo -n "$(hud_color "normal" "$message")"
                ;;
        esac
    done
}

# Ajouter une notification
function add_notification() {
    local message=$1
    local type=${2:-"info"}  # info, warning, success
    
    local current_time=$(date +%s)
    local notification="$current_time;$type;$message"
    
    # Ajouter la notification au début du tableau
    HUD_NOTIFICATIONS=("$notification" "${HUD_NOTIFICATIONS[@]}")
    
    # Limiter le nombre de notifications
    if (( ${#HUD_NOTIFICATIONS[@]} > 10 )); then
        HUD_NOTIFICATIONS=("${HUD_NOTIFICATIONS[@]:0:10}")
    fi
}

# Afficher tout le HUD
function display_hud() {
    if ! $HUD_ENABLED || [[ "$HUD_STYLE" == "off" ]]; then
        return
    fi
    
    # Afficher les différentes parties du HUD
    display_hud_stats
    display_hud_quests
    display_hud_minimap
    display_hud_compass
    display_hud_fps
    display_hud_notification
}

# Changer le style du HUD
function set_hud_style() {
    local style=$1
    
    case "$style" in
        "minimal"|"full"|"off")
            HUD_STYLE="$style"
            ;;
        *)
            echo "Style de HUD invalide: $style. Options valides: minimal, full, off"
            return 1
            ;;
    esac
    
    # Sauvegarder dans les options
    GAME_OPTIONS["hud_style"]="$HUD_STYLE"
    
    return 0
}

# Activer/désactiver les couleurs du HUD
function set_hud_color() {
    local enabled=$1
    
    if [[ "$enabled" == "true" || "$enabled" == "false" ]]; then
        HUD_COLOR="$enabled"
        GAME_OPTIONS["hud_color"]="$HUD_COLOR"
    else
        echo "Valeur invalide pour les couleurs du HUD. Utilisez true ou false."
        return 1
    fi
    
    return 0
}

# Définir l'opacité du HUD
function set_hud_opacity() {
    local opacity=$1
    
    if (( opacity >= 0 && opacity <= 100 )); then
        HUD_OPACITY="$opacity"
        GAME_OPTIONS["hud_opacity"]="$HUD_OPACITY"
    else
        echo "Valeur d'opacité invalide. Utilisez une valeur entre 0 et 100."
        return 1
    fi
    
    return 0
}

# Montrer/cacher le HUD
function toggle_hud() {
    HUD_ENABLED=!$HUD_ENABLED
    
    if $HUD_ENABLED; then
        add_notification "HUD activé" "info"
    else
        # Effacer l'écran pour supprimer le HUD
        clear
    fi
}

# Initialiser le HUD
init_hud
