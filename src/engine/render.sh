#!/bin/bash
#
# Système de rendu ASCII pour le moteur 3D
#

# Importer le script de compatibilité
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/compat.sh"

# Configuration du rendu
SCREEN_WIDTH=80
SCREEN_HEIGHT=24
ASPECT_RATIO=$(bc -l <<< "$SCREEN_WIDTH / $SCREEN_HEIGHT")
FOV=90
Z_NEAR=0.1
Z_FAR=100.0

# Symboles de rendu ASCII par profondeur (du plus proche au plus loin)
DEPTH_CHARS=('@' '#' '8' 'O' '=' '+' ':' '-' '.' ' ')

# Z-buffer pour stocker la profondeur de chaque pixel
declare_A Z_BUFFER

# Initialisation du système de rendu
function init_render() {
    # Obtenir la taille réelle du terminal si possible
    if command -v tput &> /dev/null; then
        SCREEN_HEIGHT=$(tput lines)
        SCREEN_WIDTH=$(tput cols)
        ASPECT_RATIO=$(bc -l <<< "$SCREEN_WIDTH / $SCREEN_HEIGHT")
    fi
    
    # Initialiser le z-buffer
    for ((y=0; y<SCREEN_HEIGHT; y++)); do
        for ((x=0; x<SCREEN_WIDTH; x++)); do
            associative_set Z_BUFFER "$x,$y" $Z_FAR
        done
    done
    
    # Configuration supplémentaire au besoin
    echo "Système de rendu initialisé (${SCREEN_WIDTH}x${SCREEN_HEIGHT})"
}

# Projeter un point 3D sur l'écran 2D
function project_point() {
    local x=$1
    local y=$2
    local z=$3
    
    # Transformation de la caméra
    local transformed_x=$(subtract $x $CAMERA_X)
    local transformed_y=$(subtract $y $CAMERA_Y)
    local transformed_z=$(subtract $z $CAMERA_Z)
    
    # Rotation de la caméra (version simplifiée)
    # Note: Une implémentation complète nécessiterait des matrices de rotation
    local temp_z=$transformed_z
    transformed_z=$(subtract $(multiply $temp_z $(cos $CAMERA_ROT_Y)) $(multiply $transformed_x $(sin $CAMERA_ROT_Y)))
    transformed_x=$(add $(multiply $temp_z $(sin $CAMERA_ROT_Y)) $(multiply $transformed_x $(cos $CAMERA_ROT_Y)))
    
    local temp_y=$transformed_y
    transformed_y=$(subtract $(multiply $temp_y $(cos $CAMERA_ROT_X)) $(multiply $transformed_z $(sin $CAMERA_ROT_X)))
    transformed_z=$(add $(multiply $temp_y $(sin $CAMERA_ROT_X)) $(multiply $transformed_z $(cos $CAMERA_ROT_X)))
    
    # Projection perspective
    if (( $(bc -l <<< "$transformed_z < $Z_NEAR") )); then
        # Point derrière la caméra
        return 1
    fi
    
    local scale_factor=$(divide $FOV $transformed_z)
    local screen_x=$(divide $(multiply $transformed_x $scale_factor) $ASPECT_RATIO)
    local screen_y=$(multiply $transformed_y $scale_factor)
    
    # Conversion vers les coordonnées du terminal
    local pixel_x=$(bc <<< "scale=0; ($SCREEN_WIDTH / 2) + ($screen_x * $SCREEN_WIDTH / 2) / 1")
    local pixel_y=$(bc <<< "scale=0; ($SCREEN_HEIGHT / 2) - ($screen_y * $SCREEN_HEIGHT / 2) / 1")
    
    # Vérifier si le point est visible
    if (( pixel_x >= 0 && pixel_x < SCREEN_WIDTH && pixel_y >= 0 && pixel_y < SCREEN_HEIGHT )); then
        # Stocker les coordonnées projetées et la profondeur
        echo "$pixel_x $pixel_y $transformed_z"
        return 0
    else
        return 1
    fi
}

# Dessiner un point sur l'écran avec test de profondeur
function draw_point() {
    local x=$1
    local y=$2
    local z=$3
    
    # Arrondissement des coordonnées à l'entier le plus proche
    x=$(printf "%.0f" $x)
    y=$(printf "%.0f" $y)
    
    # Test de profondeur (z-buffer)
    local current_z
    current_z=$(associative_get Z_BUFFER "$x,$y")
    
    if (( $(bc -l <<< "$z < $current_z") )); then
        # Mettre à jour le z-buffer
        associative_set Z_BUFFER "$x,$y" "$z"
        
        # Choisir le caractère en fonction de la profondeur
        local depth_index=$(bc <<< "scale=0; (($z - $Z_NEAR) / ($Z_FAR - $Z_NEAR)) * ${#DEPTH_CHARS[@]} / 1")
        if (( depth_index < 0 )); then
            depth_index=0
        elif (( depth_index >= ${#DEPTH_CHARS[@]} )); then
            depth_index=$((${#DEPTH_CHARS[@]} - 1))
        fi
        
        local char=${DEPTH_CHARS[$depth_index]}
        
        # Dessiner le point dans le buffer
        draw_to_buffer $x $y "$char"
    fi
}

# Dessiner une ligne 3D
function draw_line_3d() {
    local x1=$1
    local y1=$2
    local z1=$3
    local x2=$4
    local y2=$5
    local z2=$6
    
    # Projeter les deux extrémités
    local projected1=$(project_point $x1 $y1 $z1)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local projected2=$(project_point $x2 $y2 $z2)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Extraire les coordonnées projetées
    local px1=$(echo $projected1 | cut -d' ' -f1)
    local py1=$(echo $projected1 | cut -d' ' -f2)
    local pz1=$(echo $projected1 | cut -d' ' -f3)
    
    local px2=$(echo $projected2 | cut -d' ' -f1)
    local py2=$(echo $projected2 | cut -d' ' -f2)
    local pz2=$(echo $projected2 | cut -d' ' -f3)
    
    # Dessiner la ligne 2D avec information de profondeur
    draw_line_2d $px1 $py1 $pz1 $px2 $py2 $pz2
}

# Dessiner une ligne 2D avec interpolation de profondeur
function draw_line_2d() {
    local x1=$1
    local y1=$2
    local z1=$3
    local x2=$4
    local y2=$5
    local z2=$6
    
    # Algorithme de Bresenham pour le tracé de ligne 2D
    local dx=$(bc <<< "$x2 - $x1")
    local dy=$(bc <<< "$y2 - $y1")
    local dz=$(bc <<< "$z2 - $z1")
    
    local abs_dx=$(bc <<< "if ($dx < 0) -$dx else $dx")
    local abs_dy=$(bc <<< "if ($dy < 0) -$dy else $dy")
    
    local steps=$(bc <<< "if ($abs_dx > $abs_dy) $abs_dx else $abs_dy")
    
    if [ "$steps" = "0" ]; then
        # Éviter la division par zéro
        draw_point $x1 $y1 $z1
        return
    fi
    
    local x_inc=$(bc -l <<< "$dx / $steps")
    local y_inc=$(bc -l <<< "$dy / $steps")
    local z_inc=$(bc -l <<< "$dz / $steps")
    
    local x=$x1
    local y=$y1
    local z=$z1
    
    for (( i=0; i<=steps; i++ )); do
        draw_point $x $y $z
        x=$(bc -l <<< "$x + $x_inc")
        y=$(bc -l <<< "$y + $y_inc")
        z=$(bc -l <<< "$z + $z_inc")
    done
}

# Dessiner un modèle 3D (cube, sphère, etc.)
function draw_model() {
    local model=$1
    local x=$2
    local y=$3
    local z=$4
    local scale=${5:-1.0}
    
    case "$model" in
        "cube")
            draw_cube $x $y $z $scale
            ;;
        "sphere")
            draw_sphere $x $y $z $scale
            ;;
        *)
            echo "Modèle inconnu: $model"
            ;;
    esac
}

# Dessiner un cube
function draw_cube() {
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
    # Face avant
    draw_line_3d $x1 $y1 $z1 $x2 $y2 $z2
    draw_line_3d $x2 $y2 $z2 $x3 $y3 $z3
    draw_line_3d $x3 $y3 $z3 $x4 $y4 $z4
    draw_line_3d $x4 $y4 $z4 $x1 $y1 $z1
    
    # Face arrière
    draw_line_3d $x5 $y5 $z5 $x6 $y6 $z6
    draw_line_3d $x6 $y6 $z6 $x7 $y7 $z7
    draw_line_3d $x7 $y7 $z7 $x8 $y8 $z8
    draw_line_3d $x8 $y8 $z8 $x5 $y5 $z5
    
    # Connexions
    draw_line_3d $x1 $y1 $z1 $x5 $y5 $z5
    draw_line_3d $x2 $y2 $z2 $x6 $y6 $z6
    draw_line_3d $x3 $y3 $z3 $x7 $y7 $z7
    draw_line_3d $x4 $y4 $z4 $x8 $y8 $z8
}

# Dessiner une sphère approximative
function draw_sphere() {
    local center_x=$1
    local center_y=$2
    local center_z=$3
    local radius=${4:-1.0}
    
    # Nombre de méridiens et parallèles
    local segments=8
    
    # Dessiner les méridiens
    for ((i=0; i<segments; i++)); do
        local angle1=$(bc -l <<< "$i * 2 * 3.14159 / $segments")
        local angle2=$(bc -l <<< "($i + 1) * 2 * 3.14159 / $segments")
        
        for ((j=0; j<segments; j++)); do
            local phi1=$(bc -l <<< "$j * 3.14159 / $segments")
            local phi2=$(bc -l <<< "($j + 1) * 3.14159 / $segments")
            
            # Calculer les points
            local x1=$(bc -l <<< "$center_x + $radius * s($angle1) * s($phi1)")
            local y1=$(bc -l <<< "$center_y + $radius * c($phi1)")
            local z1=$(bc -l <<< "$center_z + $radius * c($angle1) * s($phi1)")
            
            local x2=$(bc -l <<< "$center_x + $radius * s($angle2) * s($phi1)")
            local y2=$(bc -l <<< "$center_y + $radius * c($phi1)")
            local z2=$(bc -l <<< "$center_z + $radius * c($angle2) * s($phi1)")
            
            local x3=$(bc -l <<< "$center_x + $radius * s($angle1) * s($phi2)")
            local y3=$(bc -l <<< "$center_y + $radius * c($phi2)")
            local z3=$(bc -l <<< "$center_z + $radius * c($angle1) * s($phi2)")
            
            # Dessiner les lignes
            draw_line_3d $x1 $y1 $z1 $x2 $y2 $z2
            draw_line_3d $x1 $y1 $z1 $x3 $y3 $z3
        done
    done
}

# Fonction pour rendre la scène complète
function render_world() {
    # Initialiser le z-buffer pour ce frame
    for ((y=0; y<SCREEN_HEIGHT; y++)); do
        for ((x=0; x<SCREEN_WIDTH; x++)); do
            associative_set Z_BUFFER "$x,$y" $Z_FAR
        done
    done
    
    # Demander au module world.sh de dessiner tous les objets
    draw_world_objects
}
