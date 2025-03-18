#!/bin/bash
#
# Système d'inventaire pour ASCII3D-Bash-Game
#

# Structure de données pour l'inventaire
declare -A PLAYER_INVENTORY
INVENTORY_MAX_SLOTS=20
INVENTORY_CURRENT_SLOTS=0

# Structure de données pour les objets
declare -A ITEMS

# Équipement du joueur
declare -A PLAYER_EQUIPMENT
EQUIPMENT_SLOT_HEAD="head"
EQUIPMENT_SLOT_BODY="body"
EQUIPMENT_SLOT_LEGS="legs"
EQUIPMENT_SLOT_FEET="feet"
EQUIPMENT_SLOT_WEAPON="weapon"
EQUIPMENT_SLOT_SHIELD="shield"
EQUIPMENT_SLOT_ACCESSORY1="accessory1"
EQUIPMENT_SLOT_ACCESSORY2="accessory2"

# Types d'objets
ITEM_TYPE_WEAPON=1
ITEM_TYPE_ARMOR=2
ITEM_TYPE_CONSUMABLE=3
ITEM_TYPE_QUEST=4
ITEM_TYPE_MATERIAL=5
ITEM_TYPE_MISC=6

# Initialiser le système d'inventaire
function init_inventory() {
    echo "Initialisation du système d'inventaire..."
    
    # Définir quelques objets de base
    define_item "health_potion" "Potion de vie" "Restaure 20 points de vie" $ITEM_TYPE_CONSUMABLE 5
    add_item_property "health_potion" "heal_amount" 20
    add_item_property "health_potion" "stackable" true
    add_item_property "health_potion" "max_stack" 10
    
    define_item "mana_potion" "Potion de mana" "Restaure 15 points de mana" $ITEM_TYPE_CONSUMABLE 8
    add_item_property "mana_potion" "mana_amount" 15
    add_item_property "mana_potion" "stackable" true
    add_item_property "mana_potion" "max_stack" 10
    
    define_item "rusty_sword" "Épée rouillée" "Une vieille épée avec quelques traces de rouille" $ITEM_TYPE_WEAPON 10
    add_item_property "rusty_sword" "damage" 5
    add_item_property "rusty_sword" "durability" 50
    add_item_property "rusty_sword" "equipable" true
    add_item_property "rusty_sword" "slot" "$EQUIPMENT_SLOT_WEAPON"
    
    define_item "iron_sword" "Épée en fer" "Une épée solide en fer" $ITEM_TYPE_WEAPON 25
    add_item_property "iron_sword" "damage" 10
    add_item_property "iron_sword" "durability" 100
    add_item_property "iron_sword" "equipable" true
    add_item_property "iron_sword" "slot" "$EQUIPMENT_SLOT_WEAPON"
    
    define_item "magic_sword" "Épée magique" "Une épée qui brille d'une lueur mystérieuse" $ITEM_TYPE_WEAPON 50
    add_item_property "magic_sword" "damage" 15
    add_item_property "magic_sword" "magic_damage" 5
    add_item_property "magic_sword" "durability" 150
    add_item_property "magic_sword" "equipable" true
    add_item_property "magic_sword" "slot" "$EQUIPMENT_SLOT_WEAPON"
    
    define_item "leather_armor" "Armure en cuir" "Une armure légère en cuir" $ITEM_TYPE_ARMOR 15
    add_item_property "leather_armor" "defense" 5
    add_item_property "leather_armor" "durability" 80
    add_item_property "leather_armor" "equipable" true
    add_item_property "leather_armor" "slot" "$EQUIPMENT_SLOT_BODY"
    
    define_item "iron_shield" "Bouclier en fer" "Un solide bouclier en fer" $ITEM_TYPE_ARMOR 20
    add_item_property "iron_shield" "defense" 8
    add_item_property "iron_shield" "durability" 120
    add_item_property "iron_shield" "equipable" true
    add_item_property "iron_shield" "slot" "$EQUIPMENT_SLOT_SHIELD"
    
    define_item "wooden_key" "Clé en bois" "Une clé taillée dans du bois dur" $ITEM_TYPE_QUEST 0
    add_item_property "wooden_key" "quest_item" true
    
    define_item "ancient_gem" "Gemme ancienne" "Une pierre précieuse qui rayonne d'une énergie mystérieuse" $ITEM_TYPE_QUEST 0
    add_item_property "ancient_gem" "quest_item" true
    
    define_item "iron_ore" "Minerai de fer" "Un morceau de minerai de fer brut" $ITEM_TYPE_MATERIAL 3
    add_item_property "iron_ore" "stackable" true
    add_item_property "iron_ore" "max_stack" 20
    
    define_item "magic_scroll" "Parchemin magique" "Un parchemin contenant un sort mystérieux" $ITEM_TYPE_CONSUMABLE 15
    add_item_property "magic_scroll" "spell" "fireball"
    add_item_property "magic_scroll" "stackable" true
    add_item_property "magic_scroll" "max_stack" 5
    
    # Initialiser l'équipement avec des valeurs vides
    PLAYER_EQUIPMENT["$EQUIPMENT_SLOT_HEAD"]=""
    PLAYER_EQUIPMENT["$EQUIPMENT_SLOT_BODY"]=""
    PLAYER_EQUIPMENT["$EQUIPMENT_SLOT_LEGS"]=""
    PLAYER_EQUIPMENT["$EQUIPMENT_SLOT_FEET"]=""
    PLAYER_EQUIPMENT["$EQUIPMENT_SLOT_WEAPON"]=""
    PLAYER_EQUIPMENT["$EQUIPMENT_SLOT_SHIELD"]=""
    PLAYER_EQUIPMENT["$EQUIPMENT_SLOT_ACCESSORY1"]=""
    PLAYER_EQUIPMENT["$EQUIPMENT_SLOT_ACCESSORY2"]=""
    
    echo "Système d'inventaire initialisé avec ${#ITEMS[@]} objets définis."
}

# Définir un nouvel objet
function define_item() {
    local item_id=$1
    local item_name=$2
    local item_description=$3
    local item_type=$4
    local item_value=$5
    
    # Stocker les données de l'objet
    ITEMS["$item_id,name"]="$item_name"
    ITEMS["$item_id,description"]="$item_description"
    ITEMS["$item_id,type"]="$item_type"
    ITEMS["$item_id,value"]="$item_value"
    
    echo "Objet défini: $item_name ($item_id)"
}

# Ajouter une propriété à un objet
function add_item_property() {
    local item_id=$1
    local property_name=$2
    local property_value=$3
    
    # Vérifier si l'objet existe
    if [[ -z "${ITEMS["$item_id,name"]}" ]]; then
        echo "Erreur: Objet non trouvé: $item_id"
        return 1
    fi
    
    # Stocker la propriété
    ITEMS["$item_id,$property_name"]="$property_value"
    
    echo "Propriété '$property_name' ajoutée à l'objet $item_id: $property_value"
}

# Ajouter un objet à l'inventaire
function add_to_inventory() {
    local item_id=$1
    local amount=${2:-1}
    
    # Vérifier si l'objet existe
    if [[ -z "${ITEMS["$item_id,name"]}" ]]; then
        echo "Erreur: Objet non trouvé: $item_id"
        return 1
    fi
    
    # Vérifier si l'objet est empilable
    local is_stackable=${ITEMS["$item_id,stackable"]}
    local max_stack=${ITEMS["$item_id,max_stack"]}
    
    if [[ "$is_stackable" == "true" && -n "$max_stack" ]]; then
        # Vérifier si l'objet est déjà dans l'inventaire
        if [[ -n "${PLAYER_INVENTORY["$item_id"]}" ]]; then
            local current_amount=${PLAYER_INVENTORY["$item_id"]}
            local new_amount=$(bc <<< "$current_amount + $amount")
            
            # Vérifier si la pile dépasse le maximum
            if (( $(bc <<< "$new_amount > $max_stack") )); then
                # Calculer le débordement
                local overflow=$(bc <<< "$new_amount - $max_stack")
                
                # Mettre à jour la pile existante au maximum
                PLAYER_INVENTORY["$item_id"]=$max_stack
                
                # Ajouter le débordement comme nouvelles piles
                while (( $(bc <<< "$overflow > 0") )); do
                    # Créer une nouvelle entrée dans l'inventaire
                    local stack_size=$(bc <<< "if ($overflow > $max_stack) $max_stack else $overflow")
                    
                    # Trouver un slot disponible
                    for ((i=1; i<=INVENTORY_MAX_SLOTS; i++)); do
                        local slot_key="slot_$i"
                        if [[ -z "${PLAYER_INVENTORY["$slot_key"]}" ]]; then
                            # Slot disponible
                            PLAYER_INVENTORY["$slot_key"]="$item_id"
                            PLAYER_INVENTORY["$item_id,$slot_key"]=$stack_size
                            
                            # Mettre à jour le nombre de slots occupés
                            ((INVENTORY_CURRENT_SLOTS++))
                            
                            # Mettre à jour le débordement
                            overflow=$(bc <<< "$overflow - $stack_size")
                            
                            break
                        fi
                    done
                    
                    # Vérifier si l'inventaire est plein
                    if (( INVENTORY_CURRENT_SLOTS >= INVENTORY_MAX_SLOTS )); then
                        echo "Inventaire plein! Impossible d'ajouter plus d'objets."
                        return 1
                    fi
                done
            else
                # Mettre à jour la quantité
                PLAYER_INVENTORY["$item_id"]=$new_amount
            fi
        else
            # Ajouter l'objet à l'inventaire
            PLAYER_INVENTORY["$item_id"]=$amount
            
            # Trouver un slot disponible
            for ((i=1; i<=INVENTORY_MAX_SLOTS; i++)); do
                local slot_key="slot_$i"
                if [[ -z "${PLAYER_INVENTORY["$slot_key"]}" ]]; then
                    # Slot disponible
                    PLAYER_INVENTORY["$slot_key"]="$item_id"
                    
                    # Mettre à jour le nombre de slots occupés
                    ((INVENTORY_CURRENT_SLOTS++))
                    
                    break
                fi
            done
        }
    else
        # Objet non empilable, ajouter chaque instance séparément
        for ((i=0; i<amount; i++)); do
            # Vérifier si l'inventaire est plein
            if (( INVENTORY_CURRENT_SLOTS >= INVENTORY_MAX_SLOTS )); then
                echo "Inventaire plein! Impossible d'ajouter plus d'objets."
                return 1
            }
            
            # Trouver un slot disponible
            for ((j=1; j<=INVENTORY_MAX_SLOTS; j++)); do
                local slot_key="slot_$j"
                if [[ -z "${PLAYER_INVENTORY["$slot_key"]}" ]]; then
                    # Slot disponible
                    PLAYER_INVENTORY["$slot_key"]="$item_id"
                    
                    # Mettre à jour le nombre de slots occupés
                    ((INVENTORY_CURRENT_SLOTS++))
                    
                    break
                fi
            done
        done
    fi
    
    echo "Ajouté $amount x ${ITEMS["$item_id,name"]} à l'inventaire."
    
    # Jouer un son de collecte
    sound_pickup
    
    return 0
}

# Retirer un objet de l'inventaire
function remove_from_inventory() {
    local item_id=$1
    local amount=${2:-1}
    
    # Vérifier si l'objet est dans l'inventaire
    if [[ -z "${PLAYER_INVENTORY["$item_id"]}" ]]; then
        echo "Erreur: Objet non trouvé dans l'inventaire: $item_id"
        return 1
    fi
    
    # Vérifier si l'objet est empilable
    local is_stackable=${ITEMS["$item_id,stackable"]}
    
    if [[ "$is_stackable" == "true" ]]; then
        local current_amount=${PLAYER_INVENTORY["$item_id"]}
        
        # Vérifier si la quantité est suffisante
        if (( $(bc <<< "$current_amount < $amount") )); then
            echo "Erreur: Quantité insuffisante dans l'inventaire. Disponible: $current_amount, Demandé: $amount"
            return 1
        fi
        
        # Mettre à jour la quantité
        local new_amount=$(bc <<< "$current_amount - $amount")
        
        if (( $(bc <<< "$new_amount <= 0") )); then
            # Supprimer l'objet de l'inventaire
            unset PLAYER_INVENTORY["$item_id"]
            
            # Supprimer l'objet des slots
            for ((i=1; i<=INVENTORY_MAX_SLOTS; i++)); do
                local slot_key="slot_$i"
                if [[ "${PLAYER_INVENTORY["$slot_key"]}" == "$item_id" ]]; then
                    unset PLAYER_INVENTORY["$slot_key"]
                    unset PLAYER_INVENTORY["$item_id,$slot_key"]
                    
                    # Mettre à jour le nombre de slots occupés
                    ((INVENTORY_CURRENT_SLOTS--))
                    
                    break
                fi
            done
        else
            # Mettre à jour la quantité
            PLAYER_INVENTORY["$item_id"]=$new_amount
        fi
    else
        # Objet non empilable, supprimer de l'inventaire
        local removed_count=0
        
        for ((i=1; i<=INVENTORY_MAX_SLOTS && removed_count<amount; i++)); do
            local slot_key="slot_$i"
            if [[ "${PLAYER_INVENTORY["$slot_key"]}" == "$item_id" ]]; then
                # Supprimer l'objet du slot
                unset PLAYER_INVENTORY["$slot_key"]
                
                # Mettre à jour le nombre de slots occupés
                ((INVENTORY_CURRENT_SLOTS--))
                
                # Incrémenter le compteur
                ((removed_count++))
            fi
        done
        
        # Vérifier si la quantité demandée a été supprimée
        if (( removed_count < amount )); then
            echo "Attention: Seuls $removed_count/$amount objets ont été supprimés."
        fi
    fi
    
    echo "Retiré $amount x ${ITEMS["$item_id,name"]} de l'inventaire."
    return 0
}

# Utiliser un objet
function use_item() {
    local item_id=$1
    
    # Vérifier si l'objet est dans l'inventaire
    if [[ -z "${PLAYER_INVENTORY["$item_id"]}" ]]; then
        echo "Erreur: Objet non trouvé dans l'inventaire: $item_id"
        return 1
    fi
    
    # Déterminer l'action en fonction du type d'objet
    local item_type=${ITEMS["$item_id,type"]}
    
    case "$item_type" in
        $ITEM_TYPE_CONSUMABLE)
            # Utiliser un consommable
            local heal_amount=${ITEMS["$item_id,heal_amount"]}
            local mana_amount=${ITEMS["$item_id,mana_amount"]}
            local spell=${ITEMS["$item_id,spell"]}
            
            if [[ -n "$heal_amount" ]]; then
                # Restaurer des points de vie
                local current_health=$PLAYER_HEALTH
                local max_health=$PLAYER_MAX_HEALTH
                
                local new_health=$(bc <<< "$current_health + $heal_amount")
                if (( $(bc <<< "$new_health > $max_health") )); then
                    new_health=$max_health
                fi
                
                PLAYER_HEALTH=$new_health
                
                echo "Vous avez utilisé ${ITEMS["$item_id,name"]} et récupéré $heal_amount points de vie."
            elif [[ -n "$mana_amount" ]]; then
                # Restaurer des points de mana
                local current_mana=$PLAYER_MANA
                local max_mana=$PLAYER_MAX_MANA
                
                local new_mana=$(bc <<< "$current_mana + $mana_amount")
                if (( $(bc <<< "$new_mana > $max_mana") )); then
                    new_mana=$max_mana
                fi
                
                PLAYER_MANA=$new_mana
                
                echo "Vous avez utilisé ${ITEMS["$item_id,name"]} et récupéré $mana_amount points de mana."
            elif [[ -n "$spell" ]]; then
                # Lancer un sort depuis un parchemin
                echo "Vous avez utilisé ${ITEMS["$item_id,name"]} et lancé le sort '$spell'."
                cast_spell "$spell"
            else
                echo "Vous avez utilisé ${ITEMS["$item_id,name"]}."
            fi
            
            # Retirer l'objet de l'inventaire
            remove_from_inventory "$item_id" 1
            ;;
            
        $ITEM_TYPE_WEAPON | $ITEM_TYPE_ARMOR)
            # Équiper l'arme ou l'armure
            equip_item "$item_id"
            ;;
            
        $ITEM_TYPE_QUEST)
            # Les objets de quête ne peuvent pas être utilisés directement
            echo "C'est un objet de quête. Vous ne pouvez pas l'utiliser directement."
            return 1
            ;;
            
        *)
            echo "Vous ne pouvez pas utiliser cet objet."
            return 1
            ;;
    esac
    
    return 0
}

# Équiper un objet
function equip_item() {
    local item_id=$1
    
    # Vérifier si l'objet est dans l'inventaire
    if [[ -z "${PLAYER_INVENTORY["$item_id"]}" ]]; then
        echo "Erreur: Objet non trouvé dans l'inventaire: $item_id"
        return 1
    fi
    
    # Vérifier si l'objet est équipable
    local is_equipable=${ITEMS["$item_id,equipable"]}
    if [[ "$is_equipable" != "true" ]]; then
        echo "Erreur: Cet objet ne peut pas être équipé."
        return 1
    fi
    
    # Déterminer l'emplacement d'équipement
    local slot=${ITEMS["$item_id,slot"]}
    if [[ -z "$slot" ]]; then
        echo "Erreur: Emplacement d'équipement non défini pour cet objet."
        return 1
    fi
    
    # Vérifier si un objet est déjà équipé à cet emplacement
    local current_item=${PLAYER_EQUIPMENT["$slot"]}
    if [[ -n "$current_item" ]]; then
        # Déséquiper l'objet actuel
        unequip_item "$slot"
    fi
    
    # Équiper le nouvel objet
    PLAYER_EQUIPMENT["$slot"]="$item_id"
    
    # Retirer l'objet de l'inventaire
    remove_from_inventory "$item_id" 1
    
    echo "Vous avez équipé ${ITEMS["$item_id,name"]}."
    
    # Mettre à jour les statistiques du joueur
    update_player_stats
    
    return 0
}

# Déséquiper un objet
function unequip_item() {
    local slot=$1
    
    # Vérifier si un objet est équipé dans cet emplacement
    local item_id=${PLAYER_EQUIPMENT["$slot"]}
    if [[ -z "$item_id" ]]; then
        echo "Erreur: Aucun objet équipé dans l'emplacement $slot."
        return 1
    fi
    
    # Vérifier s'il y a de la place dans l'inventaire
    if (( INVENTORY_CURRENT_SLOTS >= INVENTORY_MAX_SLOTS )); then
        echo "Erreur: Inventaire plein! Impossible de déséquiper l'objet."
        return 1
    fi
    
    # Ajouter l'objet à l'inventaire
    add_to_inventory "$item_id" 1
    
    # Supprimer l'objet de l'équipement
    PLAYER_EQUIPMENT["$slot"]=""
    
    echo "Vous avez déséquipé ${ITEMS["$item_id,name"]}."
    
    # Mettre à jour les statistiques du joueur
    update_player_stats
    
    return 0
}

# Mettre à jour les statistiques du joueur en fonction de l'équipement
function update_player_stats() {
    # Réinitialiser les bonus d'équipement
    PLAYER_EQUIPMENT_DEFENSE=0
    PLAYER_EQUIPMENT_DAMAGE=0
    PLAYER_EQUIPMENT_MAGIC_DAMAGE=0
    
    # Parcourir tout l'équipement
    for slot in "${!PLAYER_EQUIPMENT[@]}"; do
        local item_id=${PLAYER_EQUIPMENT["$slot"]}
        
        if [[ -n "$item_id" ]]; then
            # Ajouter les bonus de l'objet
            local defense=${ITEMS["$item_id,defense"]}
            local damage=${ITEMS["$item_id,damage"]}
            local magic_damage=${ITEMS["$item_id,magic_damage"]}
            
            if [[ -n "$defense" ]]; then
                PLAYER_EQUIPMENT_DEFENSE=$(bc <<< "$PLAYER_EQUIPMENT_DEFENSE + $defense")
            fi
            
            if [[ -n "$damage" ]]; then
                PLAYER_EQUIPMENT_DAMAGE=$(bc <<< "$PLAYER_EQUIPMENT_DAMAGE + $damage")
            fi
            
            if [[ -n "$magic_damage" ]]; then
                PLAYER_EQUIPMENT_MAGIC_DAMAGE=$(bc <<< "$PLAYER_EQUIPMENT_MAGIC_DAMAGE + $magic_damage")
            fi
        fi
    done
    
    # Mettre à jour les statistiques totales du joueur
    PLAYER_DEFENSE=$(bc <<< "$PLAYER_BASE_DEFENSE + $PLAYER_EQUIPMENT_DEFENSE")
    PLAYER_DAMAGE=$(bc <<< "$PLAYER_BASE_DAMAGE + $PLAYER_EQUIPMENT_DAMAGE")
    PLAYER_MAGIC_DAMAGE=$(bc <<< "$PLAYER_BASE_MAGIC_DAMAGE + $PLAYER_EQUIPMENT_MAGIC_DAMAGE")
    
    echo "Statistiques mises à jour: Défense=$PLAYER_DEFENSE, Dégâts=$PLAYER_DAMAGE, Dégâts magiques=$PLAYER_MAGIC_DAMAGE"
}

# Afficher l'inventaire
function display_inventory() {
    echo "=== Inventaire ($INVENTORY_CURRENT_SLOTS/$INVENTORY_MAX_SLOTS) ==="
    
    # Créer une liste temporaire des objets groupés par type
    declare -A grouped_items
    
    # Parcourir l'inventaire
    for ((i=1; i<=INVENTORY_MAX_SLOTS; i++)); do
        local slot_key="slot_$i"
        local item_id=${PLAYER_INVENTORY["$slot_key"]}
        
        if [[ -n "$item_id" ]]; then
            local item_name=${ITEMS["$item_id,name"]}
            local item_type=${ITEMS["$item_id,type"]}
            local is_stackable=${ITEMS["$item_id,stackable"]}
            
            # Déterminer la quantité
            local quantity=""
            if [[ "$is_stackable" == "true" ]]; then
                local amount=${PLAYER_INVENTORY["$item_id"]}
                quantity=" x$amount"
            fi
            
            # Ajouter à la liste groupée
            if [[ -z "${grouped_items["$item_id"]}" ]]; then
                grouped_items["$item_id"]="$item_name$quantity"
            fi
        fi
    done
    
    # Afficher les objets par type
    local type_names=("" "Armes" "Armures" "Consommables" "Objets de quête" "Matériaux" "Divers")
    
    for type in {1..6}; do
        local type_has_items=false
        
        # Vérifier si ce type a des objets
        for item_id in "${!grouped_items[@]}"; do
            if [[ "${ITEMS["$item_id,type"]}" == "$type" ]]; then
                if ! $type_has_items; then
                    echo "--- ${type_names[$type]} ---"
                    type_has_items=true
                fi
                
                echo "* ${grouped_items["$item_id"]}"
            fi
        done
        
        if $type_has_items; then
            echo ""
        fi
    done
    
    # Si l'inventaire est vide
    if (( INVENTORY_CURRENT_SLOTS == 0 )); then
        echo "L'inventaire est vide."
    fi
}

# Afficher l'équipement
function display_equipment() {
    echo "=== Équipement ==="
    
    # Parcourir tous les emplacements d'équipement
    local slot_names=(
        ["$EQUIPMENT_SLOT_HEAD"]="Tête"
        ["$EQUIPMENT_SLOT_BODY"]="Corps"
        ["$EQUIPMENT_SLOT_LEGS"]="Jambes"
        ["$EQUIPMENT_SLOT_FEET"]="Pieds"
        ["$EQUIPMENT_SLOT_WEAPON"]="Arme"
        ["$EQUIPMENT_SLOT_SHIELD"]="Bouclier"
        ["$EQUIPMENT_SLOT_ACCESSORY1"]="Accessoire 1"
        ["$EQUIPMENT_SLOT_ACCESSORY2"]="Accessoire 2"
    )
    
    for slot in "${!slot_names[@]}"; do
        local item_id=${PLAYER_EQUIPMENT["$slot"]}
        local display_name="${slot_names["$slot"]}"
        
        if [[ -n "$item_id" ]]; then
            local item_name=${ITEMS["$item_id,name"]}
            echo "$display_name: $item_name"
        else
            echo "$display_name: -"
        fi
    done
    
    echo ""
    echo "Défense totale: $PLAYER_DEFENSE"
    echo "Dégâts totaux: $PLAYER_DAMAGE"
    echo "Dégâts magiques: $PLAYER_MAGIC_DAMAGE"
}

# Vérifier si le joueur possède un objet
function has_item() {
    local item_id=$1
    local amount=${2:-1}
    
    # Vérifier si l'objet est dans l'inventaire
    if [[ -z "${PLAYER_INVENTORY["$item_id"]}" ]]; then
        return 1
    fi
    
    # Vérifier si l'objet est empilable
    local is_stackable=${ITEMS["$item_id,stackable"]}
    
    if [[ "$is_stackable" == "true" ]]; then
        local current_amount=${PLAYER_INVENTORY["$item_id"]}
        
        # Vérifier si la quantité est suffisante
        if (( $(bc <<< "$current_amount < $amount") )); then
            return 1
        fi
    else
        # Compter le nombre d'instances de l'objet
        local count=0
        
        for ((i=1; i<=INVENTORY_MAX_SLOTS; i++)); do
            local slot_key="slot_$i"
            if [[ "${PLAYER_INVENTORY["$slot_key"]}" == "$item_id" ]]; then
                ((count++))
            fi
        done
        
        # Vérifier si la quantité est suffisante
        if (( count < amount )); then
            return 1
        fi
    fi
    
    return 0
}

# Initialiser le système d'inventaire
init_inventory
