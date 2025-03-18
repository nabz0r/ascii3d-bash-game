#!/bin/bash
#
# Système de textures ASCII pour le moteur 3D
#

# Définir des textures ASCII par défaut
declare -A ASCII_TEXTURES

# Initialiser le système de textures
function init_textures() {
    echo "Initialisation du système de textures ASCII..."
    
    # Définir quelques textures de base
    
    # Texture de brique
    ASCII_TEXTURES["brick"]="#=#=#=
=#=#=#
#=#=#=
=#=#=#"

    # Texture de bois
    ASCII_TEXTURES["wood"]="||||
||||
||||
||||"

    # Texture de pierre
    ASCII_TEXTURES["stone"]="::::
:..:
:..;
::::"

    # Texture d'herbe
    ASCII_TEXTURES["grass"]="\"\"\"\"
\"\"\'\'
\'\'\"\"
\'\'\'\'"

    # Texture d'eau
    ASCII_TEXTURES["water"]="~~~~
~-~~
~~-~
~~~~"

    # Texture de métal
    ASCII_TEXTURES["metal"]="+++:
:+++
+++:
:+++"

    # Texture de lave
    ASCII_TEXTURES["lava"]="%%%%
%&%%
%%&%
%%%%"

    echo "Textures ASCII chargées: ${!ASCII_TEXTURES[@]}"
}

# Charger une texture depuis un fichier
function load_texture_from_file() {
    local name=$1
    local file_path=$2
    
    # Vérifier si le fichier existe
    if [[ -f "$file_path" ]]; then
        # Lire le fichier et stocker son contenu
        ASCII_TEXTURES["$name"]=$(cat "$file_path")
        echo "Texture '$name' chargée depuis $file_path"
    else
        echo "Erreur: Fichier de texture non trouvé: $file_path"
    fi
}

# Créer une nouvelle texture
function create_texture() {
    local name=$1
    local content=$2
    
    ASCII_TEXTURES["$name"]="$content"
    echo "Texture '$name' créée"
}

# Obtenir un caractère de texture à une coordonnée UV donnée
function get_texture_char() {
    local texture_name=$1
    local u=$2  # Coordonnée U (0.0-1.0)
    local v=$3  # Coordonnée V (0.0-1.0)
    
    # Vérifier si la texture existe
    if [[ -z "${ASCII_TEXTURES[$texture_name]}" ]]; then
        # Texture non trouvée, retourner un caractère par défaut
        echo "#"
        return
    fi
    
    # Obtenir les dimensions de la texture
    local texture="${ASCII_TEXTURES[$texture_name]}"
    local lines=()
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$texture"
    
    local height=${#lines[@]}
    local width=${#lines[0]}
    
    # Convertir les coordonnées UV en indices de tableau
    local x=$(bc <<< "scale=0; $u * $width / 1")
    local y=$(bc <<< "scale=0; $v * $height / 1")
    
    # Limiter aux bornes de la texture
    if (( x >= width )); then
        x=$((width - 1))
    elif (( x < 0 )); then
        x=0
    fi
    
    if (( y >= height )); then
        y=$((height - 1))
    elif (( y < 0 )); then
        y=0
    fi
    
    # Extraire le caractère à la position (x,y)
    local line="${lines[$y]}"
    echo "${line:$x:1}"
}

# Dessiner un modèle avec texture
function draw_textured_model() {
    local model=$1
    local texture_name=$2
    local x=$3
    local y=$4
    local z=$5
    local scale=${6:-1.0}
    
    case "$model" in
        "cube")
            draw_textured_cube "$texture_name" $x $y $z $scale
            ;;
        "sphere")
            draw_textured_sphere "$texture_name" $x $y $z $scale
            ;;
        *)
            echo "Modèle texturé non supporté: $model"
            draw_model "$model" $x $y $z $scale
            ;;
    esac
}

# Dessiner un cube avec texture
function draw_textured_cube() {
    local texture_name=$1
    local x=$2
    local y=$3
    local z=$4
    local scale=${5:-1.0}
    
    # Définir les sommets du cube
    local half=$(bc -l <<< "$scale / 2")
    
    # Sommets du cube
    local corners=(
        "$(bc -l <<< "$x - $half") $(bc -l <<< "$y - $half") $(bc -l <<< "$z - $half")"  # 0: avant-bas-gauche
        "$(bc -l <<< "$x + $half") $(bc -l <<< "$y - $half") $(bc -l <<< "$z - $half")"  # 1: avant-bas-droite
        "$(bc -l <<< "$x + $half") $(bc -l <<< "$y + $half") $(bc -l <<< "$z - $half")"  # 2: avant-haut-droite
        "$(bc -l <<< "$x - $half") $(bc -l <<< "$y + $half") $(bc -l <<< "$z - $half")"  # 3: avant-haut-gauche
        "$(bc -l <<< "$x - $half") $(bc -l <<< "$y - $half") $(bc -l <<< "$z + $half")"  # 4: arrière-bas-gauche
        "$(bc -l <<< "$x + $half") $(bc -l <<< "$y - $half") $(bc -l <<< "$z + $half")"  # 5: arrière-bas-droite
        "$(bc -l <<< "$x + $half") $(bc -l <<< "$y + $half") $(bc -l <<< "$z + $half")"  # 6: arrière-haut-droite
        "$(bc -l <<< "$x - $half") $(bc -l <<< "$y + $half") $(bc -l <<< "$z + $half")"  # 7: arrière-haut-gauche
    )
    
    # Définir les faces du cube (4 sommets par face)
    local faces=(
        "0 1 2 3"  # Face avant
        "4 5 6 7"  # Face arrière
        "0 4 7 3"  # Face gauche
        "1 5 6 2"  # Face droite
        "3 2 6 7"  # Face haut
        "0 1 5 4"  # Face bas
    )
    
    # Coordonnées UV pour chaque sommet de chaque face
    local uvs=(
        "0.0 1.0  1.0 1.0  1.0 0.0  0.0 0.0"  # Face avant
        "0.0 1.0  1.0 1.0  1.0 0.0  0.0 0.0"  # Face arrière
        "0.0 1.0  1.0 1.0  1.0 0.0  0.0 0.0"  # Face gauche
        "0.0 1.0  1.0 1.0  1.0 0.0  0.0 0.0"  # Face droite
        "0.0 1.0  1.0 1.0  1.0 0.0  0.0 0.0"  # Face haut
        "0.0 1.0  1.0 1.0  1.0 0.0  0.0 0.0"  # Face bas
    )
    
    # Dessiner chaque face
    for face_idx in {0..5}; do
        local vertices=(${faces[$face_idx]})
        local uv_str=${uvs[$face_idx]}
        local uv_arr=($uv_str)
        
        # Subdiviser la face en plusieurs points pour texture
        local segments=4  # Nombre de subdivisions
        
        for ((i=0; i<segments; i++)); do
            for ((j=0; j<segments; j++)); do
                # Interpoler les positions et les UVs
                local u1=$(bc -l <<< "$i / $segments")
                local v1=$(bc -l <<< "$j / $segments")
                local u2=$(bc -l <<< "($i + 1) / $segments")
                local v2=$(bc -l <<< "($j + 1) / $segments")
                
                # Calculer les coordonnées 3D interpolées
                local p0=(${corners[${vertices[0]}]})
                local p1=(${corners[${vertices[1]}]})
                local p2=(${corners[${vertices[2]}]})
                local p3=(${corners[${vertices[3]}]})
                
                # Interpoler bilinéairement pour obtenir le point
                local x_interp=$(bilinear_interpolate ${p0[0]} ${p1[0]} ${p2[0]} ${p3[0]} $u1 $v1)
                local y_interp=$(bilinear_interpolate ${p0[1]} ${p1[1]} ${p2[1]} ${p3[1]} $u1 $v1)
                local z_interp=$(bilinear_interpolate ${p0[2]} ${p1[2]} ${p2[2]} ${p3[2]} $u1 $v1)
                
                # Calculer les UVs interpolés
                local u_tex=$(bc -l <<< "${uv_arr[0]} + (${uv_arr[2]} - ${uv_arr[0]}) * $u1")
                local v_tex=$(bc -l <<< "${uv_arr[1]} + (${uv_arr[7]} - ${uv_arr[1]}) * $v1")
                
                # Obtenir le caractère de texture
                local tex_char=$(get_texture_char "$texture_name" $u_tex $v_tex)
                
                # Projeter le point 3D en 2D
                local projected=$(project_point $x_interp $y_interp $z_interp)
                if [ $? -eq 0 ]; then
                    local px=$(echo $projected | cut -d' ' -f1)
                    local py=$(echo $projected | cut -d' ' -f2)
                    local pz=$(echo $projected | cut -d' ' -f3)
                    
                    # Dessiner le point avec le caractère de texture
                    draw_textured_point $px $py $pz "$tex_char"
                fi
            done
        done
    done
}

# Dessiner une sphère avec texture
function draw_textured_sphere() {
    local texture_name=$1
    local center_x=$2
    local center_y=$3
    local center_z=$4
    local radius=${5:-1.0}
    
    # Nombre de méridiens et parallèles
    local segments=12
    
    # Dessiner les points de la sphère
    for ((i=0; i<segments; i++)); do
        for ((j=0; j<segments; j++)); do
            # Calculer les coordonnées sphériques
            local theta=$(bc -l <<< "$i * 2 * 3.14159 / $segments")
            local phi=$(bc -l <<< "$j * 3.14159 / $segments")
            
            # Convertir en coordonnées cartésiennes
            local x=$(bc -l <<< "$center_x + $radius * s($theta) * s($phi)")
            local y=$(bc -l <<< "$center_y + $radius * c($phi)")
            local z=$(bc -l <<< "$center_z + $radius * c($theta) * s($phi)")
            
            # Calculer les coordonnées UV
            local u=$(bc -l <<< "$theta / (2 * 3.14159)")
            local v=$(bc -l <<< "$phi / 3.14159")
            
            # Obtenir le caractère de texture
            local tex_char=$(get_texture_char "$texture_name" $u $v)
            
            # Projeter le point 3D en 2D
            local projected=$(project_point $x $y $z)
            if [ $? -eq 0 ]; then
                local px=$(echo $projected | cut -d' ' -f1)
                local py=$(echo $projected | cut -d' ' -f2)
                local pz=$(echo $projected | cut -d' ' -f3)
                
                # Dessiner le point avec le caractère de texture
                draw_textured_point $px $py $pz "$tex_char"
            fi
        done
    done
}

# Dessiner un point avec un caractère de texture
function draw_textured_point() {
    local x=$1
    local y=$2
    local z=$3
    local char=$4
    
    # Arrondissement des coordonnées à l'entier le plus proche
    x=$(printf "%.0f" $x)
    y=$(printf "%.0f" $y)
    
    # Test de profondeur (z-buffer)
    if (( $(bc -l <<< "$z < ${Z_BUFFER["$x,$y"]}") )); then
        # Mettre à jour le z-buffer
        Z_BUFFER["$x,$y"]=$z
        
        # Dessiner le caractère dans le buffer
        draw_to_buffer $x $y "$char"
    fi
}

# Interpolation bilinéaire
function bilinear_interpolate() {
    local x00=$1
    local x10=$2
    local x11=$3
    local x01=$4
    local u=$5
    local v=$6
    
    # Interpolation en x pour y=0
    local x0=$(bc -l <<< "$x00 * (1 - $u) + $x10 * $u")
    
    # Interpolation en x pour y=1
    local x1=$(bc -l <<< "$x01 * (1 - $u) + $x11 * $u")
    
    # Interpolation finale en y
    bc -l <<< "$x0 * (1 - $v) + $x1 * $v"
}

# Initialiser les textures
init_textures
