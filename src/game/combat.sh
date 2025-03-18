#!/bin/bash
#
# Système de combat pour ASCII3D-Bash-Game
#

# Statistiques du joueur
PLAYER_BASE_HEALTH=100
PLAYER_MAX_HEALTH=100
PLAYER_HEALTH=100
PLAYER_BASE_MANA=50
PLAYER_MAX_MANA=50
PLAYER_MANA=50
PLAYER_BASE_DAMAGE=5
PLAYER_DAMAGE=5
PLAYER_BASE_DEFENSE=2
PLAYER_DEFENSE=2
PLAYER_BASE_MAGIC_DAMAGE=2
PLAYER_MAGIC_DAMAGE=2
PLAYER_LEVEL=1
PLAYER_XP=0
PLAYER_NEXT_LEVEL_XP=100
PLAYER_GOLD=0

# Armes équipées et dégâts supplémentaires
PLAYER_EQUIPMENT_DAMAGE=0
PLAYER_EQUIPMENT_DEFENSE=0
PLAYER_EQUIPMENT_MAGIC_DAMAGE=0

# Types d'ennemis
ENEMY_TYPE_SKELETON=1
ENEMY_TYPE_ZOMBIE=2
ENEMY_TYPE_BAT=3
ENEMY_TYPE_SLIME=4
ENEMY_TYPE_GHOST=5
ENEMY_TYPE_BOSS=6

# Structure de données pour les ennemis
declare -A ENEMIES
declare -A ACTIVE_ENEMIES

# Compteur d'ennemis
ENEMY_COUNT=0

# État du combat
COMBAT_ACTIVE=false
COMBAT_TURN=0
CURRENT_ENEMY=""

# Temps de recharge des capacités
ABILITY_COOLDOWN_ATTACK=0
ABILITY_COOLDOWN_DEFEND=0
ABILITY_COOLDOWN_MAGIC=0
ABILITY_COOLDOWN_SPECIAL=0

# Initialiser le système de combat
function init_combat() {
    echo "Initialisation du système de combat..."
    
    # Définir les ennemis de base
    define_enemy "skeleton" "Squelette" $ENEMY_TYPE_SKELETON 25 5 2 10 20
    define_enemy "zombie" "Zombie" $ENEMY_TYPE_ZOMBIE 40 4 3 15 25
    define_enemy "bat" "Chauve-souris" $ENEMY_TYPE_BAT 15 3 1 5 10
    define_enemy "slime" "Slime" $ENEMY_TYPE_SLIME 20 2 4 8 15
    define_enemy "ghost" "Fantôme" $ENEMY_TYPE_GHOST 30 6 0 20 30
    define_enemy "boss" "Boss" $ENEMY_TYPE_BOSS 100 10 5 50 100
    
    echo "Système de combat initialisé avec ${#ENEMIES[@]} types d'ennemis."
}

# Définir un nouvel ennemi
function define_enemy() {
    local enemy_id=$1
    local enemy_name=$2
    local enemy_type=$3
    local enemy_health=$4
    local enemy_damage=$5
    local enemy_defense=$6
    local enemy_xp=$7
    local enemy_gold=$8
    
    # Stocker les données de l'ennemi
    ENEMIES["$enemy_id,name"]="$enemy_name"
    ENEMIES["$enemy_id,type"]="$enemy_type"
    ENEMIES["$enemy_id,health"]="$enemy_health"
    ENEMIES["$enemy_id,max_health"]="$enemy_health"
    ENEMIES["$enemy_id,damage"]="$enemy_damage"
    ENEMIES["$enemy_id,defense"]="$enemy_defense"
    ENEMIES["$enemy_id,xp"]="$enemy_xp"
    ENEMIES["$enemy_id,gold"]="$enemy_gold"
    
    echo "Ennemi défini: $enemy_name ($enemy_id)"
}

# Faire apparaître un ennemi
function spawn_enemy() {
    local enemy_type=$1
    local x=$2
    local y=$3
    local z=$4
    
    # Trouver un ennemi de ce type
    local enemy_id=""
    for key in "${!ENEMIES[@]}"; do
        if [[ "$key" == *",type" && "${ENEMIES[$key]}" == "$enemy_type" ]]; then
            enemy_id="${key%,type}"
            break
        fi
    done
    
    if [[ -z "$enemy_id" ]]; then
        echo "Erreur: Type d'ennemi non trouvé: $enemy_type"
        return 1
    fi
    
    # Créer une nouvelle instance de l'ennemi
    local instance_id="enemy_$((++ENEMY_COUNT))"
    
    # Copier les statistiques de base
    ACTIVE_ENEMIES["$instance_id,id"]="$enemy_id"
    ACTIVE_ENEMIES["$instance_id,name"]="${ENEMIES["$enemy_id,name"]}"
    ACTIVE_ENEMIES["$instance_id,type"]="$enemy_type"
    ACTIVE_ENEMIES["$instance_id,health"]="${ENEMIES["$enemy_id,health"]}"
    ACTIVE_ENEMIES["$instance_id,max_health"]="${ENEMIES["$enemy_id,max_health"]}"
    ACTIVE_ENEMIES["$instance_id,damage"]="${ENEMIES["$enemy_id,damage"]}"
    ACTIVE_ENEMIES["$instance_id,defense"]="${ENEMIES["$enemy_id,defense"]}"
    ACTIVE_ENEMIES["$instance_id,xp"]="${ENEMIES["$enemy_id,xp"]}"
    ACTIVE_ENEMIES["$instance_id,gold"]="${ENEMIES["$enemy_id,gold"]}"
    
    # Stocker la position
    ACTIVE_ENEMIES["$instance_id,x"]="$x"
    ACTIVE_ENEMIES["$instance_id,y"]="$y"
    ACTIVE_ENEMIES["$instance_id,z"]="$z"
    
    # Statut actif
    ACTIVE_ENEMIES["$instance_id,active"]=true
    
    echo "Ennemi ${ENEMIES["$enemy_id,name"]} apparu à la position ($x, $y, $z)."
    
    # Retourner l'ID de l'instance
    echo "$instance_id"
}

# Vérifier si un ennemi est proche du joueur
function check_enemy_proximity() {
    local player_x=$1
    local player_y=$2
    local player_z=$3
    local detection_range=${4:-3.0}  # Distance de détection par défaut
    
    # Parcourir tous les ennemis actifs
    for key in "${!ACTIVE_ENEMIES[@]}"; do
        if [[ "$key" == *",active" && "${ACTIVE_ENEMIES[$key]}" == "true" ]]; then
            local instance_id="${key%,active}"
            
            # Obtenir la position de l'ennemi
            local enemy_x=${ACTIVE_ENEMIES["$instance_id,x"]}
            local enemy_y=${ACTIVE_ENEMIES["$instance_id,y"]}
            local enemy_z=${ACTIVE_ENEMIES["$instance_id,z"]}
            
            # Calculer la distance
            local dx=$(bc -l <<< "$enemy_x - $player_x")
            local dy=$(bc -l <<< "$enemy_y - $player_y")
            local dz=$(bc -l <<< "$enemy_z - $player_z")
            local distance=$(bc -l <<< "sqrt($dx^2 + $dy^2 + $dz^2)")
            
            # Vérifier si l'ennemi est à portée
            if (( $(bc -l <<< "$distance <= $detection_range") )); then
                # Ennemi détecté
                return 0
            fi
        fi
    done
    
    # Aucun ennemi détecté
    return 1
}

# Engager le combat avec un ennemi
function engage_combat() {
    local instance_id=$1
    
    # Vérifier si l'ennemi existe et est actif
    if [[ "${ACTIVE_ENEMIES["$instance_id,active"]}" != "true" ]]; then
        echo "Erreur: Ennemi non trouvé ou inactif: $instance_id"
        return 1
    fi
    
    # Initialiser le combat
    COMBAT_ACTIVE=true
    COMBAT_TURN=1
    CURRENT_ENEMY="$instance_id"
    
    # Afficher le début du combat
    local enemy_name=${ACTIVE_ENEMIES["$instance_id,name"]}
    echo ""
    echo "=== COMBAT ENGAGÉ ==="
    echo "Vous affrontez un $enemy_name!"
    echo ""
    
    # Jouer un son
    sound_player_hit
    
    # Afficher les statistiques
    display_combat_status
    
    return 0
}

# Terminer le combat
function end_combat() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        return 1
    fi
    
    # Réinitialiser l'état du combat
    COMBAT_ACTIVE=false
    COMBAT_TURN=0
    CURRENT_ENEMY=""
    
    # Réinitialiser les temps de recharge
    ABILITY_COOLDOWN_ATTACK=0
    ABILITY_COOLDOWN_DEFEND=0
    ABILITY_COOLDOWN_MAGIC=0
    ABILITY_COOLDOWN_SPECIAL=0
    
    echo ""
    echo "=== COMBAT TERMINÉ ==="
    echo ""
    
    return 0
}

# Afficher l'état du combat
function display_combat_status() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        echo "Aucun combat en cours."
        return 1
    fi
    
    local instance_id="$CURRENT_ENEMY"
    local enemy_name=${ACTIVE_ENEMIES["$instance_id,name"]}
    local enemy_health=${ACTIVE_ENEMIES["$instance_id,health"]}
    local enemy_max_health=${ACTIVE_ENEMIES["$instance_id,max_health"]}
    
    echo "--- Tour $COMBAT_TURN ---"
    echo "Joueur: PV $PLAYER_HEALTH/$PLAYER_MAX_HEALTH, Mana $PLAYER_MANA/$PLAYER_MAX_MANA"
    echo "$enemy_name: PV $enemy_health/$enemy_max_health"
    echo ""
    
    # Afficher les temps de recharge
    if (( ABILITY_COOLDOWN_ATTACK > 0 )); then
        echo "Attaque puissante: Recharge $ABILITY_COOLDOWN_ATTACK tours"
    fi
    
    if (( ABILITY_COOLDOWN_DEFEND > 0 )); then
        echo "Défense renforcée: Recharge $ABILITY_COOLDOWN_DEFEND tours"
    fi
    
    if (( ABILITY_COOLDOWN_MAGIC > 0 )); then
        echo "Attaque magique: Recharge $ABILITY_COOLDOWN_MAGIC tours"
    fi
    
    if (( ABILITY_COOLDOWN_SPECIAL > 0 )); then
        echo "Capacité spéciale: Recharge $ABILITY_COOLDOWN_SPECIAL tours"
    fi
    
    echo ""
}

# Le joueur attaque
function player_attack() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        echo "Aucun combat en cours."
        return 1
    fi
    
    local instance_id="$CURRENT_ENEMY"
    local enemy_name=${ACTIVE_ENEMIES["$instance_id,name"]}
    local enemy_defense=${ACTIVE_ENEMIES["$instance_id,defense"]}
    
    # Calculer les dégâts
    local damage=$PLAYER_DAMAGE
    local actual_damage=$(bc <<< "scale=0; $damage - $enemy_defense / 1")
    
    # Assurer des dégâts minimums
    if (( $(bc <<< "$actual_damage < 1") )); then
        actual_damage=1
    fi
    
    # Appliquer les dégâts
    local enemy_health=${ACTIVE_ENEMIES["$instance_id,health"]}
    local new_health=$(bc <<< "scale=0; $enemy_health - $actual_damage / 1")
    
    # Mettre à jour la santé de l'ennemi
    ACTIVE_ENEMIES["$instance_id,health"]=$new_health
    
    echo "Vous attaquez le $enemy_name et infligez $actual_damage points de dégâts!"
    
    # Jouer un son
    sound_player_shoot
    
    # Vérifier si l'ennemi est vaincu
    if (( $(bc <<< "$new_health <= 0") )); then
        defeat_enemy "$instance_id"
    else
        # C'est au tour de l'ennemi
        enemy_turn
    fi
    
    return 0
}

# Attaque puissante du joueur
function player_strong_attack() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        echo "Aucun combat en cours."
        return 1
    fi
    
    # Vérifier le temps de recharge
    if (( ABILITY_COOLDOWN_ATTACK > 0 )); then
        echo "Cette capacité est en recharge pour encore $ABILITY_COOLDOWN_ATTACK tours."
        return 1
    fi
    
    local instance_id="$CURRENT_ENEMY"
    local enemy_name=${ACTIVE_ENEMIES["$instance_id,name"]}
    local enemy_defense=${ACTIVE_ENEMIES["$instance_id,defense"]}
    
    # Calculer les dégâts (2x les dégâts normaux)
    local damage=$(bc <<< "$PLAYER_DAMAGE * 2")
    local actual_damage=$(bc <<< "scale=0; $damage - $enemy_defense / 1")
    
    # Assurer des dégâts minimums
    if (( $(bc <<< "$actual_damage < 1") )); then
        actual_damage=1
    fi
    
    # Appliquer les dégâts
    local enemy_health=${ACTIVE_ENEMIES["$instance_id,health"]}
    local new_health=$(bc <<< "scale=0; $enemy_health - $actual_damage / 1")
    
    # Mettre à jour la santé de l'ennemi
    ACTIVE_ENEMIES["$instance_id,health"]=$new_health
    
    # Définir le temps de recharge
    ABILITY_COOLDOWN_ATTACK=3
    
    echo "Vous effectuez une attaque puissante sur le $enemy_name et infligez $actual_damage points de dégâts!"
    
    # Jouer un son
    sound_player_shoot
    
    # Vérifier si l'ennemi est vaincu
    if (( $(bc <<< "$new_health <= 0") )); then
        defeat_enemy "$instance_id"
    else
        # C'est au tour de l'ennemi
        enemy_turn
    fi
    
    return 0
}

# Le joueur se défend
function player_defend() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        echo "Aucun combat en cours."
        return 1
    fi
    
    # Augmenter temporairement la défense du joueur
    PLAYER_TEMP_DEFENSE=$(bc <<< "$PLAYER_DEFENSE * 2")
    
    echo "Vous vous préparez à défendre. Votre défense est temporairement augmentée!"
    
    # C'est au tour de l'ennemi
    enemy_turn
    
    # Réinitialiser la défense après le tour de l'ennemi
    PLAYER_TEMP_DEFENSE=0
    
    return 0
}

# Défense renforcée du joueur
function player_strong_defend() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        echo "Aucun combat en cours."
        return 1
    fi
    
    # Vérifier le temps de recharge
    if (( ABILITY_COOLDOWN_DEFEND > 0 )); then
        echo "Cette capacité est en recharge pour encore $ABILITY_COOLDOWN_DEFEND tours."
        return 1
    fi
    
    # Augmenter fortement la défense du joueur et récupérer des PV
    PLAYER_TEMP_DEFENSE=$(bc <<< "$PLAYER_DEFENSE * 4")
    
    # Récupérer 10% des PV
    local heal_amount=$(bc <<< "scale=0; $PLAYER_MAX_HEALTH * 0.1 / 1")
    local new_health=$(bc <<< "$PLAYER_HEALTH + $heal_amount")
    
    if (( $(bc <<< "$new_health > $PLAYER_MAX_HEALTH") )); then
        new_health=$PLAYER_MAX_HEALTH
    fi
    
    PLAYER_HEALTH=$new_health
    
    # Définir le temps de recharge
    ABILITY_COOLDOWN_DEFEND=4
    
    echo "Vous adoptez une posture de défense renforcée. Votre défense est considérablement augmentée!"
    echo "Vous récupérez $heal_amount points de vie."
    
    # C'est au tour de l'ennemi
    enemy_turn
    
    # Réinitialiser la défense après le tour de l'ennemi
    PLAYER_TEMP_DEFENSE=0
    
    return 0
}

# Le joueur utilise la magie
function player_magic() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        echo "Aucun combat en cours."
        return 1
    fi
    
    # Vérifier si le joueur a assez de mana
    local mana_cost=10
    if (( $(bc <<< "$PLAYER_MANA < $mana_cost") )); then
        echo "Vous n'avez pas assez de mana! (Coût: $mana_cost, Disponible: $PLAYER_MANA)"
        return 1
    fi
    
    local instance_id="$CURRENT_ENEMY"
    local enemy_name=${ACTIVE_ENEMIES["$instance_id,name"]}
    
    # La magie ignore la défense de l'ennemi
    local damage=$PLAYER_MAGIC_DAMAGE
    
    # Appliquer les dégâts
    local enemy_health=${ACTIVE_ENEMIES["$instance_id,health"]}
    local new_health=$(bc <<< "scale=0; $enemy_health - $damage / 1")
    
    # Mettre à jour la santé de l'ennemi
    ACTIVE_ENEMIES["$instance_id,health"]=$new_health
    
    # Consommer le mana
    PLAYER_MANA=$(bc <<< "$PLAYER_MANA - $mana_cost")
    
    echo "Vous lancez un sort sur le $enemy_name et infligez $damage points de dégâts magiques!"
    
    # Jouer un son
    sound_explosion
    
    # Vérifier si l'ennemi est vaincu
    if (( $(bc <<< "$new_health <= 0") )); then
        defeat_enemy "$instance_id"
    else
        # C'est au tour de l'ennemi
        enemy_turn
    fi
    
    return 0
}

# Le joueur utilise une attaque magique puissante
function player_strong_magic() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        echo "Aucun combat en cours."
        return 1
    fi
    
    # Vérifier le temps de recharge
    if (( ABILITY_COOLDOWN_MAGIC > 0 )); then
        echo "Cette capacité est en recharge pour encore $ABILITY_COOLDOWN_MAGIC tours."
        return 1
    fi
    
    # Vérifier si le joueur a assez de mana
    local mana_cost=20
    if (( $(bc <<< "$PLAYER_MANA < $mana_cost") )); then
        echo "Vous n'avez pas assez de mana! (Coût: $mana_cost, Disponible: $PLAYER_MANA)"
        return 1
    fi
    
    local instance_id="$CURRENT_ENEMY"
    local enemy_name=${ACTIVE_ENEMIES["$instance_id,name"]}
    
    # La magie puissante fait trois fois plus de dégâts et ignore la défense
    local damage=$(bc <<< "$PLAYER_MAGIC_DAMAGE * 3")
    
    # Appliquer les dégâts
    local enemy_health=${ACTIVE_ENEMIES["$instance_id,health"]}
    local new_health=$(bc <<< "scale=0; $enemy_health - $damage / 1")
    
    # Mettre à jour la santé de l'ennemi
    ACTIVE_ENEMIES["$instance_id,health"]=$new_health
    
    # Consommer le mana
    PLAYER_MANA=$(bc <<< "$PLAYER_MANA - $mana_cost")
    
    # Définir le temps de recharge
    ABILITY_COOLDOWN_MAGIC=3
    
    echo "Vous concentrez votre énergie magique et lancez un puissant sort sur le $enemy_name!"
    echo "Le sort inflige $damage points de dégâts magiques!"
    
    # Jouer un son
    sound_explosion
    
    # Vérifier si l'ennemi est vaincu
    if (( $(bc <<< "$new_health <= 0") )); then
        defeat_enemy "$instance_id"
    else
        # C'est au tour de l'ennemi
        enemy_turn
    fi
    
    return 0
}

# Le joueur utilise une capacité spéciale
function player_special() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        echo "Aucun combat en cours."
        return 1
    fi
    
    # Vérifier le temps de recharge
    if (( ABILITY_COOLDOWN_SPECIAL > 0 )); then
        echo "Cette capacité est en recharge pour encore $ABILITY_COOLDOWN_SPECIAL tours."
        return 1
    fi
    
    # Vérifier si le joueur a assez de mana
    local mana_cost=30
    if (( $(bc <<< "$PLAYER_MANA < $mana_cost") )); then
        echo "Vous n'avez pas assez de mana! (Coût: $mana_cost, Disponible: $PLAYER_MANA)"
        return 1
    fi
    
    local instance_id="$CURRENT_ENEMY"
    local enemy_name=${ACTIVE_ENEMIES["$instance_id,name"]}
    
    # La capacité spéciale fait des dégâts basés sur les PV max de l'ennemi
    local enemy_max_health=${ACTIVE_ENEMIES["$instance_id,max_health"]}
    local damage=$(bc <<< "scale=0; $enemy_max_health * 0.3 / 1")  # 30% des PV max
    
    # Appliquer les dégâts
    local enemy_health=${ACTIVE_ENEMIES["$instance_id,health"]}
    local new_health=$(bc <<< "scale=0; $enemy_health - $damage / 1")
    
    # Mettre à jour la santé de l'ennemi
    ACTIVE_ENEMIES["$instance_id,health"]=$new_health
    
    # Consommer le mana
    PLAYER_MANA=$(bc <<< "$PLAYER_MANA - $mana_cost")
    
    # Définir le temps de recharge
    ABILITY_COOLDOWN_SPECIAL=5
    
    echo "Vous libérez votre puissance spéciale contre le $enemy_name!"
    echo "Votre attaque inflige $damage points de dégâts!"
    
    # Jouer un son
    sound_explosion
    
    # Vérifier si l'ennemi est vaincu
    if (( $(bc <<< "$new_health <= 0") )); then
        defeat_enemy "$instance_id"
    else
        # C'est au tour de l'ennemi
        enemy_turn
    fi
    
    return 0
}

# Le joueur utilise un objet
function player_use_item() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        echo "Aucun combat en cours."
        return 1
    fi
    
    # Afficher l'inventaire et demander quel objet utiliser
    display_inventory
    
    echo ""
    echo "Entrez l'ID de l'objet à utiliser (ou 'annuler'):"
    read -r item_id
    
    if [[ "$item_id" == "annuler" ]]; then
        echo "Action annulée."
        return 1
    fi
    
    # Utiliser l'objet
    if use_item "$item_id"; then
        # C'est au tour de l'ennemi
        enemy_turn
        return 0
    else
        echo "Impossible d'utiliser cet objet."
        return 1
    fi
}

# Le joueur fuit le combat
function player_flee() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        echo "Aucun combat en cours."
        return 1
    fi
    
    # Chance de fuite (50%)
    local flee_chance=50
    local roll=$((RANDOM % 100 + 1))
    
    if (( roll <= flee_chance )); then
        echo "Vous fuyez le combat avec succès!"
        end_combat
        return 0
    else
        echo "Vous ne parvenez pas à fuir!"
        
        # C'est au tour de l'ennemi
        enemy_turn
        return 1
    fi
}

# Tour de l'ennemi
function enemy_turn() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        return 1
    fi
    
    local instance_id="$CURRENT_ENEMY"
    local enemy_name=${ACTIVE_ENEMIES["$instance_id,name"]}
    local enemy_damage=${ACTIVE_ENEMIES["$instance_id,damage"]}
    
    # Déterminer la défense du joueur (normale ou temporaire)
    local player_def=$PLAYER_DEFENSE
    if [[ -n "$PLAYER_TEMP_DEFENSE" && "$PLAYER_TEMP_DEFENSE" -gt 0 ]]; then
        player_def=$PLAYER_TEMP_DEFENSE
    fi
    
    # Calculer les dégâts
    local actual_damage=$(bc <<< "scale=0; $enemy_damage - $player_def / 1")
    
    # Assurer des dégâts minimums
    if (( $(bc <<< "$actual_damage < 1") )); then
        actual_damage=1
    fi
    
    # Appliquer les dégâts
    PLAYER_HEALTH=$(bc <<< "scale=0; $PLAYER_HEALTH - $actual_damage / 1")
    
    echo "Le $enemy_name vous attaque et inflige $actual_damage points de dégâts!"
    
    # Jouer un son
    sound_player_hit
    
    # Vérifier si le joueur est vaincu
    if (( $(bc <<< "$PLAYER_HEALTH <= 0") )); then
        player_defeated
    else
        # Incrémenter le tour
        ((COMBAT_TURN++))
        
        # Réduire les temps de recharge
        if (( ABILITY_COOLDOWN_ATTACK > 0 )); then
            ((ABILITY_COOLDOWN_ATTACK--))
        fi
        
        if (( ABILITY_COOLDOWN_DEFEND > 0 )); then
            ((ABILITY_COOLDOWN_DEFEND--))
        fi
        
        if (( ABILITY_COOLDOWN_MAGIC > 0 )); then
            ((ABILITY_COOLDOWN_MAGIC--))
        fi
        
        if (( ABILITY_COOLDOWN_SPECIAL > 0 )); then
            ((ABILITY_COOLDOWN_SPECIAL--))
        fi
        
        # Régénérer un peu de mana
        local mana_regen=2
        PLAYER_MANA=$(bc <<< "$PLAYER_MANA + $mana_regen")
        if (( $(bc <<< "$PLAYER_MANA > $PLAYER_MAX_MANA") )); then
            PLAYER_MANA=$PLAYER_MAX_MANA
        fi
        
        # Afficher l'état du combat
        display_combat_status
    fi
    
    return 0
}

# L'ennemi est vaincu
function defeat_enemy() {
    local instance_id=$1
    
    # Vérifier si l'ennemi existe et est actif
    if [[ "${ACTIVE_ENEMIES["$instance_id,active"]}" != "true" ]]; then
        return 1
    fi
    
    local enemy_name=${ACTIVE_ENEMIES["$instance_id,name"]}
    local enemy_xp=${ACTIVE_ENEMIES["$instance_id,xp"]}
    local enemy_gold=${ACTIVE_ENEMIES["$instance_id,gold"]}
    
    # Marquer l'ennemi comme inactif
    ACTIVE_ENEMIES["$instance_id,active"]=false
    
    # Donner de l'XP et de l'or au joueur
    PLAYER_XP=$(bc <<< "$PLAYER_XP + $enemy_xp")
    PLAYER_GOLD=$(bc <<< "$PLAYER_GOLD + $enemy_gold")
    
    echo "Vous avez vaincu le $enemy_name!"
    echo "Vous gagnez $enemy_xp points d'expérience et $enemy_gold pièces d'or."
    
    # Vérifier si le joueur monte de niveau
    check_level_up
    
    # Chance de loot (30%)
    local loot_chance=30
    local roll=$((RANDOM % 100 + 1))
    
    if (( roll <= loot_chance )); then
        # Déterminer le type d'objet à donner
        local enemy_type=${ACTIVE_ENEMIES["$instance_id,type"]}
        local loot_item=""
        
        case "$enemy_type" in
            $ENEMY_TYPE_SKELETON)
                loot_item="rusty_sword"
                ;;
            $ENEMY_TYPE_ZOMBIE)
                loot_item="health_potion"
                ;;
            $ENEMY_TYPE_BAT)
                loot_item="mana_potion"
                ;;
            $ENEMY_TYPE_SLIME)
                loot_item="iron_ore"
                ;;
            $ENEMY_TYPE_GHOST)
                loot_item="magic_scroll"
                ;;
            $ENEMY_TYPE_BOSS)
                loot_item="magic_sword"
                ;;
        esac
        
        if [[ -n "$loot_item" ]]; then
            add_to_inventory "$loot_item" 1
            echo "Le $enemy_name a laissé tomber: ${ITEMS["$loot_item,name"]}!"
        fi
    fi
    
    # Mettre à jour les quêtes (si nécessaire)
    case "$enemy_type" in
        $ENEMY_TYPE_SKELETON)
            update_objective_progress "tutorial" "kill_skeletons" 1
            ;;
        $ENEMY_TYPE_BAT)
            update_objective_progress "explore_cave" "kill_bats" 1
            ;;
        *)
            update_objective_progress "defend_village" "kill_monsters" 1
            ;;
    esac
    
    # Terminer le combat
    end_combat
    
    # Jouer un son
    sound_level_complete
    
    return 0
}

# Le joueur est vaincu
function player_defeated() {
    echo "Vous avez été vaincu!"
    
    # Pénalité: perte d'or
    local gold_loss=$(bc <<< "scale=0; $PLAYER_GOLD * 0.1 / 1")  # 10% de l'or
    PLAYER_GOLD=$(bc <<< "$PLAYER_GOLD - $gold_loss")
    
    if (( $(bc <<< "$PLAYER_GOLD < 0") )); then
        PLAYER_GOLD=0
    fi
    
    echo "Vous perdez $gold_loss pièces d'or."
    
    # Ramener le joueur à la moitié de sa santé
    PLAYER_HEALTH=$(bc <<< "scale=0; $PLAYER_MAX_HEALTH / 2 / 1")
    
    # Terminer le combat
    end_combat
    
    # Jouer un son
    sound_game_over
    
    return 0
}

# Vérifier si le joueur monte de niveau
function check_level_up() {
    while (( $(bc <<< "$PLAYER_XP >= $PLAYER_NEXT_LEVEL_XP") )); do
        # Monter de niveau
        ((PLAYER_LEVEL++))
        
        # Calculer l'XP pour le prochain niveau
        PLAYER_NEXT_LEVEL_XP=$(bc <<< "scale=0; $PLAYER_NEXT_LEVEL_XP * 1.5 / 1")
        
        # Augmenter les statistiques
        PLAYER_BASE_HEALTH=$(bc <<< "scale=0; $PLAYER_BASE_HEALTH * 1.1 / 1")
        PLAYER_MAX_HEALTH=$PLAYER_BASE_HEALTH
        PLAYER_HEALTH=$PLAYER_MAX_HEALTH
        
        PLAYER_BASE_MANA=$(bc <<< "scale=0; $PLAYER_BASE_MANA * 1.1 / 1")
        PLAYER_MAX_MANA=$PLAYER_BASE_MANA
        PLAYER_MANA=$PLAYER_MAX_MANA
        
        PLAYER_BASE_DAMAGE=$(bc <<< "scale=0; $PLAYER_BASE_DAMAGE + 1 / 1")
        PLAYER_DAMAGE=$(bc <<< "$PLAYER_BASE_DAMAGE + $PLAYER_EQUIPMENT_DAMAGE")
        
        PLAYER_BASE_DEFENSE=$(bc <<< "scale=0; $PLAYER_BASE_DEFENSE + 1 / 1")
        PLAYER_DEFENSE=$(bc <<< "$PLAYER_BASE_DEFENSE + $PLAYER_EQUIPMENT_DEFENSE")
        
        PLAYER_BASE_MAGIC_DAMAGE=$(bc <<< "scale=0; $PLAYER_BASE_MAGIC_DAMAGE + 1 / 1")
        PLAYER_MAGIC_DAMAGE=$(bc <<< "$PLAYER_BASE_MAGIC_DAMAGE + $PLAYER_EQUIPMENT_MAGIC_DAMAGE")
        
        echo ""
        echo "===== NIVEAU SUPÉRIEUR! ====="
        echo "Vous atteignez le niveau $PLAYER_LEVEL!"
        echo "Vos statistiques augmentent:"
        echo "PV: $PLAYER_MAX_HEALTH"
        echo "Mana: $PLAYER_MAX_MANA"
        echo "Dégâts: $PLAYER_DAMAGE"
        echo "Défense: $PLAYER_DEFENSE"
        echo "Dégâts magiques: $PLAYER_MAGIC_DAMAGE"
        echo "==============================="
        echo ""
        
        # Jouer un son
        sound_level_complete
    done
}

# Afficher les statistiques du joueur
function display_player_stats() {
    echo "=== Statistiques du Joueur ==="
    echo "Niveau: $PLAYER_LEVEL"
    echo "Expérience: $PLAYER_XP / $PLAYER_NEXT_LEVEL_XP"
    echo "Points de vie: $PLAYER_HEALTH / $PLAYER_MAX_HEALTH"
    echo "Mana: $PLAYER_MANA / $PLAYER_MAX_MANA"
    echo "Dégâts: $PLAYER_DAMAGE"
    echo "Défense: $PLAYER_DEFENSE"
    echo "Dégâts magiques: $PLAYER_MAGIC_DAMAGE"
    echo "Or: $PLAYER_GOLD"
}

# Menu de combat
function combat_menu() {
    # Vérifier si un combat est actif
    if ! $COMBAT_ACTIVE; then
        echo "Aucun combat en cours."
        return 1
    fi
    
    local choice
    
    echo "Actions disponibles:"
    echo "1. Attaque normale"
    echo "2. Attaque puissante"
    echo "3. Défense"
    echo "4. Défense renforcée"
    echo "5. Magie"
    echo "6. Magie puissante"
    echo "7. Capacité spéciale"
    echo "8. Utiliser un objet"
    echo "9. Fuir"
    echo ""
    echo "Votre choix (1-9):"
    read -r choice
    
    case "$choice" in
        1) player_attack ;;
        2) player_strong_attack ;;
        3) player_defend ;;
        4) player_strong_defend ;;
        5) player_magic ;;
        6) player_strong_magic ;;
        7) player_special ;;
        8) player_use_item ;;
        9) player_flee ;;
        *) echo "Choix invalide. Veuillez réessayer." ;;
    esac
}

# Initialiser le système de combat
init_combat
