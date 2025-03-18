#!/bin/bash
#
# Système de gestion des entités du jeu
#

# Liste des entités du jeu (objets avec comportement)
declare -A ENTITIES

# Types d'entités
ENTITY_TYPE_STATIC=0    # Objets statiques
ENTITY_TYPE_MOVING=1    # Objets en mouvement
ENTITY_TYPE_PLAYER=2    # Joueur
ENTITY_TYPE_ENEMY=3     # Ennemi
ENTITY_TYPE_PICKUP=4    # Objet à ramasser

# Initialiser le système d'entités
function init_entities() {
    echo "Initialisation du système d'entités..."
    
    # Ajouter l'entité du joueur
    add_entity "player" $ENTITY_TYPE_PLAYER 0 0 0 0 0 0
    
    # Ajouter quelques entités pour tester
    add_entity "cube" $ENTITY_TYPE_STATIC 5 0 5 0 0 0
    add_entity "cube" $ENTITY_TYPE_MOVING -5 0 5 0.1 0 0.05
    add_entity "sphere" $ENTITY_TYPE_ENEMY 0 0 10 0 0 0
    add_entity "cube" $ENTITY_TYPE_PICKUP 3 1 3 0 0.1 0
    
    echo "Système d'entités initialisé avec ${#ENTITIES[@]} entités."
}

# Ajouter une entité au jeu
function add_entity() {
    local model=$1        # Modèle 3D à utiliser
    local type=$2         # Type d'entité
    local x=$3            # Position X
    local y=$4            # Position Y
    local z=$5            # Position Z
    local vel_x=${6:-0}   # Vélocité X
    local vel_y=${7:-0}   # Vélocité Y
    local vel_z=${8:-0}   # Vélocité Z
    
    # Générer un ID unique
    local entity_id="entity_$(date +%s%N)"
    
    # Stocker les données de l'entité
    ENTITIES["$entity_id,model"]="$model"
    ENTITIES["$entity_id,type"]="$type"
    ENTITIES["$entity_id,x"]="$x"
    ENTITIES["$entity_id,y"]="$y"
    ENTITIES["$entity_id,z"]="$z"
    ENTITIES["$entity_id,vel_x"]="$vel_x"
    ENTITIES["$entity_id,vel_y"]="$vel_y"
    ENTITIES["$entity_id,vel_z"]="$vel_z"
    ENTITIES["$entity_id,active"]="1"  # 1 = actif, 0 = inactif
    
    echo "Entité ajoutée: ID=$entity_id, Type=$type, Position=($x, $y, $z)"
    
    # Retourner l'ID de l'entité
    echo "$entity_id"
}

# Supprimer une entité
function remove_entity() {
    local entity_id=$1
    
    # Vérifier si l'entité existe
    if [[ -n "${ENTITIES["$entity_id,model"]}" ]]; then
        # Supprimer toutes les propriétés de l'entité
        unset ENTITIES["$entity_id,model"]
        unset ENTITIES["$entity_id,type"]
        unset ENTITIES["$entity_id,x"]
        unset ENTITIES["$entity_id,y"]
        unset ENTITIES["$entity_id,z"]
        unset ENTITIES["$entity_id,vel_x"]
        unset ENTITIES["$entity_id,vel_y"]
        unset ENTITIES["$entity_id,vel_z"]
        unset ENTITIES["$entity_id,active"]
        
        echo "Entité supprimée: ID=$entity_id"
    else
        echo "Erreur: Entité non trouvée: $entity_id"
    fi
}

# Désactiver une entité (sans la supprimer)
function deactivate_entity() {
    local entity_id=$1
    
    # Vérifier si l'entité existe
    if [[ -n "${ENTITIES["$entity_id,model"]}" ]]; then
        ENTITIES["$entity_id,active"]="0"
        echo "Entité désactivée: ID=$entity_id"
    else
        echo "Erreur: Entité non trouvée: $entity_id"
    fi
}

# Activer une entité
function activate_entity() {
    local entity_id=$1
    
    # Vérifier si l'entité existe
    if [[ -n "${ENTITIES["$entity_id,model"]}" ]]; then
        ENTITIES["$entity_id,active"]="1"
        echo "Entité activée: ID=$entity_id"
    else
        echo "Erreur: Entité non trouvée: $entity_id"
    fi
}

# Mettre à jour la position d'une entité
function update_entity_position() {
    local entity_id=$1
    local new_x=$2
    local new_y=$3
    local new_z=$4
    
    # Vérifier si l'entité existe
    if [[ -n "${ENTITIES["$entity_id,model"]}" ]]; then
        ENTITIES["$entity_id,x"]="$new_x"
        ENTITIES["$entity_id,y"]="$new_y"
        ENTITIES["$entity_id,z"]="$new_z"
    else
        echo "Erreur: Entité non trouvée: $entity_id"
    fi
}

# Mettre à jour la vélocité d'une entité
function update_entity_velocity() {
    local entity_id=$1
    local new_vel_x=$2
    local new_vel_y=$3
    local new_vel_z=$4
    
    # Vérifier si l'entité existe
    if [[ -n "${ENTITIES["$entity_id,model"]}" ]]; then
        ENTITIES["$entity_id,vel_x"]="$new_vel_x"
        ENTITIES["$entity_id,vel_y"]="$new_vel_y"
        ENTITIES["$entity_id,vel_z"]="$new_vel_z"
    else
        echo "Erreur: Entité non trouvée: $entity_id"
    fi
}

# Dessiner toutes les entités actives
function draw_entities() {
    # Parcourir toutes les entités
    for key in "${!ENTITIES[@]}"; do
        # Vérifier si c'est une clé de modèle (pour éviter de traiter chaque propriété)
        if [[ "$key" == *",model" ]]; then
            # Extraire l'ID de l'entité
            local entity_id="${key%,model}"
            
            # Vérifier si l'entité est active
            if [[ "${ENTITIES["$entity_id,active"]}" == "1" ]]; then
                # Récupérer les données de l'entité
                local model="${ENTITIES["$entity_id,model"]}"
                local x="${ENTITIES["$entity_id,x"]}"
                local y="${ENTITIES["$entity_id,y"]}"
                local z="${ENTITIES["$entity_id,z"]}"
                
                # Dessiner le modèle de l'entité
                draw_model "$model" $x $y $z 1.0
            fi
        fi
    done
}

# Mettre à jour toutes les entités
function update_entities() {
    # Parcourir toutes les entités
    for key in "${!ENTITIES[@]}"; do
        # Vérifier si c'est une clé de modèle (pour éviter de traiter chaque propriété)
        if [[ "$key" == *",model" ]]; then
            # Extraire l'ID de l'entité
            local entity_id="${key%,model}"
            
            # Vérifier si l'entité est active
            if [[ "${ENTITIES["$entity_id,active"]}" == "1" ]]; then
                # Récupérer les données de l'entité
                local type="${ENTITIES["$entity_id,type"]}"
                local x="${ENTITIES["$entity_id,x"]}"
                local y="${ENTITIES["$entity_id,y"]}"
                local z="${ENTITIES["$entity_id,z"]}"
                local vel_x="${ENTITIES["$entity_id,vel_x"]}"
                local vel_y="${ENTITIES["$entity_id,vel_y"]}"
                local vel_z="${ENTITIES["$entity_id,vel_z"]}"
                
                # Mettre à jour la position en fonction de la vélocité
                local new_x=$(bc -l <<< "$x + $vel_x")
                local new_y=$(bc -l <<< "$y + $vel_y")
                local new_z=$(bc -l <<< "$z + $vel_z")
                
                # Appliquer la mise à jour
                update_entity_position "$entity_id" $new_x $new_y $new_z
                
                # Comportement spécifique selon le type d'entité
                case $type in
                    $ENTITY_TYPE_MOVING)
                        # Exemple: rebondir aux limites du monde
                        if (( $(bc -l <<< "$new_x > $WORLD_SIZE_X/2") )) || (( $(bc -l <<< "$new_x < -$WORLD_SIZE_X/2") )); then
                            update_entity_velocity "$entity_id" $(bc -l <<< "-$vel_x") $vel_y $vel_z
                        fi
                        if (( $(bc -l <<< "$new_z > $WORLD_SIZE_Z/2") )) || (( $(bc -l <<< "$new_z < -$WORLD_SIZE_Z/2") )); then
                            update_entity_velocity "$entity_id" $vel_x $vel_y $(bc -l <<< "-$vel_z")
                        fi
                        ;;
                    $ENTITY_TYPE_ENEMY)
                        # Exemple: les ennemis se déplacent vers le joueur
                        # Logique à implémenter
                        ;;
                    $ENTITY_TYPE_PICKUP)
                        # Faire tourner ou flotter les objets à ramasser
                        local new_y=$(bc -l <<< "$y + s($(date +%s) * 0.5) * 0.01")
                        update_entity_position "$entity_id" $new_x $new_y $new_z
                        ;;
                esac
            fi
        fi
    done
}

# Obtenir la position d'une entité
function get_entity_position() {
    local entity_id=$1
    
    # Vérifier si l'entité existe
    if [[ -n "${ENTITIES["$entity_id,model"]}" ]]; then
        local x="${ENTITIES["$entity_id,x"]}"
        local y="${ENTITIES["$entity_id,y"]}"
        local z="${ENTITIES["$entity_id,z"]}"
        echo "$x $y $z"
    else
        echo "Erreur: Entité non trouvée: $entity_id"
        echo "0 0 0"  # Valeur par défaut
    fi
}

# Obtenir la distance entre deux entités
function get_distance_between_entities() {
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
    
    # Calculer la distance
    distance3d $x1 $y1 $z1 $x2 $y2 $z2
}
