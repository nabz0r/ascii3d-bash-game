#!/bin/bash
#
# Système de gestion du monde de jeu
#

# Définir la taille du monde
WORLD_SIZE_X=50
WORLD_SIZE_Y=50
WORLD_SIZE_Z=50

# Liste des objets dans le monde
declare -a WORLD_OBJECTS

# Initialiser le monde
function init_world() {
    echo "Initialisation du monde de jeu..."
    
    # Créer quelques objets de test
    add_object "cube" 0 0 0 1.5    # Un cube au centre
    add_object "cube" 3 0 0 1.0    # Un autre cube à droite
    add_object "cube" -3 0 0 1.0   # Un cube à gauche
    add_object "cube" 0 0 3 1.0    # Un cube devant
    add_object "cube" 0 3 0 1.0    # Un cube au-dessus
    
    add_object "sphere" 0 0 -5 2.0  # Une sphère derrière
    
    echo "Monde initialisé avec ${#WORLD_OBJECTS[@]} objets."
}

# Ajouter un objet au monde
function add_object() {
    local type=$1
    local x=$2
    local y=$3
    local z=$4
    local scale=${5:-1.0}
    
    # Créer un nouvel objet et l'ajouter à la liste
    local obj_id=${#WORLD_OBJECTS[@]}
    WORLD_OBJECTS[$obj_id]="$type $x $y $z $scale"
    
    # Debug : afficher l'objet ajouté
    echo "Objet ajouté: ID=$obj_id, Type=$type, Position=($x, $y, $z), Taille=$scale"
}

# Supprimer un objet du monde
function remove_object() {
    local obj_id=$1
    
    # Vérifier si l'ID est valide
    if (( obj_id >= 0 && obj_id < ${#WORLD_OBJECTS[@]} )); then
        unset WORLD_OBJECTS[$obj_id]
        echo "Objet $obj_id supprimé."
    else
        echo "ID d'objet invalide: $obj_id"
    fi
}

# Mettre à jour la position d'un objet
function update_object_position() {
    local obj_id=$1
    local new_x=$2
    local new_y=$3
    local new_z=$4
    
    # Vérifier si l'ID est valide
    if (( obj_id >= 0 && obj_id < ${#WORLD_OBJECTS[@]} )); then
        local obj_data=${WORLD_OBJECTS[$obj_id]}
        local type=$(echo $obj_data | cut -d' ' -f1)
        local scale=$(echo $obj_data | cut -d' ' -f5)
        
        # Mettre à jour les données de l'objet
        WORLD_OBJECTS[$obj_id]="$type $new_x $new_y $new_z $scale"
    else
        echo "ID d'objet invalide: $obj_id"
    fi
}

# Mettre à jour l'état du monde
function update_world() {
    # Cette fonction serait appelée à chaque frame pour mettre à jour
    # l'état du monde, comme l'animation des objets, les interactions, etc.
    
    # Pour l'exemple, faisons tourner légèrement quelques objets autour du centre
    local time=$(date +%s)
    local angle=$(bc -l <<< "($time % 60) * $PI / 30")
    
    # Faire tourner le premier objet autour de l'axe Y
    local radius=5
    local new_x=$(bc -l <<< "$radius * s($angle)")
    local new_z=$(bc -l <<< "$radius * c($angle)")
    
    # Mettre à jour la position (exemple pour l'objet ID 5 - la sphère)
    if (( ${#WORLD_OBJECTS[@]} > 5 )); then
        update_object_position 5 $new_x 0 $new_z
    fi
}

# Dessiner tous les objets du monde
function draw_world_objects() {
    for obj_id in "${!WORLD_OBJECTS[@]}"; do
        local obj_data=${WORLD_OBJECTS[$obj_id]}
        
        # Extraire les données de l'objet
        local type=$(echo $obj_data | cut -d' ' -f1)
        local x=$(echo $obj_data | cut -d' ' -f2)
        local y=$(echo $obj_data | cut -d' ' -f3)
        local z=$(echo $obj_data | cut -d' ' -f4)
        local scale=$(echo $obj_data | cut -d' ' -f5)
        
        # Dessiner l'objet
        draw_model "$type" $x $y $z $scale
    done
}

# Obtenir la hauteur du terrain à une position donnée
function get_terrain_height() {
    local x=$1
    local z=$2
    
    # Pour l'exemple, nous retournons une valeur fixe (0)
    # Dans un vrai jeu, cette fonction pourrait interroger une carte de hauteur
    echo "0"
}

# Vérifier si un point est à l'intérieur des limites du monde
function is_inside_world() {
    local x=$1
    local y=$2
    local z=$3
    
    if (( $(bc -l <<< "$x >= -$WORLD_SIZE_X/2 && $x <= $WORLD_SIZE_X/2") )) && \
       (( $(bc -l <<< "$y >= -$WORLD_SIZE_Y/2 && $y <= $WORLD_SIZE_Y/2") )) && \
       (( $(bc -l <<< "$z >= -$WORLD_SIZE_Z/2 && $z <= $WORLD_SIZE_Z/2") )); then
        echo "true"
    else
        echo "false"
    fi
}

# Charger un niveau depuis un fichier
function load_level() {
    local level_file=$1
    
    echo "Chargement du niveau: $level_file..."
    
    # Réinitialiser le monde
    WORLD_OBJECTS=()
    
    # Vérifier si le fichier existe
    if [[ -f "$level_file" ]]; then
        # Lire le fichier ligne par ligne
        while IFS= read -r line; do
            # Ignorer les lignes vides et les commentaires
            if [[ -z "$line" || "$line" == \#* ]]; then
                continue
            fi
            
            # Extraire les données de l'objet
            local type=$(echo $line | cut -d' ' -f1)
            local x=$(echo $line | cut -d' ' -f2)
            local y=$(echo $line | cut -d' ' -f3)
            local z=$(echo $line | cut -d' ' -f4)
            local scale=$(echo $line | cut -d' ' -f5)
            
            # Ajouter l'objet au monde
            add_object "$type" $x $y $z $scale
        done < "$level_file"
        
        echo "Niveau chargé avec ${#WORLD_OBJECTS[@]} objets."
    else
        echo "Erreur: Fichier de niveau non trouvé: $level_file"
        
        # Créer un niveau par défaut
        init_world
    fi
}

# Sauvegarder le niveau dans un fichier
function save_level() {
    local level_file=$1
    
    echo "Sauvegarde du niveau dans: $level_file..."
    
    # Créer le fichier
    > "$level_file"
    
    # Ajouter un en-tête
    echo "# Niveau de ASCII3D-Bash-Game" >> "$level_file"
    echo "# Format: type x y z scale" >> "$level_file"
    echo "" >> "$level_file"
    
    # Écrire chaque objet
    for obj_id in "${!WORLD_OBJECTS[@]}"; do
        echo "${WORLD_OBJECTS[$obj_id]}" >> "$level_file"
    done
    
    echo "Niveau sauvegardé avec ${#WORLD_OBJECTS[@]} objets."
}
