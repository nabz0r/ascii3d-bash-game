#!/bin/bash
#
# Fonctions mathématiques pour les opérations 3D
#

# Importer le script de compatibilité
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/compat.sh"

# Constantes mathématiques
PI=3.14159265359
TWO_PI=6.28318530718
HALF_PI=1.57079632679

# Optimisation : pré-calculer les valeurs de sinus et cosinus
# pour les angles les plus fréquemment utilisés (0-360 degrés)
declare_A SIN_TABLE
declare_A COS_TABLE

# Initialiser les tables de sinus et cosinus
function init_trig_tables() {
    for ((i=0; i<360; i++)); do
        local rad=$(bc -l <<< "$i * $PI / 180")
        associative_set SIN_TABLE "$i" "$(bc -l <<< "s($rad)")"
        associative_set COS_TABLE "$i" "$(bc -l <<< "c($rad)")"
    done
}

# Fonction sinus optimisée
function sin() {
    local angle=$1
    
    # Normaliser l'angle en degrés entre 0-359
    local deg=$(bc <<< "scale=0; (($angle * 180 / $PI) % 360 + 360) % 360 / 1")
    
    # Utiliser la table précalculée si disponible
    if associative_exists SIN_TABLE "$deg"; then
        echo "$(associative_get SIN_TABLE "$deg")"
    else
        # Fallback sur la fonction native si l'angle n'est pas dans la table
        bc -l <<< "s($angle)"
    fi
}

# Fonction cosinus optimisée
function cos() {
    local angle=$1
    
    # Normaliser l'angle en degrés entre 0-359
    local deg=$(bc <<< "scale=0; (($angle * 180 / $PI) % 360 + 360) % 360 / 1")
    
    # Utiliser la table précalculée si disponible
    if associative_exists COS_TABLE "$deg"; then
        echo "$(associative_get COS_TABLE "$deg")"
    else
        # Fallback sur la fonction native si l'angle n'est pas dans la table
        bc -l <<< "c($angle)"
    fi
}

# Fonction tangente
function tan() {
    local angle=$1
    bc -l <<< "s($angle) / c($angle)"
}

# Addition
function add() {
    bc -l <<< "$1 + $2"
}

# Soustraction
function subtract() {
    bc -l <<< "$1 - $2"
}

# Multiplication
function multiply() {
    bc -l <<< "$1 * $2"
}

# Division
function divide() {
    if (( $(bc -l <<< "$2 == 0") )); then
        echo "1"  # Valeur par défaut pour éviter la division par zéro
    else
        bc -l <<< "$1 / $2"
    fi
}

# Racine carrée
function sqrt() {
    bc -l <<< "sqrt($1)"
}

# Puissance
function pow() {
    bc -l <<< "$1 ^ $2"
}

# Distance entre deux points 3D
function distance3d() {
    local x1=$1
    local y1=$2
    local z1=$3
    local x2=$4
    local y2=$5
    local z2=$6
    
    local dx=$(bc -l <<< "$x2 - $x1")
    local dy=$(bc -l <<< "$y2 - $y1")
    local dz=$(bc -l <<< "$z2 - $z1")
    
    bc -l <<< "sqrt($dx^2 + $dy^2 + $dz^2)"
}

# Normaliser un vecteur 3D
function normalize_vector() {
    local x=$1
    local y=$2
    local z=$3
    
    local length=$(bc -l <<< "sqrt($x^2 + $y^2 + $z^2)")
    
    if (( $(bc -l <<< "$length == 0") )); then
        echo "0 0 0"  # Éviter la division par zéro
    else
        local nx=$(bc -l <<< "$x / $length")
        local ny=$(bc -l <<< "$y / $length")
        local nz=$(bc -l <<< "$z / $length")
        echo "$nx $ny $nz"
    fi
}

# Produit scalaire de deux vecteurs
function dot_product() {
    local x1=$1
    local y1=$2
    local z1=$3
    local x2=$4
    local y2=$5
    local z2=$6
    
    bc -l <<< "$x1 * $x2 + $y1 * $y2 + $z1 * $z2"
}

# Produit vectoriel de deux vecteurs
function cross_product() {
    local x1=$1
    local y1=$2
    local z1=$3
    local x2=$4
    local y2=$5
    local z2=$6
    
    local rx=$(bc -l <<< "$y1 * $z2 - $z1 * $y2")
    local ry=$(bc -l <<< "$z1 * $x2 - $x1 * $z2")
    local rz=$(bc -l <<< "$x1 * $y2 - $y1 * $x2")
    
    echo "$rx $ry $rz"
}

# Interpolation linéaire
function lerp() {
    local a=$1
    local b=$2
    local t=$3  # Facteur entre 0 et 1
    
    bc -l <<< "$a + ($b - $a) * $t"
}

# Initialiser les tables trigonométriques
init_trig_tables
