#!/bin/bash
#
# Système de physique simplifiée pour le jeu
#

# Constantes physiques
GRAVITY=0.05          # Force de gravité
FRICTION=0.98         # Coefficient de friction
BOUNCE_FACTOR=0.7     # Facteur de rebond
COLLISION_THRESHOLD=0.8  # Seuil de détection de collision

# Initialiser le système de physique
function init_physics() {
    echo "Initialisation du système de physique..."
}

# Appliquer la gravité à une entité
function apply_gravity() {
    local entity_id=$1
    
    # Vérifier si l'entité existe
    if [[ -n "${ENTITIES["$entity_id,model"]}" ]]; then
        local vel_y="${ENTITIES["$entity_id,vel_y"]}"
        
        # Appliquer la gravité
        local new_vel_y=$(bc -l <<< "$vel_y - $GRAVITY")
        
        # Mettre à jour la vélocité
        update_entity_velocity "$entity_id" "${ENTITIES["$entity_id,vel_x"]}" "$new_vel_y" "${ENTITIES["$entity_id,vel_z"]}"
    fi
}

# Appliquer la friction à une entité
function apply_friction() {
    local entity_id=$1
    
    # Vérifier si l'entité existe
    if [[ -n "${ENTITIES["$entity_id,model"]}" ]]; then
        local vel_x="${ENTITIES["$entity_id,vel_x"]}"
        local vel_y="${ENTITIES["$entity_id,vel_y"]}"
        local vel_z="${ENTITIES["$entity_id,vel_z"]}"
        
        # Appliquer la friction
        local new_vel_x=$(bc -l <<< "$vel_x * $FRICTION")
        local new_vel_y=$(bc -l <<< "$vel_y * $FRICTION")
        local new_vel_z=$(bc -l <<< "$vel_z * $FRICTION")
        
        # Mettre à jour la vélocité
        update_entity_velocity "$entity_id" "$new_vel_x" "$new_vel_y" "$new_vel_z"
    fi
}

# Détecter une collision entre deux entités (détection basique par sphère)
function check_collision() {
    local entity_id1=$1
    local entity_id2=$2
    
    # Calculer la distance entre les entités
    local distance=$(get_distance_between_entities "$entity_id1" "$entity_id2")
    
    # Vérifier si la distance est inférieure au seuil de collision
    if (( $(bc -l <<< "$distance < $COLLISION_THRESHOLD") )); then
        echo "true"
    else
        echo "false"
    fi
}

# Résoudre une collision entre deux entités
function resolve_collision() {
    local entity_id1=$1
    local entity_id2=$2
    
    # Obtenir les positions
    local pos1=$(get_entity_position "$entity_id1")
    local pos2=$(get_entity_position "$entity_id2")
    
    # Extraire les coordonnées
    local x1=$(echo $pos1 | cut -d' ' -f1)
    local y1=$(echo $pos1 | cut -d' ' -f2)
    local z1=$(echo $pos1 | cut -d' ' -f3)
    
    local x2=$(echo $pos2 | cut -d' ' -f1)
    local y2=$(echo $pos2 | cut -d' ' -f2)
    local z2=$(echo $pos2 | cut -d' ' -f3)
    
    # Calculer le vecteur de collision
    local dx=$(bc -l <<< "$x2 - $x1")
    local dy=$(bc -l <<< "$y2 - $y1")
    local dz=$(bc -l <<< "$z2 - $z1")
    
    # Normaliser le vecteur
    local normal=$(normalize_vector $dx $dy $dz)
    local nx=$(echo $normal | cut -d' ' -f1)
    local ny=$(echo $normal | cut -d' ' -f2)
    local nz=$(echo $normal | cut -d' ' -f3)
    
    # Obtenir les vélocités
    local vel_x1="${ENTITIES["$entity_id1,vel_x"]}"
    local vel_y1="${ENTITIES["$entity_id1,vel_y"]}"
    local vel_z1="${ENTITIES["$entity_id1,vel_z"]}"
    
    local vel_x2="${ENTITIES["$entity_id2,vel_x"]}"
    local vel_y2="${ENTITIES["$entity_id2,vel_y"]}"
    local vel_z2="${ENTITIES["$entity_id2,vel_z"]}"
    
    # Calculer le produit scalaire
    local dot1=$(dot_product $vel_x1 $vel_y1 $vel_z1 $nx $ny $nz)
    local dot2=$(dot_product $vel_x2 $vel_y2 $vel_z2 $nx $ny $nz)
    
    # Calculer l'impulsion
    local impulse=$(bc -l <<< "($dot1 - $dot2) * $BOUNCE_FACTOR")
    
    # Appliquer l'impulsion à l'entité 1
    local new_vel_x1=$(bc -l <<< "$vel_x1 - $impulse * $nx")
    local new_vel_y1=$(bc -l <<< "$vel_y1 - $impulse * $ny")
    local new_vel_z1=$(bc -l <<< "$vel_z1 - $impulse * $nz")
    
    # Appliquer l'impulsion à l'entité 2
    local new_vel_x2=$(bc -l <<< "$vel_x2 + $impulse * $nx")
    local new_vel_y2=$(bc -l <<< "$vel_y2 + $impulse * $ny")
    local new_vel_z2=$(bc -l <<< "$vel_z2 + $impulse * $nz")
    
    # Mettre à jour les vélocités
    update_entity_velocity "$entity_id1" "$new_vel_x1" "$new_vel_y1" "$new_vel_z1"
    update_entity_velocity "$entity_id2" "$new_vel_x2" "$new_vel_y2" "$new_vel_z2"
}

# Vérifier la collision avec le sol
function check_ground_collision() {
    local entity_id=$1
    
    # Obtenir la position
    local pos=$(get_entity_position "$entity_id")
    
    # Extraire les coordonnées
    local x=$(echo $pos | cut -d' ' -f1)
    local y=$(echo $pos | cut -d' ' -f2)
    local z=$(echo $pos | cut -d' ' -f3)
    
    # Obtenir la hauteur du terrain
    local ground_height=$(get_terrain_height $x $z)
    
    # Vérifier si l'entité est sous le sol
    if (( $(bc -l <<< "$y < $ground_height") )); then
        echo "true"
    else
        echo "false"
    fi
}

# Résoudre la collision avec le sol
function resolve_ground_collision() {
    local entity_id=$1
    
    # Obtenir la position
    local pos=$(get_entity_position "$entity_id")
    
    # Extraire les coordonnées
    local x=$(echo $pos | cut -d' ' -f1)
    local y=$(echo $pos | cut -d' ' -f2)
    local z=$(echo $pos | cut -d' ' -f3)
    
    # Obtenir la hauteur du terrain
    local ground_height=$(get_terrain_height $x $z)
    
    # Obtenir la vélocité
    local vel_y="${ENTITIES["$entity_id,vel_y"]}"
    
    # Repositionner l'entité au niveau du sol
    update_entity_position "$entity_id" $x $ground_height $z
    
    # Inverser la vélocité verticale avec le facteur de rebond
    local new_vel_y=$(bc -l <<< "-$vel_y * $BOUNCE_FACTOR")
    
    # Si la vitesse est très faible, arrêter le rebond
    if (( $(bc -l <<< "a($new_vel_y) < 0.01") )); then
        new_vel_y=0
    fi
    
    # Mettre à jour la vélocité
    update_entity_velocity "$entity_id" "${ENTITIES["$entity_id,vel_x"]}" "$new_vel_y" "${ENTITIES["$entity_id,vel_z"]}"
}

# Mettre à jour la physique pour toutes les entités
function update_physics() {
    # Parcourir toutes les entités
    for key in "${!ENTITIES[@]}"; do
        # Vérifier si c'est une clé de modèle (pour éviter de traiter chaque propriété)
        if [[ "$key" == *",model" ]]; then
            # Extraire l'ID de l'entité
            local entity_id="${key%,model}"
            
            # Vérifier si l'entité est active
            if [[ "${ENTITIES["$entity_id,active"]}" == "1" ]]; then
                # Appliquer la gravité
                apply_gravity "$entity_id"
                
                # Appliquer la friction
                apply_friction "$entity_id"
                
                # Vérifier la collision avec le sol
                if [[ $(check_ground_collision "$entity_id") == "true" ]]; then
                    resolve_ground_collision "$entity_id"
                fi
                
                # Vérifier les collisions avec les autres entités
                # (Ceci est coûteux en performance, donc on pourrait optimiser)
                for other_key in "${!ENTITIES[@]}"; do
                    if [[ "$other_key" == *",model" && "$other_key" != "$key" ]]; then
                        local other_id="${other_key%,model}"
                        
                        if [[ "${ENTITIES["$other_id,active"]}" == "1" ]]; then
                            if [[ $(check_collision "$entity_id" "$other_id") == "true" ]]; then
                                resolve_collision "$entity_id" "$other_id"
                            fi
                        fi
                    fi
                done
            fi
        fi
    done
}

# Appliquer une force à une entité
function apply_force() {
    local entity_id=$1
    local force_x=$2
    local force_y=$3
    local force_z=$4
    
    # Vérifier si l'entité existe
    if [[ -n "${ENTITIES["$entity_id,model"]}" ]]; then
        local vel_x="${ENTITIES["$entity_id,vel_x"]}"
        local vel_y="${ENTITIES["$entity_id,vel_y"]}"
        local vel_z="${ENTITIES["$entity_id,vel_z"]}"
        
        # Appliquer la force
        local new_vel_x=$(bc -l <<< "$vel_x + $force_x")
        local new_vel_y=$(bc -l <<< "$vel_y + $force_y")
        local new_vel_z=$(bc -l <<< "$vel_z + $force_z")
        
        # Mettre à jour la vélocité
        update_entity_velocity "$entity_id" "$new_vel_x" "$new_vel_y" "$new_vel_z"
    fi
}

# Définir la position et la vélocité d'une entité
function set_entity_state() {
    local entity_id=$1
    local x=$2
    local y=$3
    local z=$4
    local vel_x=$5
    local vel_y=$6
    local vel_z=$7
    
    # Mettre à jour la position
    update_entity_position "$entity_id" $x $y $z
    
    # Mettre à jour la vélocité
    update_entity_velocity "$entity_id" $vel_x $vel_y $vel_z
}
