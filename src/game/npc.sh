#!/bin/bash
#
# Système de PNJ (NPC) et dialogues pour ASCII3D-Bash-Game
#

# Structure de données pour les PNJ
declare -A NPCS
declare -A NPC_DIALOGUES
declare -A NPC_QUESTS
declare -A NPC_SHOPS

# Types de PNJ
NPC_TYPE_VILLAGER=1
NPC_TYPE_GUARD=2
NPC_TYPE_MERCHANT=3
NPC_TYPE_QUEST_GIVER=4
NPC_TYPE_ELDER=5
NPC_TYPE_WIZARD=6
NPC_TYPE_BLACKSMITH=7
NPC_TYPE_INNKEEPER=8

# États des PNJ
NPC_STATE_IDLE=1
NPC_STATE_WALKING=2
NPC_STATE_TALKING=3
NPC_STATE_TRADING=4
NPC_STATE_FOLLOWING=5
NPC_STATE_FLEEING=6

# Nombre de PNJ
NPC_COUNT=0

# PNJ actuel en interaction
CURRENT_NPC=""
DIALOG_STATE=""

# Initialiser le système de PNJ
function init_npcs() {
    echo "Initialisation du système de PNJ..."
    
    # Définir quelques PNJ de base
    define_npc "elder" "Ancien du village" $NPC_TYPE_ELDER 0 0 5
    add_npc_dialogue "elder" "greeting" "Bienvenue, voyageur. Je suis l'Ancien de ce village."
    add_npc_dialogue "elder" "tutorial" "Si vous cherchez de l'aventure, vous devriez commencer par explorer les alentours."
    add_npc_dialogue "elder" "main_quest" "Notre village est menacé par des créatures étranges provenant de la caverne à l'est. Pourriez-vous nous aider?"
    add_npc_quest "elder" "tutorial"
    
    define_npc "merchant" "Marchand" $NPC_TYPE_MERCHANT 5 0 0
    add_npc_dialogue "merchant" "greeting" "Salutations! J'ai toutes sortes de marchandises à vendre."
    add_npc_dialogue "merchant" "shop" "Que puis-je vous proposer aujourd'hui?"
    add_npc_shop "merchant" "health_potion" 20
    add_npc_shop "merchant" "mana_potion" 25
    add_npc_shop "merchant" "magic_scroll" 50
    
    define_npc "blacksmith" "Forgeron" $NPC_TYPE_BLACKSMITH -5 0 0
    add_npc_dialogue "blacksmith" "greeting" "Hmph! Besoin d'armes ou d'armures, étranger?"
    add_npc_dialogue "blacksmith" "shop" "Voici ce que j'ai forgé récemment. Du solide!"
    add_npc_shop "blacksmith" "rusty_sword" 30
    add_npc_shop "blacksmith" "iron_sword" 80
    add_npc_shop "blacksmith" "leather_armor" 50
    add_npc_shop "blacksmith" "iron_shield" 60
    
    define_npc "guard" "Garde" $NPC_TYPE_GUARD 3 0 3
    add_npc_dialogue "guard" "greeting" "Halte là! Ah, ce n'est qu'un voyageur. Soyez prudent, les environs ne sont pas sûrs."
    add_npc_dialogue "guard" "warning" "Des monstres ont été aperçus près de la caverne à l'est. N'y allez pas sans être bien équipé."
    
    define_npc "wizard" "Magicien" $NPC_TYPE_WIZARD 0 0 -5
    add_npc_dialogue "wizard" "greeting" "Mmm, je sens un potentiel magique en vous."
    add_npc_dialogue "wizard" "magic" "Je pourrais vous enseigner quelques sorts... si vous m'apportez certains ingrédients."
    add_npc_quest "wizard" "explore_cave"
    
    define_npc "innkeeper" "Aubergiste" $NPC_TYPE_INNKEEPER -3 0 -3
    add_npc_dialogue "innkeeper" "greeting" "Bienvenue à l'Auberge du Repos! Vous avez l'air fatigué."
    add_npc_dialogue "innkeeper" "rest" "Pour 10 pièces d'or, vous pouvez vous reposer ici et récupérer vos forces."
    add_npc_dialogue "innkeeper" "rumors" "J'ai entendu dire que le vieux magicien cherchait quelqu'un pour explorer la caverne à l'est."
    
    echo "Système de PNJ initialisé avec ${#NPCS[@]} personnages."
}

# Définir un nouveau PNJ
function define_npc() {
    local npc_id=$1
    local npc_name=$2
    local npc_type=$3
    local npc_x=$4
    local npc_y=$5
    local npc_z=$6
    
    # Incrémenter le compteur de PNJ
    ((NPC_COUNT++))
    
    # Stocker les données du PNJ
    NPCS["$npc_id,name"]="$npc_name"
    NPCS["$npc_id,type"]="$npc_type"
    NPCS["$npc_id,x"]="$npc_x"
    NPCS["$npc_id,y"]="$npc_y"
    NPCS["$npc_id,z"]="$npc_z"
    NPCS["$npc_id,state"]="$NPC_STATE_IDLE"
    NPCS["$npc_id,model"]="cube"  # Modèle 3D pour le rendu
    NPCS["$npc_id,scale"]="1.0"   # Échelle du modèle
    
    echo "PNJ défini: $npc_name ($npc_id)"
}

# Ajouter un dialogue à un PNJ
function add_npc_dialogue() {
    local npc_id=$1
    local dialogue_id=$2
    local dialogue_text=$3
    
    # Vérifier si le PNJ existe
    if [[ -z "${NPCS["$npc_id,name"]}" ]]; then
        echo "Erreur: PNJ non trouvé: $npc_id"
        return 1
    fi
    
    # Stocker le dialogue
    NPC_DIALOGUES["$npc_id,$dialogue_id"]="$dialogue_text"
    
    echo "Dialogue '$dialogue_id' ajouté au PNJ $npc_id."
}

# Ajouter une quête à un PNJ
function add_npc_quest() {
    local npc_id=$1
    local quest_id=$2
    
    # Vérifier si le PNJ existe
    if [[ -z "${NPCS["$npc_id,name"]}" ]]; then
        echo "Erreur: PNJ non trouvé: $npc_id"
        return 1
    fi
    
    # Vérifier si la quête existe
    if [[ -z "${QUESTS["$quest_id,name"]}" ]]; then
        echo "Erreur: Quête non trouvée: $quest_id"
        return 1
    fi
    
    # Stocker l'association PNJ-quête
    local quest_count=0
    if [[ -n "${NPC_QUESTS["$npc_id,count"]}" ]]; then
        quest_count=${NPC_QUESTS["$npc_id,count"]}
    fi
    
    ((quest_count++))
    NPC_QUESTS["$npc_id,count"]=$quest_count
    NPC_QUESTS["$npc_id,$quest_count"]="$quest_id"
    
    echo "Quête '$quest_id' associée au PNJ $npc_id."
}

# Ajouter un objet à vendre dans la boutique d'un PNJ
function add_npc_shop() {
    local npc_id=$1
    local item_id=$2
    local price=$3
    
    # Vérifier si le PNJ existe
    if [[ -z "${NPCS["$npc_id,name"]}" ]]; then
        echo "Erreur: PNJ non trouvé: $npc_id"
        return 1
    fi
    
    # Vérifier si l'objet existe
    if [[ -z "${ITEMS["$item_id,name"]}" ]]; then
        echo "Erreur: Objet non trouvé: $item_id"
        return 1
    fi
    
    # Stocker l'objet dans la boutique
    local item_count=0
    if [[ -n "${NPC_SHOPS["$npc_id,count"]}" ]]; then
        item_count=${NPC_SHOPS["$npc_id,count"]}
    fi
    
    ((item_count++))
    NPC_SHOPS["$npc_id,count"]=$item_count
    NPC_SHOPS["$npc_id,$item_count,item"]="$item_id"
    NPC_SHOPS["$npc_id,$item_count,price"]="$price"
    
    echo "Objet '$item_id' ajouté à la boutique du PNJ $npc_id au prix de $price."
}

# Vérifier si un PNJ est proche du joueur
function check_npc_proximity() {
    local player_x=$1
    local player_y=$2
    local player_z=$3
    local detection_range=${4:-2.0}  # Distance de détection par défaut
    
    # Parcourir tous les PNJ
    for npc_id in $(get_all_npcs); do
        # Obtenir la position du PNJ
        local npc_x=${NPCS["$npc_id,x"]}
        local npc_y=${NPCS["$npc_id,y"]}
        local npc_z=${NPCS["$npc_id,z"]}
        
        # Calculer la distance
        local dx=$(bc -l <<< "$npc_x - $player_x")
        local dy=$(bc -l <<< "$npc_y - $player_y")
        local dz=$(bc -l <<< "$npc_z - $player_z")
        local distance=$(bc -l <<< "sqrt($dx^2 + $dy^2 + $dz^2)")
        
        # Vérifier si le PNJ est à portée
        if (( $(bc -l <<< "$distance <= $detection_range") )); then
            # PNJ détecté, retourner son ID
            echo "$npc_id"
            return 0
        fi
    done
    
    # Aucun PNJ détecté
    return 1
}

# Engager la conversation avec un PNJ
function talk_to_npc() {
    local npc_id=$1
    
    # Vérifier si le PNJ existe
    if [[ -z "${NPCS["$npc_id,name"]}" ]]; then
        echo "Erreur: PNJ non trouvé: $npc_id"
        return 1
    fi
    
    # Définir le PNJ actuel
    CURRENT_NPC="$npc_id"
    DIALOG_STATE="greeting"
    
    # Mettre à jour l'état du PNJ
    NPCS["$npc_id,state"]="$NPC_STATE_TALKING"
    
    # Afficher le dialogue de salutation
    display_npc_dialogue "$npc_id" "greeting"
    
    # Afficher les options de dialogue
    display_dialogue_options "$npc_id"
    
    return 0
}

# Afficher un dialogue de PNJ
function display_npc_dialogue() {
    local npc_id=$1
    local dialogue_id=$2
    
    # Vérifier si le PNJ et le dialogue existent
    if [[ -z "${NPCS["$npc_id,name"]}" ]]; then
        echo "Erreur: PNJ non trouvé: $npc_id"
        return 1
    fi
    
    if [[ -z "${NPC_DIALOGUES["$npc_id,$dialogue_id"]}" ]]; then
        echo "Erreur: Dialogue non trouvé: $dialogue_id pour le PNJ $npc_id"
        return 1
    fi
    
    local npc_name=${NPCS["$npc_id,name"]}
    local dialogue_text=${NPC_DIALOGUES["$npc_id,$dialogue_id"]}
    
    # Afficher le dialogue dans une boîte
    create_dialogue_box "$npc_name" "$dialogue_text"
    
    # Jouer un son
    sound_menu_select
    
    return 0
}

# Créer une boîte de dialogue
function create_dialogue_box() {
    local speaker=$1
    local text=$2
    
    # Effacer l'ancien dialogue
    local box_x=5
    local box_y=$((SCREEN_HEIGHT - 12))
    local box_width=$((SCREEN_WIDTH - 10))
    local box_height=8
    
    # Dessiner la boîte
    tput cup $box_y $box_x
    echo -n "┌$(printf "%*s" $box_width | tr ' ' '─')┐"
    
    for ((i=1; i<box_height-1; i++)); do
        tput cup $((box_y+i)) $box_x
        echo -n "│$(printf "%*s" $box_width)│"
    done
    
    tput cup $((box_y+box_height-1)) $box_x
    echo -n "└$(printf "%*s" $box_width | tr ' ' '─')┘"
    
    # Afficher le nom du locuteur
    tput cup $box_y $((box_x + 2))
    echo -n " $speaker "
    
    # Découper le texte en lignes pour qu'il tienne dans la boîte
    local max_line_length=$((box_width - 2))
    local remaining_text="$text"
    local line_count=0
    
    while [[ -n "$remaining_text" && $line_count -lt $((box_height - 3)) ]]; do
        # Extraire une partie du texte qui tient sur une ligne
        local line_text=""
        if (( ${#remaining_text} > max_line_length )); then
            # Chercher un espace pour couper la ligne proprement
            local cut_pos=$max_line_length
            while (( cut_pos > 0 )) && [[ "${remaining_text:cut_pos:1}" != " " ]]; do
                ((cut_pos--))
            done
            
            if (( cut_pos == 0 )); then
                # Pas d'espace trouvé, couper au max_line_length
                cut_pos=$max_line_length
            fi
            
            line_text="${remaining_text:0:cut_pos}"
            remaining_text="${remaining_text:cut_pos+1}"
        else
            line_text="$remaining_text"
            remaining_text=""
        fi
        
        # Afficher la ligne
        tput cup $((box_y + 2 + line_count)) $((box_x + 2))
        echo -n "$line_text"
        
        ((line_count++))
    done
    
    # Si le texte est trop long, indiquer qu'il y a plus
    if [[ -n "$remaining_text" ]]; then
        tput cup $((box_y + box_height - 2)) $((box_x + box_width - 10))
        echo -n "[Suite...]"
    else
        # Sinon, indiquer d'appuyer sur une touche
        tput cup $((box_y + box_height - 2)) $((box_x + box_width - 25))
        echo -n "[Appuyez sur Entrée pour continuer]"
    fi
}

# Afficher les options de dialogue
function display_dialogue_options() {
    local npc_id=$1
    
    # Vérifier si le PNJ existe
    if [[ -z "${NPCS["$npc_id,name"]}" ]]; then
        echo "Erreur: PNJ non trouvé: $npc_id"
        return 1
    fi
    
    local options_x=5
    local options_y=$((SCREEN_HEIGHT - 3))
    local options_width=$((SCREEN_WIDTH - 10))
    
    # Effacer les anciennes options
    tput cup $options_y $options_x
    echo -n "$(printf "%*s" $options_width)"
    
    # Déterminer les options disponibles en fonction du type de PNJ
    local npc_type=${NPCS["$npc_id,type"]}
    local options=""
    
    case "$npc_type" in
        $NPC_TYPE_VILLAGER|$NPC_TYPE_GUARD|$NPC_TYPE_ELDER)
            options="1. Parler   2. Au revoir"
            ;;
        $NPC_TYPE_MERCHANT|$NPC_TYPE_BLACKSMITH)
            options="1. Parler   2. Acheter   3. Vendre   4. Au revoir"
            ;;
        $NPC_TYPE_QUEST_GIVER|$NPC_TYPE_WIZARD)
            options="1. Parler   2. Quêtes   3. Au revoir"
            ;;
        $NPC_TYPE_INNKEEPER)
            options="1. Parler   2. Se reposer   3. Au revoir"
            ;;
        *)
            options="1. Parler   2. Au revoir"
            ;;
    esac
    
    # Afficher les options
    tput cup $options_y $options_x
    echo -n "$options"
    
    return 0
}

# Gérer la sélection d'une option de dialogue
function select_dialogue_option() {
    local option=$1
    
    # Vérifier si un dialogue est en cours
    if [[ -z "$CURRENT_NPC" ]]; then
        echo "Erreur: Aucun dialogue en cours."
        return 1
    fi
    
    local npc_id="$CURRENT_NPC"
    local npc_type=${NPCS["$npc_id,type"]}
    
    case "$npc_type" in
        $NPC_TYPE_VILLAGER|$NPC_TYPE_GUARD|$NPC_TYPE_ELDER)
            case "$option" in
                1) # Parler
                    cycle_dialogue "$npc_id"
                    ;;
                2) # Au revoir
                    end_dialogue
                    ;;
                *)
                    echo "Option invalide."
                    ;;
            esac
            ;;
        $NPC_TYPE_MERCHANT|$NPC_TYPE_BLACKSMITH)
            case "$option" in
                1) # Parler
                    cycle_dialogue "$npc_id"
                    ;;
                2) # Acheter
                    show_shop "$npc_id"
                    ;;
                3) # Vendre
                    show_sell_menu
                    ;;
                4) # Au revoir
                    end_dialogue
                    ;;
                *)
                    echo "Option invalide."
                    ;;
            esac
            ;;
        $NPC_TYPE_QUEST_GIVER|$NPC_TYPE_WIZARD)
            case "$option" in
                1) # Parler
                    cycle_dialogue "$npc_id"
                    ;;
                2) # Quêtes
                    show_npc_quests "$npc_id"
                    ;;
                3) # Au revoir
                    end_dialogue
                    ;;
                *)
                    echo "Option invalide."
                    ;;
            esac
            ;;
        $NPC_TYPE_INNKEEPER)
            case "$option" in
                1) # Parler
                    cycle_dialogue "$npc_id"
                    ;;
                2) # Se reposer
                    rest_at_inn
                    ;;
                3) # Au revoir
                    end_dialogue
                    ;;
                *)
                    echo "Option invalide."
                    ;;
            esac
            ;;
        *)
            case "$option" in
                1) # Parler
                    cycle_dialogue "$npc_id"
                    ;;
                2) # Au revoir
                    end_dialogue
                    ;;
                *)
                    echo "Option invalide."
                    ;;
            esac
            ;;
    esac
    
    return 0
}

# Avancer dans le dialogue
function cycle_dialogue() {
    local npc_id=$1
    
    # Vérifier si le PNJ existe
    if [[ -z "${NPCS["$npc_id,name"]}" ]]; then
        echo "Erreur: PNJ non trouvé: $npc_id"
        return 1
    fi
    
    # Déterminer le prochain dialogue en fonction de l'état actuel
    case "$DIALOG_STATE" in
        "greeting")
            # Passer à un dialogue différent selon le type de PNJ
            local npc_type=${NPCS["$npc_id,type"]}
            
            case "$npc_type" in
                $NPC_TYPE_VILLAGER|$NPC_TYPE_GUARD)
                    DIALOG_STATE="warning"
                    ;;
                $NPC_TYPE_MERCHANT|$NPC_TYPE_BLACKSMITH)
                    DIALOG_STATE="shop"
                    ;;
                $NPC_TYPE_QUEST_GIVER|$NPC_TYPE_WIZARD)
                    DIALOG_STATE="main_quest"
                    ;;
                $NPC_TYPE_ELDER)
                    DIALOG_STATE="tutorial"
                    ;;
                $NPC_TYPE_INNKEEPER)
                    DIALOG_STATE="rumors"
                    ;;
                *)
                    DIALOG_STATE="greeting"  # Rester sur le même dialogue
                    ;;
            esac
            ;;
        *)
            # Revenir à la salutation si on a parcouru tous les dialogues
            DIALOG_STATE="greeting"
            ;;
    esac
    
    # Afficher le nouveau dialogue
    if [[ -n "${NPC_DIALOGUES["$npc_id,$DIALOG_STATE"]}" ]]; then
        display_npc_dialogue "$npc_id" "$DIALOG_STATE"
    else
        # Si le dialogue spécifique n'existe pas, revenir à la salutation
        DIALOG_STATE="greeting"
        display_npc_dialogue "$npc_id" "$DIALOG_STATE"
    fi
    
    # Afficher les options
    display_dialogue_options "$npc_id"
    
    return 0
}

# Terminer le dialogue
function end_dialogue() {
    # Vérifier si un dialogue est en cours
    if [[ -z "$CURRENT_NPC" ]]; then
        return 1
    fi
    
    local npc_id="$CURRENT_NPC"
    
    # Remettre le PNJ à l'état inactif
    NPCS["$npc_id,state"]="$NPC_STATE_IDLE"
    
    # Effacer la boîte de dialogue
    local box_x=5
    local box_y=$((SCREEN_HEIGHT - 12))
    local box_width=$((SCREEN_WIDTH - 10))
    local box_height=8
    
    for ((i=0; i<box_height; i++)); do
        tput cup $((box_y+i)) $box_x
        echo -n "$(printf "%*s" $((box_width + 2)))"
    done
    
    # Effacer les options
    local options_y=$((SCREEN_HEIGHT - 3))
    tput cup $options_y $box_x
    echo -n "$(printf "%*s" $((box_width + 2)))"
    
    # Réinitialiser les variables
    CURRENT_NPC=""
    DIALOG_STATE=""
    
    return 0
}

# Afficher la boutique d'un PNJ
function show_shop() {
    local npc_id=$1
    
    # Vérifier si le PNJ existe et a une boutique
    if [[ -z "${NPCS["$npc_id,name"]}" ]]; then
        echo "Erreur: PNJ non trouvé: $npc_id"
        return 1
    fi
    
    local item_count=${NPC_SHOPS["$npc_id,count"]}
    if [[ -z "$item_count" || "$item_count" -eq 0 ]]; then
        echo "Ce PNJ n'a rien à vendre."
        return 1
    fi
    
    # Mettre le PNJ en mode commerce
    NPCS["$npc_id,state"]="$NPC_STATE_TRADING"
    
    # Afficher la boîte de commerce
    local shop_x=10
    local shop_y=5
    local shop_width=60
    local shop_height=$((item_count + 7))
    
    # Dessiner la boîte
    tput cup $shop_y $shop_x
    echo -n "┌$(printf "%*s" $shop_width | tr ' ' '─')┐"
    
    for ((i=1; i<shop_height-1; i++)); do
        tput cup $((shop_y+i)) $shop_x
        echo -n "│$(printf "%*s" $shop_width)│"
    done
    
    tput cup $((shop_y+shop_height-1)) $shop_x
    echo -n "└$(printf "%*s" $shop_width | tr ' ' '─')┘"
    
    # Afficher le titre
    local npc_name=${NPCS["$npc_id,name"]}
    tput cup $shop_y $((shop_x + 2))
    echo -n " Boutique de $npc_name "
    
    # Afficher l'or du joueur
    tput cup $((shop_y+2)) $((shop_x + 2))
    echo -n "Votre or: $PLAYER_GOLD"
    
    # Afficher les objets à vendre
    tput cup $((shop_y+4)) $((shop_x + 2))
    echo -n "ID  Objet                   Prix   Description"
    tput cup $((shop_y+5)) $((shop_x + 2))
    echo -n "─────────────────────────────────────────────────"
    
    for ((i=1; i<=item_count; i++)); do
        local item_id=${NPC_SHOPS["$npc_id,$i,item"]}
        local price=${NPC_SHOPS["$npc_id,$i,price"]}
        local item_name=${ITEMS["$item_id,name"]}
        local item_desc=${ITEMS["$item_id,description"]}
        
        # Tronquer la description si nécessaire
        if (( ${#item_desc} > 25 )); then
            item_desc="${item_desc:0:22}..."
        fi
        
        # Afficher la ligne
        tput cup $((shop_y+5+i)) $((shop_x + 2))
        printf "%-3d %-22s %-6d %s" $i "$item_name" $price "$item_desc"
    done
    
    # Afficher les instructions
    tput cup $((shop_y+shop_height-2)) $((shop_x + 2))
    echo -n "Entrez le numéro de l'objet à acheter ou 0 pour quitter:"
    
    # Lire la sélection
    local selection
    tput cup $((shop_y+shop_height-2)) $((shop_x + 55))
    read -n 2 selection
    
    # Traiter la sélection
    if [[ "$selection" == "0" ]]; then
        # Retourner au dialogue
        NPCS["$npc_id,state"]="$NPC_STATE_TALKING"
        
        # Effacer la boîte de commerce
        for ((i=0; i<shop_height; i++)); do
            tput cup $((shop_y+i)) $shop_x
            echo -n "$(printf "%*s" $((shop_width + 2)))"
        done
        
        # Restaurer le dialogue
        display_npc_dialogue "$npc_id" "$DIALOG_STATE"
        display_dialogue_options "$npc_id"
    elif (( selection >= 1 && selection <= item_count )); then
        # Acheter l'objet
        local item_id=${NPC_SHOPS["$npc_id,$selection,item"]}
        local price=${NPC_SHOPS["$npc_id,$selection,price"]}
        
        buy_item "$npc_id" "$item_id" "$price"
        
        # Afficher à nouveau la boutique
        show_shop "$npc_id"
    else
        # Sélection invalide
        tput cup $((shop_y+shop_height-3)) $((shop_x + 2))
        echo -n "Sélection invalide. Appuyez sur une touche pour continuer."
        read -n 1
        
        # Afficher à nouveau la boutique
        show_shop "$npc_id"
    fi
    
    return 0
}

# Acheter un objet
function buy_item() {
    local npc_id=$1
    local item_id=$2
    local price=$3
    
    # Vérifier si le joueur a assez d'or
    if (( PLAYER_GOLD < price )); then
        local shop_x=10
        local shop_y=5
        local shop_width=60
        local item_count=${NPC_SHOPS["$npc_id,count"]}
        local shop_height=$((item_count + 7))
        
        tput cup $((shop_y+shop_height-3)) $((shop_x + 2))
        echo -n "Vous n'avez pas assez d'or! Appuyez sur une touche."
        read -n 1
        return 1
    fi
    
    # Vérifier si l'inventaire est plein
    if (( INVENTORY_CURRENT_SLOTS >= INVENTORY_MAX_SLOTS )); then
        local shop_x=10
        local shop_y=5
        local shop_width=60
        local item_count=${NPC_SHOPS["$npc_id,count"]}
        local shop_height=$((item_count + 7))
        
        tput cup $((shop_y+shop_height-3)) $((shop_x + 2))
        echo -n "Votre inventaire est plein! Appuyez sur une touche."
        read -n 1
        return 1
    fi
    
    # Déduire l'or
    PLAYER_GOLD=$((PLAYER_GOLD - price))
    
    # Ajouter l'objet à l'inventaire
    add_to_inventory "$item_id" 1
    
    local shop_x=10
    local shop_y=5
    local shop_width=60
    local item_count=${NPC_SHOPS["$npc_id,count"]}
    local shop_height=$((item_count + 7))
    
    tput cup $((shop_y+shop_height-3)) $((shop_x + 2))
    echo -n "Vous avez acheté ${ITEMS["$item_id,name"]}! Appuyez sur une touche."
    read -n 1
    
    return 0
}

# Afficher le menu de vente
function show_sell_menu() {
    # Vérifier si un dialogue est en cours
    if [[ -z "$CURRENT_NPC" ]]; then
        echo "Erreur: Aucun dialogue en cours."
        return 1
    fi
    
    local npc_id="$CURRENT_NPC"
    
    # Mettre le PNJ en mode commerce
    NPCS["$npc_id,state"]="$NPC_STATE_TRADING"
    
    # Afficher la boîte de vente
    local shop_x=10
    local shop_y=5
    local shop_width=60
    local shop_height=20
    
    # Dessiner la boîte
    tput cup $shop_y $shop_x
    echo -n "┌$(printf "%*s" $shop_width | tr ' ' '─')┐"
    
    for ((i=1; i<shop_height-1; i++)); do
        tput cup $((shop_y+i)) $shop_x
        echo -n "│$(printf "%*s" $shop_width)│"
    done
    
    tput cup $((shop_y+shop_height-1)) $shop_x
    echo -n "└$(printf "%*s" $shop_width | tr ' ' '─')┘"
    
    # Afficher le titre
    local npc_name=${NPCS["$npc_id,name"]}
    tput cup $shop_y $((shop_x + 2))
    echo -n " Vendre à $npc_name "
    
    # Afficher l'or du joueur
    tput cup $((shop_y+2)) $((shop_x + 2))
    echo -n "Votre or: $PLAYER_GOLD"
    
    # Afficher l'inventaire
    tput cup $((shop_y+4)) $((shop_x + 2))
    echo -n "ID  Objet                   Prix   Description"
    tput cup $((shop_y+5)) $((shop_x + 2))
    echo -n "─────────────────────────────────────────────────"
    
    # Créer une liste temporaire des objets dans l'inventaire
    declare -A inventory_list
    local item_count=0
    
    for ((i=1; i<=INVENTORY_MAX_SLOTS; i++)); do
        local slot_key="slot_$i"
        local item_id=${PLAYER_INVENTORY["$slot_key"]}
        
        if [[ -n "$item_id" ]]; then
            # Vérifier si l'objet est déjà dans la liste
            if [[ -z "${inventory_list["$item_id"]}" ]]; then
                ((item_count++))
                inventory_list["$item_id"]=$item_count
                
                local item_name=${ITEMS["$item_id,name"]}
                local item_desc=${ITEMS["$item_id,description"]}
                local item_value=${ITEMS["$item_id,value"]}
                local sell_price=$((item_value / 2))
                
                # Tronquer la description si nécessaire
                if (( ${#item_desc} > 25 )); then
                    item_desc="${item_desc:0:22}..."
                fi
                
                # Afficher la ligne si on a de la place
                if (( item_count <= 10 )); then
                    tput cup $((shop_y+5+item_count)) $((shop_x + 2))
                    printf "%-3d %-22s %-6d %s" $item_count "$item_name" $sell_price "$item_desc"
                fi
            fi
        fi
    done
    
    # Afficher les instructions
    tput cup $((shop_y+shop_height-2)) $((shop_x + 2))
    echo -n "Entrez le numéro de l'objet à vendre ou 0 pour quitter:"
    
    # Lire la sélection
    local selection
    tput cup $((shop_y+shop_height-2)) $((shop_x + 55))
    read -n 2 selection
    
    # Traiter la sélection
    if [[ "$selection" == "0" ]]; then
        # Retourner au dialogue
        NPCS["$npc_id,state"]="$NPC_STATE_TALKING"
        
        # Effacer la boîte de vente
        for ((i=0; i<shop_height; i++)); do
            tput cup $((shop_y+i)) $shop_x
            echo -n "$(printf "%*s" $((shop_width + 2)))"
        done
        
        # Restaurer le dialogue
        display_npc_dialogue "$npc_id" "$DIALOG_STATE"
        display_dialogue_options "$npc_id"
    elif (( selection >= 1 && selection <= item_count )); then
        # Trouver l'objet correspondant
        local selected_item=""
        
        for item_id in "${!inventory_list[@]}"; do
            if [[ "${inventory_list["$item_id"]}" == "$selection" ]]; then
                selected_item="$item_id"
                break
            fi
        done
        
        if [[ -n "$selected_item" ]]; then
            # Vendre l'objet
            local item_value=${ITEMS["$selected_item,value"]}
            local sell_price=$((item_value / 2))
            
            sell_item "$selected_item" "$sell_price"
        fi
        
        # Afficher à nouveau le menu de vente
        show_sell_menu
    else
        # Sélection invalide
        tput cup $((shop_y+shop_height-3)) $((shop_x + 2))
        echo -n "Sélection invalide. Appuyez sur une touche pour continuer."
        read -n 1
        
        # Afficher à nouveau le menu de vente
        show_sell_menu
    fi
    
    return 0
}

# Vendre un objet
function sell_item() {
    local item_id=$1
    local price=$2
    
    # Vérifier si le joueur possède l'objet
    if ! has_item "$item_id" 1; then
        return 1
    fi
    
    # Retirer l'objet de l'inventaire
    remove_from_inventory "$item_id" 1
    
    # Ajouter l'or
    PLAYER_GOLD=$((PLAYER_GOLD + price))
    
    local shop_x=10
    local shop_y=5
    local shop_width=60
    local shop_height=20
    
    tput cup $((shop_y+shop_height-3)) $((shop_x + 2))
    echo -n "Vous avez vendu ${ITEMS["$item_id,name"]} pour $price pièces d'or! Appuyez sur une touche."
    read -n 1
    
    return 0
}

# Afficher les quêtes d'un PNJ
function show_npc_quests() {
    local npc_id=$1
    
    # Vérifier si le PNJ existe et a des quêtes
    if [[ -z "${NPCS["$npc_id,name"]}" ]]; then
        echo "Erreur: PNJ non trouvé: $npc_id"
        return 1
    fi
    
    local quest_count=${NPC_QUESTS["$npc_id,count"]}
    if [[ -z "$quest_count" || "$quest_count" -eq 0 ]]; then
        # Afficher un message
        local npc_name=${NPCS["$npc_id,name"]}
        create_dialogue_box "$npc_name" "Je n'ai pas de quêtes pour vous en ce moment."
        
        # Attendre une touche
        read -n 1
        
        # Restaurer le dialogue
        display_npc_dialogue "$npc_id" "$DIALOG_STATE"
        display_dialogue_options "$npc_id"
        
        return 1
    fi
    
    # Afficher la boîte de quêtes
    local quest_x=10
    local quest_y=5
    local quest_width=60
    local quest_height=$((quest_count * 3 + 7))
    
    # Dessiner la boîte
    tput cup $quest_y $quest_x
    echo -n "┌$(printf "%*s" $quest_width | tr ' ' '─')┐"
    
    for ((i=1; i<quest_height-1; i++)); do
        tput cup $((quest_y+i)) $quest_x
        echo -n "│$(printf "%*s" $quest_width)│"
    done
    
    tput cup $((quest_y+quest_height-1)) $quest_x
    echo -n "└$(printf "%*s" $quest_width | tr ' ' '─')┘"
    
    # Afficher le titre
    local npc_name=${NPCS["$npc_id,name"]}
    tput cup $quest_y $((quest_x + 2))
    echo -n " Quêtes de $npc_name "
    
    # Afficher les quêtes
    local quest_y_offset=3
    
    for ((i=1; i<=quest_count; i++)); do
        local quest_id=${NPC_QUESTS["$npc_id,$i"]}
        local quest_name=${QUESTS["$quest_id,name"]}
        local quest_desc=${QUESTS["$quest_id,description"]}
        local quest_state=${QUESTS["$quest_id,state"]}
        
        # Déterminer l'état de la quête
        local state_text=""
        case "$quest_state" in
            $QUEST_STATE_UNAVAILABLE) state_text="Non disponible" ;;
            $QUEST_STATE_AVAILABLE) state_text="Disponible" ;;
            $QUEST_STATE_ACTIVE) state_text="En cours" ;;
            $QUEST_STATE_COMPLETED) state_text="Terminée" ;;
            $QUEST_STATE_FAILED) state_text="Échouée" ;;
            *) state_text="Inconnu" ;;
        esac
        
        # Afficher les informations de la quête
        tput cup $((quest_y + quest_y_offset)) $((quest_x + 2))
        echo -n "$i. $quest_name [$state_text]"
        
        tput cup $((quest_y + quest_y_offset + 1)) $((quest_x + 4))
        echo -n "$quest_desc"
        
        quest_y_offset=$((quest_y_offset + 3))
    done
    
    # Afficher les instructions
    tput cup $((quest_y+quest_height-2)) $((quest_x + 2))
    echo -n "Entrez le numéro de la quête à accepter ou 0 pour quitter:"
    
    # Lire la sélection
    local selection
    tput cup $((quest_y+quest_height-2)) $((quest_x + 55))
    read -n 2 selection
    
    # Traiter la sélection
    if [[ "$selection" == "0" ]]; then
        # Retourner au dialogue
        
        # Effacer la boîte de quêtes
        for ((i=0; i<quest_height; i++)); do
            tput cup $((quest_y+i)) $quest_x
            echo -n "$(printf "%*s" $((quest_width + 2)))"
        done
        
        # Restaurer le dialogue
        display_npc_dialogue "$npc_id" "$DIALOG_STATE"
        display_dialogue_options "$npc_id"
    elif (( selection >= 1 && selection <= quest_count )); then
        # Accepter la quête
        local quest_id=${NPC_QUESTS["$npc_id,$selection"]}
        
        if is_quest_available "$quest_id"; then
            accept_quest "$quest_id"
            
            # Afficher un message de confirmation
            local npc_name=${NPCS["$npc_id,name"]}
            create_dialogue_box "$npc_name" "Excellent! J'ai confiance en vos capacités. Revenez me voir quand vous aurez terminé."
            
            # Attendre une touche
            read -n 1
        else
            # Afficher un message
            local npc_name=${NPCS["$npc_id,name"]}
            create_dialogue_box "$npc_name" "Cette quête n'est pas disponible pour le moment. Revenez plus tard."
            
            # Attendre une touche
            read -n 1
        fi
        
        # Afficher à nouveau les quêtes
        show_npc_quests "$npc_id"
    else
        # Sélection invalide
        tput cup $((quest_y+quest_height-3)) $((quest_x + 2))
        echo -n "Sélection invalide. Appuyez sur une touche pour continuer."
        read -n 1
        
        # Afficher à nouveau les quêtes
        show_npc_quests "$npc_id"
    fi
    
    return 0
}

# Se reposer à l'auberge
function rest_at_inn() {
    # Vérifier si un dialogue est en cours
    if [[ -z "$CURRENT_NPC" ]]; then
        echo "Erreur: Aucun dialogue en cours."
        return 1
    fi
    
    local npc_id="$CURRENT_NPC"
    local npc_name=${NPCS["$npc_id,name"]}
    local rest_cost=10
    
    # Vérifier si le joueur a assez d'or
    if (( PLAYER_GOLD < rest_cost )); then
        create_dialogue_box "$npc_name" "Vous n'avez pas assez d'or. Le repos coûte $rest_cost pièces d'or."
        
        # Attendre une touche
        read -n 1
        
        # Restaurer le dialogue
        display_npc_dialogue "$npc_id" "$DIALOG_STATE"
        display_dialogue_options "$npc_id"
        
        return 1
    fi
    
    # Déduire l'or
    PLAYER_GOLD=$((PLAYER_GOLD - rest_cost))
    
    # Récupérer tous les PV et MP
    PLAYER_HEALTH=$PLAYER_MAX_HEALTH
    PLAYER_MANA=$PLAYER_MAX_MANA
    
    # Afficher un message
    create_dialogue_box "$npc_name" "Vous vous reposez confortablement et récupérez toutes vos forces. Vos PV et MP sont restaurés."
    
    # Attendre une touche
    read -n 1
    
    # Restaurer le dialogue
    display_npc_dialogue "$npc_id" "$DIALOG_STATE"
    display_dialogue_options "$npc_id"
    
    return 0
}

# Rendre les PNJ aux coordonnées spécifiées
function render_npcs() {
    # Parcourir tous les PNJ
    for npc_id in $(get_all_npcs); do
        # Obtenir les données du PNJ
        local npc_x=${NPCS["$npc_id,x"]}
        local npc_y=${NPCS["$npc_id,y"]}
        local npc_z=${NPCS["$npc_id,z"]}
        local npc_model=${NPCS["$npc_id,model"]}
        local npc_scale=${NPCS["$npc_id,scale"]}
        
        # Dessiner le modèle du PNJ
        draw_model "$npc_model" $npc_x $npc_y $npc_z $npc_scale
    done
}

# Obtenir tous les PNJ
function get_all_npcs() {
    local npcs=()
    
    # Parcourir tous les PNJ
    for key in "${!NPCS[@]}"; do
        # Extraire les IDs de PNJ (uniquement les clés de type "npc_id,name")
        if [[ "$key" == *",name" ]]; then
            local npc_id="${key%,name}"
            npcs+=("$npc_id")
        fi
    done
    
    # Retourner la liste des PNJ
    echo "${npcs[@]}"
}

# Initialiser le système de PNJ
init_npcs
