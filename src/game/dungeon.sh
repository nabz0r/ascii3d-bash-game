#!/bin/bash
#
# Générateur procédural de donjons pour ASCII3D-Bash-Game
#

# Configuration du générateur
DUNGEON_MIN_ROOMS=5
DUNGEON_MAX_ROOMS=15
DUNGEON_MIN_ROOM_SIZE=3
DUNGEON_MAX_ROOM_SIZE=8
DUNGEON_CORRIDOR_WIDTH=1
DUNGEON_GRID_SIZE=1.0
DUNGEON_WALL_HEIGHT=1.5
DUNGEON_CEILING_HEIGHT=2.0

# Types de tuiles
TILE_EMPTY=0
TILE_WALL=1
TILE_FLOOR=2
TILE_DOOR=3
TILE_STAIRS_UP=4
TILE_STAIRS_DOWN=5
TILE_CHEST=6
TILE_TRAP=7

# Structure du donjon
declare -A DUNGEON_MAP
DUNGEON_WIDTH=0
DUNGEON_HEIGHT=0
DUNGEON_ROOMS=()
DUNGEON_START_X=0
DUNGEON_START_Y=0
DUNGEON_START_Z=0
DUNGEON_EXIT_X=0
DUNGEON_EXIT_Y=0
DUNGEON_EXIT_Z=0

# Initialiser le générateur de donjons
function init_dungeon_generator() {
    echo "Initialisation du générateur de donjons..."
    
    # Initialiser le générateur de nombres aléatoires
    RANDOM=$$
    
    echo "Générateur de donjons initialisé."
}

# Générer un nouveau donjon
function generate_dungeon() {
    local width=$1
    local height=$2
    
    echo "Génération d'un donjon de taille ${width}x${height}..."
    
    # Réinitialiser les structures de données
    DUNGEON_MAP=()
    DUNGEON_ROOMS=()
    DUNGEON_WIDTH=$width
    DUNGEON_HEIGHT=$height
    
    # Initialiser la carte avec des tuiles vides
    for ((y=0; y<height; y++)); do
        for ((x=0; x<width; x++)); do
            DUNGEON_MAP["$x,$y"]=$TILE_EMPTY
        done
    done
    
    # Générer un nombre aléatoire de pièces
    local num_rooms=$((RANDOM % (DUNGEON_MAX_ROOMS - DUNGEON_MIN_ROOMS + 1) + DUNGEON_MIN_ROOMS))
    
    echo "Création de $num_rooms pièces..."
    
    # Générer les pièces
    for ((i=0; i<num_rooms; i++)); do
        generate_room
    done
    
    # Connecter les pièces
    connect_rooms
    
    # Placer l'entrée et la sortie
    place_entrance_exit
    
    # Ajouter des fonctionnalités
    add_features
    
    echo "Donjon généré avec $num_rooms pièces."
}

# Générer une pièce aléatoire
function generate_room() {
    # Déterminer la taille de la pièce
    local room_width=$((RANDOM % (DUNGEON_MAX_ROOM_SIZE - DUNGEON_MIN_ROOM_SIZE + 1) + DUNGEON_MIN_ROOM_SIZE))
    local room_height=$((RANDOM % (DUNGEON_MAX_ROOM_SIZE - DUNGEON_MIN_ROOM_SIZE + 1) + DUNGEON_MIN_ROOM_SIZE))
    
    # Déterminer la position de la pièce
    local room_x=$((RANDOM % (DUNGEON_WIDTH - room_width - 2) + 1))
    local room_y=$((RANDOM % (DUNGEON_HEIGHT - room_height - 2) + 1))
    
    # Vérifier s'il y a de la place pour la pièce
    local can_place=true
    
    for ((y=room_y-1; y<=room_y+room_height; y++)); do
        for ((x=room_x-1; x<=room_x+room_width; x++)); do
            if (( x < 0 || x >= DUNGEON_WIDTH || y < 0 || y >= DUNGEON_HEIGHT )); then
                can_place=false
                break
            fi
            
            if [[ "${DUNGEON_MAP["$x,$y"]}" != "$TILE_EMPTY" ]]; then
                can_place=false
                break
            fi
        done
        
        if ! $can_place; then
            break
        fi
    done
    
    # Si on ne peut pas placer la pièce, abandonner
    if ! $can_place; then
        return 1
    fi
    
    # Placer la pièce
    for ((y=room_y; y<room_y+room_height; y++)); do
        for ((x=room_x; x<room_x+room_width; x++)); do
            # Les murs sont sur les bords
            if (( x == room_x || x == room_x+room_width-1 || y == room_y || y == room_y+room_height-1 )); then
                DUNGEON_MAP["$x,$y"]=$TILE_WALL
            else
                DUNGEON_MAP["$x,$y"]=$TILE_FLOOR
            fi
        done
    done
    
    # Stocker les données de la pièce
    local room_id=${#DUNGEON_ROOMS[@]}
    DUNGEON_ROOMS["$room_id,x"]=$room_x
    DUNGEON_ROOMS["$room_id,y"]=$room_y
    DUNGEON_ROOMS["$room_id,width"]=$room_width
    DUNGEON_ROOMS["$room_id,height"]=$room_height
    DUNGEON_ROOMS["$room_id,connected"]=false
    
    return 0
}

# Connecter les pièces avec des couloirs
function connect_rooms() {
    local num_rooms=${#DUNGEON_ROOMS[@]}
    
    if (( num_rooms <= 1 )); then
        return
    fi
    
    # Marquer la première pièce comme connectée
    DUNGEON_ROOMS["0,connected"]=true
    
    # Connecter chaque pièce non connectée à une pièce connectée
    local connected_rooms=1
    
    while (( connected_rooms < num_rooms )); do
        # Trouver une pièce connectée
        local room1_id=-1
        
        for ((i=0; i<num_rooms; i++)); do
            if [[ "${DUNGEON_ROOMS["$i,connected"]}" == "true" ]]; then
                room1_id=$i
                break
            fi
        done
        
        # Trouver une pièce non connectée
        local room2_id=-1
        
        for ((i=0; i<num_rooms; i++)); do
            if [[ "${DUNGEON_ROOMS["$i,connected"]}" == "false" ]]; then
                room2_id=$i
                break
            fi
        done
        
        # Si on ne trouve pas de paires, sortir
        if (( room1_id == -1 || room2_id == -1 )); then
            break
        fi
        
        # Connecter les deux pièces
        connect_two_rooms $room1_id $room2_id
        
        # Marquer la deuxième pièce comme connectée
        DUNGEON_ROOMS["$room2_id,connected"]=true
        
        # Incrémenter le compteur
        ((connected_rooms++))
    done
}

# Connecter deux pièces spécifiques
function connect_two_rooms() {
    local room1_id=$1
    local room2_id=$2
    
    # Obtenir les centres des pièces
    local room1_x=$((${DUNGEON_ROOMS["$room1_id,x"]} + ${DUNGEON_ROOMS["$room1_id,width"]} / 2))
    local room1_y=$((${DUNGEON_ROOMS["$room1_id,y"]} + ${DUNGEON_ROOMS["$room1_id,height"]} / 2))
    
    local room2_x=$((${DUNGEON_ROOMS["$room2_id,x"]} + ${DUNGEON_ROOMS["$room2_id,width"]} / 2))
    local room2_y=$((${DUNGEON_ROOMS["$room2_id,y"]} + ${DUNGEON_ROOMS["$room2_id,height"]} / 2))
    
    # Décider si on va d'abord horizontalement puis verticalement, ou l'inverse
    if (( RANDOM % 2 == 0 )); then
        # Horizontal puis vertical
        create_horizontal_corridor $room1_x $room1_y $room2_x $room1_y
        create_vertical_corridor $room2_x $room1_y $room2_x $room2_y
    else
        # Vertical puis horizontal
        create_vertical_corridor $room1_x $room1_y $room1_x $room2_y
        create_horizontal_corridor $room1_x $room2_y $room2_x $room2_y
    fi
}

# Créer un couloir horizontal
function create_horizontal_corridor() {
    local x1=$1
    local y1=$2
    local x2=$3
    local y2=$4
    
    # S'assurer que x1 <= x2
    if (( x1 > x2 )); then
        local temp=$x1
        x1=$x2
        x2=$temp
    fi
    
    # Créer le couloir
    for ((x=x1; x<=x2; x++)); do
        # Vérifier si c'est un mur
        if [[ "${DUNGEON_MAP["$x,$y1"]}" == "$TILE_WALL" ]]; then
            # Convertir en porte
            DUNGEON_MAP["$x,$y1"]=$TILE_DOOR
        elif [[ "${DUNGEON_MAP["$x,$y1"]}" == "$TILE_EMPTY" ]]; then
            # Convertir en sol
            DUNGEON_MAP["$x,$y1"]=$TILE_FLOOR
            
            # Ajouter des murs autour
            if [[ "${DUNGEON_MAP["$x,$((y1-1))"]}" == "$TILE_EMPTY" ]]; then
                DUNGEON_MAP["$x,$((y1-1))"]=$TILE_WALL
            fi
            
            if [[ "${DUNGEON_MAP["$x,$((y1+1))"]}" == "$TILE_EMPTY" ]]; then
                DUNGEON_MAP["$x,$((y1+1))"]=$TILE_WALL
            fi
        fi
    done
}

# Créer un couloir vertical
function create_vertical_corridor() {
    local x1=$1
    local y1=$2
    local x2=$3
    local y2=$4
    
    # S'assurer que y1 <= y2
    if (( y1 > y2 )); then
        local temp=$y1
        y1=$y2
        y2=$temp
    fi
    
    # Créer le couloir
    for ((y=y1; y<=y2; y++)); do
        # Vérifier si c'est un mur
        if [[ "${DUNGEON_MAP["$x1,$y"]}" == "$TILE_WALL" ]]; then
            # Convertir en porte
            DUNGEON_MAP["$x1,$y"]=$TILE_DOOR
        elif [[ "${DUNGEON_MAP["$x1,$y"]}" == "$TILE_EMPTY" ]]; then
            # Convertir en sol
            DUNGEON_MAP["$x1,$y"]=$TILE_FLOOR
            
            # Ajouter des murs autour
            if [[ "${DUNGEON_MAP["$((x1-1)),$y"]}" == "$TILE_EMPTY" ]]; then
                DUNGEON_MAP["$((x1-1)),$y"]=$TILE_WALL
            fi
            
            if [[ "${DUNGEON_MAP["$((x1+1)),$y"]}" == "$TILE_EMPTY" ]]; then
                DUNGEON_MAP["$((x1+1)),$y"]=$TILE_WALL
            fi
        fi
    done
}

# Placer l'entrée et la sortie du donjon
function place_entrance_exit() {
    local num_rooms=${#DUNGEON_ROOMS[@]}
    
    if (( num_rooms <= 0 )); then
        return
    fi
    
    # Choisir une pièce pour l'entrée (première pièce)
    local entrance_room_id=0
    local entrance_room_x=${DUNGEON_ROOMS["$entrance_room_id,x"]}
    local entrance_room_y=${DUNGEON_ROOMS["$entrance_room_id,y"]}
    local entrance_room_width=${DUNGEON_ROOMS["$entrance_room_id,width"]}
    local entrance_room_height=${DUNGEON_ROOMS["$entrance_room_id,height"]}
    
    # Placer l'entrée au centre de la pièce
    local entrance_x=$((entrance_room_x + entrance_room_width / 2))
    local entrance_y=$((entrance_room_y + entrance_room_height / 2))
    
    DUNGEON_MAP["$entrance_x,$entrance_y"]=$TILE_STAIRS_UP
    DUNGEON_START_X=$entrance_x
    DUNGEON_START_Y=0
    DUNGEON_START_Z=$entrance_y
    
    # Choisir une pièce pour la sortie (dernière pièce)
    local exit_room_id=$((num_rooms - 1))
    local exit_room_x=${DUNGEON_ROOMS["$exit_room_id,x"]}
    local exit_room_y=${DUNGEON_ROOMS["$exit_room_id,y"]}
    local exit_room_width=${DUNGEON_ROOMS["$exit_room_id,width"]}
    local exit_room_height=${DUNGEON_ROOMS["$exit_room_id,height"]}
    
    # Placer la sortie au centre de la pièce
    local exit_x=$((exit_room_x + exit_room_width / 2))
    local exit_y=$((exit_room_y + exit_room_height / 2))
    
    DUNGEON_MAP["$exit_x,$exit_y"]=$TILE_STAIRS_DOWN
    DUNGEON_EXIT_X=$exit_x
    DUNGEON_EXIT_Y=0
    DUNGEON_EXIT_Z=$exit_y
}

# Ajouter des fonctionnalités au donjon (coffres, pièges, etc.)
function add_features() {
    local num_rooms=${#DUNGEON_ROOMS[@]}
    
    # Ajouter des coffres (un dans chaque pièce sauf l'entrée et la sortie)
    for ((i=1; i<num_rooms-1; i++)); do
        # 50% de chance d'avoir un coffre
        if (( RANDOM % 2 == 0 )); then
            local room_x=${DUNGEON_ROOMS["$i,x"]}
            local room_y=${DUNGEON_ROOMS["$i,y"]}
            local room_width=${DUNGEON_ROOMS["$i,width"]}
            local room_height=${DUNGEON_ROOMS["$i,height"]}
            
            # Trouver un emplacement pour le coffre (coin de la pièce)
            local chest_x=$((room_x + 1))
            local chest_y=$((room_y + 1))
            
            # Vérifier si l'emplacement est libre
            if [[ "${DUNGEON_MAP["$chest_x,$chest_y"]}" == "$TILE_FLOOR" ]]; then
                DUNGEON_MAP["$chest_x,$chest_y"]=$TILE_CHEST
            fi
        fi
    done
    
    # Ajouter des pièges (dans les couloirs)
    local trap_count=$((num_rooms / 2))
    
    for ((i=0; i<trap_count; i++)); do
        # Chercher un emplacement aléatoire qui est un sol
        local attempts=0
        local max_attempts=100
        
        while (( attempts < max_attempts )); do
            local trap_x=$((RANDOM % DUNGEON_WIDTH))
            local trap_y=$((RANDOM % DUNGEON_HEIGHT))
            
            if [[ "${DUNGEON_MAP["$trap_x,$trap_y"]}" == "$TILE_FLOOR" ]]; then
                # Vérifier si ce n'est pas dans une pièce
                local in_room=false
                
                for ((j=0; j<num_rooms; j++)); do
                    local room_x=${DUNGEON_ROOMS["$j,x"]}
                    local room_y=${DUNGEON_ROOMS["$j,y"]}
                    local room_width=${DUNGEON_ROOMS["$j,width"]}
                    local room_height=${DUNGEON_ROOMS["$j,height"]}
                    
                    if (( trap_x > room_x && trap_x < room_x+room_width-1 && 
                          trap_y > room_y && trap_y < room_y+room_height-1 )); then
                        in_room=true
                        break
                    fi
                done
                
                if ! $in_room; then
                    DUNGEON_MAP["$trap_x,$trap_y"]=$TILE_TRAP
                    break
                fi
            fi
            
            ((attempts++))
        done
    done
}

# Construire le donjon dans le monde 3D
function build_dungeon_in_world() {
    local origin_x=$1
    local origin_y=$2
    local origin_z=$3
    
    echo "Construction du donjon dans le monde aux coordonnées ($origin_x, $origin_y, $origin_z)..."
    
    # Parcourir la carte du donjon
    for ((y=0; y<DUNGEON_HEIGHT; y++)); do
        for ((x=0; x<DUNGEON_WIDTH; x++)); do
            local tile=${DUNGEON_MAP["$x,$y"]}
            
            # Calculer les coordonnées 3D
            local world_x=$(bc -l <<< "$origin_x + $x * $DUNGEON_GRID_SIZE")
            local world_z=$(bc -l <<< "$origin_z + $y * $DUNGEON_GRID_SIZE")
            
            # Créer l'objet en fonction du type de tuile
            case "$tile" in
                $TILE_WALL)
                    # Mur
                    add_object "cube" $world_x $origin_y $world_z $DUNGEON_WALL_HEIGHT
                    ;;
                $TILE_FLOOR)
                    # Sol
                    # Rien à faire, le sol est implicite
                    ;;
                $TILE_DOOR)
                    # Porte
                    # Pour simplifier, on utilise juste un cube plus petit
                    add_object "cube" $world_x $origin_y $world_z 0.5
                    ;;
                $TILE_STAIRS_UP)
                    # Escalier montant
                    add_object "cube" $world_x $origin_y $world_z 0.3
                    ;;
                $TILE_STAIRS_DOWN)
                    # Escalier descendant
                    add_object "cube" $world_x $origin_y $world_z 0.3
                    ;;
                $TILE_CHEST)
                    # Coffre
                    add_object "cube" $world_x $origin_y $world_z 0.5
                    ;;
                $TILE_TRAP)
                    # Piège (invisible)
                    # On ne rend pas le piège visible, mais on stocke sa position
                    local trap_id="trap_${x}_${y}"
                    TRAPS["$trap_id,x"]=$world_x
                    TRAPS["$trap_id,y"]=$origin_y
                    TRAPS["$trap_id,z"]=$world_z
                    TRAPS["$trap_id,active"]=true
                    ;;
            esac
        done
    done
    
    # Mettre à jour les coordonnées de départ et de sortie
    DUNGEON_START_X=$(bc -l <<< "$origin_x + $DUNGEON_START_X * $DUNGEON_GRID_SIZE")
    DUNGEON_START_Y=$origin_y
    DUNGEON_START_Z=$(bc -l <<< "$origin_z + $DUNGEON_START_Z * $DUNGEON_GRID_SIZE")
    
    DUNGEON_EXIT_X=$(bc -l <<< "$origin_x + $DUNGEON_EXIT_X * $DUNGEON_GRID_SIZE")
    DUNGEON_EXIT_Y=$origin_y
    DUNGEON_EXIT_Z=$(bc -l <<< "$origin_z + $DUNGEON_EXIT_Z * $DUNGEON_GRID_SIZE")
    
    echo "Donjon construit dans le monde."
}

# Téléporter le joueur à l'entrée du donjon
function teleport_to_dungeon_entrance() {
    # Vérifier si un donjon a été généré
    if [[ -z "$DUNGEON_START_X" || -z "$DUNGEON_START_Y" || -z "$DUNGEON_START_Z" ]]; then
        echo "Erreur: Aucun donjon généré."
        return 1
    fi
    
    # Téléporter le joueur
    CAMERA_X=$DUNGEON_START_X
    CAMERA_Y=$DUNGEON_START_Y
    CAMERA_Z=$DUNGEON_START_Z
    
    echo "Téléporté à l'entrée du donjon: ($DUNGEON_START_X, $DUNGEON_START_Y, $DUNGEON_START_Z)"
    
    return 0
}

# Téléporter le joueur à la sortie du donjon
function teleport_to_dungeon_exit() {
    # Vérifier si un donjon a été généré
    if [[ -z "$DUNGEON_EXIT_X" || -z "$DUNGEON_EXIT_Y" || -z "$DUNGEON_EXIT_Z" ]]; then
        echo "Erreur: Aucun donjon généré."
        return 1
    fi
    
    # Téléporter le joueur
    CAMERA_X=$DUNGEON_EXIT_X
    CAMERA_Y=$DUNGEON_EXIT_Y
    CAMERA_Z=$DUNGEON_EXIT_Z
    
    echo "Téléporté à la sortie du donjon: ($DUNGEON_EXIT_X, $DUNGEON_EXIT_Y, $DUNGEON_EXIT_Z)"
    
    return 0
}

# Vérifier si le joueur est sur un piège
function check_for_traps() {
    local player_x=$1
    local player_y=$2
    local player_z=$3
    local trap_radius=0.5
    
    # Parcourir tous les pièges
    for key in "${!TRAPS[@]}"; do
        if [[ "$key" == *",active" && "${TRAPS[$key]}" == "true" ]]; then
            local trap_id="${key%,active}"
            
            # Obtenir la position du piège
            local trap_x=${TRAPS["$trap_id,x"]}
            local trap_y=${TRAPS["$trap_id,y"]}
            local trap_z=${TRAPS["$trap_id,z"]}
            
            # Calculer la distance
            local dx=$(bc -l <<< "$trap_x - $player_x")
            local dy=$(bc -l <<< "$trap_y - $player_y")
            local dz=$(bc -l <<< "$trap_z - $player_z")
            local distance=$(bc -l <<< "sqrt($dx^2 + $dy^2 + $dz^2)")
            
            # Vérifier si le joueur est sur le piège
            if (( $(bc -l <<< "$distance <= $trap_radius") )); then
                # Activer le piège
                trigger_trap "$trap_id"
                
                # Désactiver le piège
                TRAPS["$trap_id,active"]=false
                
                return 0
            fi
        fi
    done
    
    return 1
}

# Déclencher un piège
function trigger_trap() {
    local trap_id=$1
    
    echo "Vous avez déclenché un piège!"
    
    # Effet aléatoire du piège
    local trap_effect=$((RANDOM % 3))
    
    case "$trap_effect" in
        0)
            # Dégâts
            local damage=$((RANDOM % 10 + 5))
            PLAYER_HEALTH=$((PLAYER_HEALTH - damage))
            
            echo "Le piège vous inflige $damage points de dégâts!"
            
            # Vérifier si le joueur est mort
            if (( PLAYER_HEALTH <= 0 )); then
                player_defeated
            fi
            ;;
        1)
            # Poison
            local poison_duration=$((RANDOM % 5 + 3))
            PLAYER_POISONED=true
            PLAYER_POISON_DURATION=$poison_duration
            
            echo "Vous êtes empoisonné pour $poison_duration tours!"
            ;;
        2)
            # Téléportation aléatoire
            local random_room_id=$((RANDOM % ${#DUNGEON_ROOMS[@]}))
            local room_x=${DUNGEON_ROOMS["$random_room_id,x"]}
            local room_y=${DUNGEON_ROOMS["$random_room_id,y"]}
            local room_width=${DUNGEON_ROOMS["$random_room_id,width"]}
            local room_height=${DUNGEON_ROOMS["$random_room_id,height"]}
            
            # Calculer les coordonnées du centre de la pièce
            local center_x=$((room_x + room_width / 2))
            local center_y=$((room_y + room_height / 2))
            
            # Téléporter le joueur
            CAMERA_X=$center_x
            CAMERA_Y=$DUNGEON_START_Y
            CAMERA_Z=$center_y
            
            echo "Vous êtes téléporté dans une autre pièce du donjon!"
            ;;
    esac
    
    # Jouer un son
    sound_player_hit
    
    return 0
}

# Vérifier si le joueur est sur un coffre
function check_for_chests() {
    local player_x=$1
    local player_y=$2
    local player_z=$3
    local chest_radius=0.7
    
    # Parcourir la carte à la recherche de coffres proches
    for ((y=0; y<DUNGEON_HEIGHT; y++)); do
        for ((x=0; x<DUNGEON_WIDTH; x++)); do
            if [[ "${DUNGEON_MAP["$x,$y"]}" == "$TILE_CHEST" ]]; then
                # Calculer les coordonnées 3D du coffre
                local chest_x=$(bc -l <<< "$DUNGEON_START_X + ($x - $DUNGEON_START_X) * $DUNGEON_GRID_SIZE")
                local chest_z=$(bc -l <<< "$DUNGEON_START_Z + ($y - $DUNGEON_START_Z) * $DUNGEON_GRID_SIZE")
                
                # Calculer la distance
                local dx=$(bc -l <<< "$chest_x - $player_x")
                local dy=$(bc -l <<< "$DUNGEON_START_Y - $player_y")
                local dz=$(bc -l <<< "$chest_z - $player_z")
                local distance=$(bc -l <<< "sqrt($dx^2 + $dy^2 + $dz^2)")
                
                # Vérifier si le joueur est près du coffre
                if (( $(bc -l <<< "$distance <= $chest_radius") )); then
                    # Ouvrir le coffre
                    open_chest "$x" "$y"
                    
                    # Marquer le coffre comme ouvert
                    DUNGEON_MAP["$x,$y"]=$TILE_FLOOR
                    
                    return 0
                fi
            fi
        done
    done
    
    return 1
}

# Ouvrir un coffre
function open_chest() {
    local chest_x=$1
    local chest_y=$2
    
    echo "Vous ouvrez un coffre!"
    
    # Contenu aléatoire du coffre
    local chest_content=$((RANDOM % 5))
    
    case "$chest_content" in
        0)
            # Or
            local gold_amount=$((RANDOM % 50 + 10))
            PLAYER_GOLD=$((PLAYER_GOLD + gold_amount))
            
            echo "Vous trouvez $gold_amount pièces d'or!"
            ;;
        1)
            # Potion de vie
            add_to_inventory "health_potion" 1
            
            echo "Vous trouvez une potion de vie!"
            ;;
        2)
            # Potion de mana
            add_to_inventory "mana_potion" 1
            
            echo "Vous trouvez une potion de mana!"
            ;;
        3)
            # Arme ou armure
            local item_type=$((RANDOM % 2))
            
            if (( item_type == 0 )); then
                # Arme
                add_to_inventory "iron_sword" 1
                
                echo "Vous trouvez une épée en fer!"
            else
                # Armure
                add_to_inventory "leather_armor" 1
                
                echo "Vous trouvez une armure en cuir!"
            fi
            ;;
        4)
            # Parchemin magique
            add_to_inventory "magic_scroll" 1
            
            echo "Vous trouvez un parchemin magique!"
            ;;
    esac
    
    # Jouer un son
    sound_pickup
    
    return 0
}

# Vérifier si le joueur est sur un escalier
function check_for_stairs() {
    local player_x=$1
    local player_y=$2
    local player_z=$3
    local stairs_radius=0.7
    
    # Vérifier l'escalier montant
    local dx_up=$(bc -l <<< "$DUNGEON_START_X - $player_x")
    local dy_up=$(bc -l <<< "$DUNGEON_START_Y - $player_y")
    local dz_up=$(bc -l <<< "$DUNGEON_START_Z - $player_z")
    local distance_up=$(bc -l <<< "sqrt($dx_up^2 + $dy_up^2 + $dz_up^2)")
    
    if (( $(bc -l <<< "$distance_up <= $stairs_radius") )); then
        # Monter l'escalier (sortir du donjon)
        exit_dungeon_up
        
        return 0
    fi
    
    # Vérifier l'escalier descendant
    local dx_down=$(bc -l <<< "$DUNGEON_EXIT_X - $player_x")
    local dy_down=$(bc -l <<< "$DUNGEON_EXIT_Y - $player_y")
    local dz_down=$(bc -l <<< "$DUNGEON_EXIT_Z - $player_z")
    local distance_down=$(bc -l <<< "sqrt($dx_down^2 + $dy_down^2 + $dz_down^2)")
    
    if (( $(bc -l <<< "$distance_down <= $stairs_radius") )); then
        # Descendre l'escalier (aller au niveau suivant)
        exit_dungeon_down
        
        return 0
    fi
    
    return 1
}

# Sortir du donjon par l'escalier montant
function exit_dungeon_up() {
    echo "Vous montez l'escalier et sortez du donjon."
    
    # Téléporter le joueur à la position d'origine
    CAMERA_X=0
    CAMERA_Y=0
    CAMERA_Z=0
    
    # Réinitialiser le donjon
    DUNGEON_MAP=()
    DUNGEON_ROOMS=()
    
    # Jouer un son
    sound_door_open
    
    return 0
}

# Sortir du donjon par l'escalier descendant
function exit_dungeon_down() {
    echo "Vous descendez l'escalier et entrez dans un nouveau niveau du donjon."
    
    # Générer un nouveau donjon
    generate_dungeon $DUNGEON_WIDTH $DUNGEON_HEIGHT
    
    # Construire le donjon
    build_dungeon_in_world 0 0 0
    
    # Téléporter le joueur à l'entrée du nouveau donjon
    teleport_to_dungeon_entrance
    
    # Jouer un son
    sound_door_open
    
    return 0
}

# Afficher la carte du donjon
function display_dungeon_map() {
    local screen_x=10
    local screen_y=5
    local map_width=DUNGEON_WIDTH
    local map_height=DUNGEON_HEIGHT
    
    # Effacer l'écran
    clear
    
    # Afficher le titre
    echo "Carte du donjon"
    echo "==============="
    echo ""
    
    # Afficher la légende
    echo "Légende :"
    echo "□ : Mur"
    echo "· : Sol"
    echo "+ : Porte"
    echo "↑ : Escalier montant"
    echo "↓ : Escalier descendant"
    echo "C : Coffre"
    echo "P : Joueur"
    echo ""
    
    # Dessiner la carte
    for ((y=0; y<map_height; y++)); do
        local line=""
        
        for ((x=0; x<map_width; x++)); do
            local tile=${DUNGEON_MAP["$x,$y"]}
            local char=""
            
            # Vérifier si le joueur est à cette position
            local player_map_x=$(bc <<< "scale=0; ($CAMERA_X - $DUNGEON_START_X) / $DUNGEON_GRID_SIZE + 0.5 / 1")
            local player_map_y=$(bc <<< "scale=0; ($CAMERA_Z - $DUNGEON_START_Z) / $DUNGEON_GRID_SIZE + 0.5 / 1")
            
            if (( x == player_map_x && y == player_map_y )); then
                char="P"
            else
                # Déterminer le caractère en fonction du type de tuile
                case "$tile" in
                    $TILE_EMPTY) char=" " ;;
                    $TILE_WALL) char="□" ;;
                    $TILE_FLOOR) char="·" ;;
                    $TILE_DOOR) char="+" ;;
                    $TILE_STAIRS_UP) char="↑" ;;
                    $TILE_STAIRS_DOWN) char="↓" ;;
                    $TILE_CHEST) char="C" ;;
                    $TILE_TRAP) char="·" ;;  # Les pièges sont cachés
                    *) char="?" ;;
                esac
            fi
            
            line+="$char"
        done
        
        echo "$line"
    done
    
    # Attendre que le joueur appuie sur une touche
    echo ""
    echo "Appuyez sur une touche pour continuer..."
    read -n 1
    
    # Effacer l'écran
    clear
    
    return 0
}

# Afficher la minimap du donjon
function display_minimap() {
    local map_size=7
    local center_x=$(bc <<< "scale=0; ($CAMERA_X - $DUNGEON_START_X) / $DUNGEON_GRID_SIZE + 0.5 / 1")
    local center_y=$(bc <<< "scale=0; ($CAMERA_Z - $DUNGEON_START_Z) / $DUNGEON_GRID_SIZE + 0.5 / 1")
    
    local start_x=$((center_x - map_size / 2))
    local start_y=$((center_y - map_size / 2))
    local end_x=$((center_x + map_size / 2))
    local end_y=$((center_y + map_size / 2))
    
    # Limiter aux dimensions du donjon
    if (( start_x < 0 )); then
        start_x=0
    fi
    
    if (( start_y < 0 )); then
        start_y=0
    fi
    
    if (( end_x >= DUNGEON_WIDTH )); then
        end_x=$((DUNGEON_WIDTH - 1))
    fi
    
    if (( end_y >= DUNGEON_HEIGHT )); then
        end_y=$((DUNGEON_HEIGHT - 1))
    fi
    
    # Dessiner la minimap
    local screen_x=$((SCREEN_WIDTH - map_size - 2))
    local screen_y=2
    
    # Dessiner le cadre
    tput cup $screen_y $screen_x
    echo -n "┌$(printf "%*s" $map_size | tr ' ' '─')┐"
    
    for ((y=start_y; y<=end_y; y++)); do
        tput cup $((screen_y + y - start_y + 1)) $screen_x
        echo -n "│"
        
        for ((x=start_x; x<=end_x; x++)); do
            local tile=${DUNGEON_MAP["$x,$y"]}
            local char=""
            
            # Vérifier si le joueur est à cette position
            if (( x == center_x && y == center_y )); then
                echo -n "P"
            else
                # Déterminer le caractère en fonction du type de tuile
                case "$tile" in
                    $TILE_EMPTY) echo -n " " ;;
                    $TILE_WALL) echo -n "█" ;;
                    $TILE_FLOOR) echo -n "·" ;;
                    $TILE_DOOR) echo -n "+" ;;
                    $TILE_STAIRS_UP) echo -n "↑" ;;
                    $TILE_STAIRS_DOWN) echo -n "↓" ;;
                    $TILE_CHEST) echo -n "C" ;;
                    $TILE_TRAP) echo -n "·" ;;  # Les pièges sont cachés
                    *) echo -n "?" ;;
                esac
            fi
        done
        
        # Remplir le reste de la ligne
        for ((x=end_x+1; x<start_x+map_size; x++)); do
            echo -n " "
        done
        
        echo -n "│"
    done
    
    tput cup $((screen_y + end_y - start_y + 2)) $screen_x
    echo -n "└$(printf "%*s" $map_size | tr ' ' '─')┘"
    
    return 0
}

# Initialiser le générateur de donjons
init_dungeon_generator
