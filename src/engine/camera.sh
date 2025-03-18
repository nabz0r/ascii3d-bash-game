#!/bin/bash
#
# Système de caméra pour le moteur 3D ASCII
#

# Position de la caméra
CAMERA_X=0.0
CAMERA_Y=0.0
CAMERA_Z=0.0

# Rotation de la caméra (en radians)
CAMERA_ROT_X=0.0  # Rotation autour de l'axe X (pitch)
CAMERA_ROT_Y=0.0  # Rotation autour de l'axe Y (yaw)

# Sensibilité des mouvements
CAMERA_MOVE_SPEED=0.5
CAMERA_ROTATION_SPEED=0.1

# Initialiser la caméra
function init_camera() {
    local x=${1:-0.0}
    local y=${2:-0.0}
    local z=${3:--5.0}  # Par défaut, la caméra est à -5 unités sur l'axe Z
    
    CAMERA_X=$x
    CAMERA_Y=$y
    CAMERA_Z=$z
    
    echo "Caméra initialisée à la position ($CAMERA_X, $CAMERA_Y, $CAMERA_Z)"
}

# Déplacer la caméra vers l'avant
function move_camera_forward() {
    local sin_y=$(sin $CAMERA_ROT_Y)
    local cos_y=$(cos $CAMERA_ROT_Y)
    
    CAMERA_X=$(bc -l <<< "$CAMERA_X + $sin_y * $CAMERA_MOVE_SPEED")
    CAMERA_Z=$(bc -l <<< "$CAMERA_Z + $cos_y * $CAMERA_MOVE_SPEED")
}

# Déplacer la caméra vers l'arrière
function move_camera_backward() {
    local sin_y=$(sin $CAMERA_ROT_Y)
    local cos_y=$(cos $CAMERA_ROT_Y)
    
    CAMERA_X=$(bc -l <<< "$CAMERA_X - $sin_y * $CAMERA_MOVE_SPEED")
    CAMERA_Z=$(bc -l <<< "$CAMERA_Z - $cos_y * $CAMERA_MOVE_SPEED")
}

# Déplacer la caméra vers la gauche
function move_camera_left() {
    local sin_y=$(sin $(bc -l <<< "$CAMERA_ROT_Y - 1.5708"))  # Soustraire PI/2
    local cos_y=$(cos $(bc -l <<< "$CAMERA_ROT_Y - 1.5708"))
    
    CAMERA_X=$(bc -l <<< "$CAMERA_X + $sin_y * $CAMERA_MOVE_SPEED")
    CAMERA_Z=$(bc -l <<< "$CAMERA_Z + $cos_y * $CAMERA_MOVE_SPEED")
}

# Déplacer la caméra vers la droite
function move_camera_right() {
    local sin_y=$(sin $(bc -l <<< "$CAMERA_ROT_Y + 1.5708"))  # Ajouter PI/2
    local cos_y=$(cos $(bc -l <<< "$CAMERA_ROT_Y + 1.5708"))
    
    CAMERA_X=$(bc -l <<< "$CAMERA_X + $sin_y * $CAMERA_MOVE_SPEED")
    CAMERA_Z=$(bc -l <<< "$CAMERA_Z + $cos_y * $CAMERA_MOVE_SPEED")
}

# Déplacer la caméra vers le haut
function move_camera_up() {
    CAMERA_Y=$(bc -l <<< "$CAMERA_Y + $CAMERA_MOVE_SPEED")
}

# Déplacer la caméra vers le bas
function move_camera_down() {
    CAMERA_Y=$(bc -l <<< "$CAMERA_Y - $CAMERA_MOVE_SPEED")
}

# Rotation de la caméra vers le haut
function rotate_camera_up() {
    CAMERA_ROT_X=$(bc -l <<< "$CAMERA_ROT_X + $CAMERA_ROTATION_SPEED")
    
    # Limiter la rotation (éviter le gimbal lock)
    if (( $(bc -l <<< "$CAMERA_ROT_X > 1.5") )); then
        CAMERA_ROT_X=1.5
    fi
}

# Rotation de la caméra vers le bas
function rotate_camera_down() {
    CAMERA_ROT_X=$(bc -l <<< "$CAMERA_ROT_X - $CAMERA_ROTATION_SPEED")
    
    # Limiter la rotation (éviter le gimbal lock)
    if (( $(bc -l <<< "$CAMERA_ROT_X < -1.5") )); then
        CAMERA_ROT_X=-1.5
    fi
}

# Rotation de la caméra vers la gauche
function rotate_camera_left() {
    CAMERA_ROT_Y=$(bc -l <<< "$CAMERA_ROT_Y - $CAMERA_ROTATION_SPEED")
    
    # Normaliser l'angle (entre 0 et 2*PI)
    if (( $(bc -l <<< "$CAMERA_ROT_Y < 0") )); then
        CAMERA_ROT_Y=$(bc -l <<< "$CAMERA_ROT_Y + 6.28318")
    fi
}

# Rotation de la caméra vers la droite
function rotate_camera_right() {
    CAMERA_ROT_Y=$(bc -l <<< "$CAMERA_ROT_Y + $CAMERA_ROTATION_SPEED")
    
    # Normaliser l'angle (entre 0 et 2*PI)
    if (( $(bc -l <<< "$CAMERA_ROT_Y > 6.28318") )); then
        CAMERA_ROT_Y=$(bc -l <<< "$CAMERA_ROT_Y - 6.28318")
    fi
}

# Calculer le rayon de vision à partir de la caméra
function get_camera_ray() {
    local screen_x=$1
    local screen_y=$2
    
    # Convertir les coordonnées d'écran en coordonnées normalisées (-1 à 1)
    local normalized_x=$(bc -l <<< "($screen_x - $SCREEN_WIDTH / 2) / ($SCREEN_WIDTH / 2)")
    local normalized_y=$(bc -l <<< "($SCREEN_HEIGHT / 2 - $screen_y) / ($SCREEN_HEIGHT / 2)")
    
    # Calculer la direction du rayon
    local ray_dir_x=$normalized_x
    local ray_dir_y=$normalized_y
    local ray_dir_z=1.0  # Profondeur fixe pour simplifier
    
    # Appliquer la rotation de la caméra (version simplifiée)
    # Pour une implémentation complète, utiliser des matrices de rotation
    
    # Retourner les composantes du rayon
    echo "$ray_dir_x $ray_dir_y $ray_dir_z"
}
