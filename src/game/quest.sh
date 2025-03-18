#!/bin/bash
#
# Système de quêtes et d'objectifs pour ASCII3D-Bash-Game
#

# Structure de données pour les quêtes
declare -A QUESTS
declare -A QUEST_OBJECTIVES
declare -A QUEST_REWARDS
declare -A QUEST_DEPENDENCIES
declare -A QUEST_DIALOGS

# États des quêtes
QUEST_STATE_UNAVAILABLE=0
QUEST_STATE_AVAILABLE=1
QUEST_STATE_ACTIVE=2
QUEST_STATE_COMPLETED=3
QUEST_STATE_FAILED=4

# Types d'objectifs
OBJECTIVE_TYPE_COLLECT=1     # Collecter des objets
OBJECTIVE_TYPE_KILL=2        # Éliminer des ennemis
OBJECTIVE_TYPE_REACH=3       # Atteindre un lieu
OBJECTIVE_TYPE_INTERACT=4    # Interagir avec un objet/personnage
OBJECTIVE_TYPE_ESCORT=5      # Escorter un personnage
OBJECTIVE_TYPE_SURVIVE=6     # Survivre pendant un temps donné

# Initialiser le système de quêtes
function init_quests() {
    echo "Initialisation du système de quêtes..."
    
    # Définir quelques quêtes de base
    define_quest "tutorial" "Tutoriel" "Apprenez les bases du jeu" 10 $QUEST_STATE_AVAILABLE
    add_quest_objective "tutorial" $OBJECTIVE_TYPE_REACH "reach_waypoint1" "Atteignez le premier point de passage" 1
    add_quest_objective "tutorial" $OBJECTIVE_TYPE_INTERACT "interact_lever" "Activez le levier" 1
    add_quest_objective "tutorial" $OBJECTIVE_TYPE_COLLECT "collect_key" "Trouvez la clé" 1
    add_quest_reward "tutorial" "xp" 50
    add_quest_reward "tutorial" "item" "health_potion" 2
    add_quest_dialog "tutorial" "start" "Bienvenue dans le monde ASCII 3D ! Suivez les instructions pour apprendre à jouer."
    add_quest_dialog "tutorial" "complete" "Félicitations ! Vous avez terminé le tutoriel et vous êtes prêt à explorer le monde."
    
    define_quest "explore_cave" "Explorer la caverne" "Explorez la caverne mystérieuse et découvrez ses secrets" 20 $QUEST_STATE_UNAVAILABLE
    add_quest_dependency "explore_cave" "tutorial" $QUEST_STATE_COMPLETED
    add_quest_objective "explore_cave" $OBJECTIVE_TYPE_REACH "reach_cave" "Trouver l'entrée de la caverne" 1
    add_quest_objective "explore_cave" $OBJECTIVE_TYPE_KILL "kill_bats" "Éliminer les chauves-souris" 5
    add_quest_objective "explore_cave" $OBJECTIVE_TYPE_COLLECT "collect_gem" "Récupérer la gemme ancienne" 1
    add_quest_reward "explore_cave" "xp" 100
    add_quest_reward "explore_cave" "item" "magic_scroll" 1
    add_quest_reward "explore_cave" "gold" 50
    add_quest_dialog "explore_cave" "start" "Une caverne mystérieuse a été découverte à l'est. Explorez-la et rapportez tout artefact intéressant que vous pourriez trouver."
    add_quest_dialog "explore_cave" "complete" "Excellent travail ! Cette gemme semble posséder des pouvoirs mystérieux. Nous devons l'étudier davantage."
    
    define_quest "defend_village" "Défendre le village" "Protégez le village contre l'attaque des monstres" 30 $QUEST_STATE_UNAVAILABLE
    add_quest_dependency "defend_village" "explore_cave" $QUEST_STATE_COMPLETED
    add_quest_objective "defend_village" $OBJECTIVE_TYPE_KILL "kill_monsters" "Éliminer les monstres" 10
    add_quest_objective "defend_village" $OBJECTIVE_TYPE_SURVIVE "survive_waves" "Survivre aux vagues d'attaques" 3
    add_quest_objective "defend_village" $OBJECTIVE_TYPE_INTERACT "activate_barrier" "Activer la barrière magique" 1
    add_quest_reward "defend_village" "xp" 200
    add_quest_reward "defend_village" "item" "magic_sword" 1
    add_quest_reward "defend_village" "gold" 100
    add_quest_dialog "defend_village" "start" "Le village est en danger ! Des monstres approchent et nous avons besoin de votre aide pour les repousser."
    add_quest_dialog "defend_village" "complete" "Grâce à vous, le village est sauvé ! Veuillez accepter cette épée magique en témoignage de notre gratitude."
    
    echo "Système de quêtes initialisé avec ${#QUESTS[@]} quêtes."
}

# Définir une nouvelle quête
function define_quest() {
    local quest_id=$1
    local quest_name=$2
    local quest_description=$3
    local quest_xp=$4
    local quest_state=$5
    
    # Stocker les données de la quête
    QUESTS["$quest_id,name"]="$quest_name"
    QUESTS["$quest_id,description"]="$quest_description"
    QUESTS["$quest_id,xp"]="$quest_xp"
    QUESTS["$quest_id,state"]="$quest_state"
    QUESTS["$quest_id,progress"]=0
    QUESTS["$quest_id,objective_count"]=0
    
    # Initialiser la liste des objectifs
    QUEST_OBJECTIVES["$quest_id"]=""
    
    # Initialiser la liste des récompenses
    QUEST_REWARDS["$quest_id"]=""
    
    # Initialiser la liste des dépendances
    QUEST_DEPENDENCIES["$quest_id"]=""
    
    # Initialiser la liste des dialogues
    QUEST_DIALOGS["$quest_id"]=""
    
    echo "Quête '$quest_name' ($quest_id) définie."
}

# Ajouter un objectif à une quête
function add_quest_objective() {
    local quest_id=$1
    local objective_type=$2
    local objective_id=$3
    local objective_description=$4
    local objective_target=$5
    
    # Vérifier si la quête existe
    if [[ -z "${QUESTS["$quest_id,name"]}" ]]; then
        echo "Erreur: Quête non trouvée: $quest_id"
        return 1
    fi
    
    # Incrémenter le compteur d'objectifs
    local obj_count=${QUESTS["$quest_id,objective_count"]}
    ((obj_count++))
    QUESTS["$quest_id,objective_count"]=$obj_count
    
    # Stocker les données de l'objectif
    QUEST_OBJECTIVES["$quest_id,$obj_count,type"]="$objective_type"
    QUEST_OBJECTIVES["$quest_id,$obj_count,id"]="$objective_id"
    QUEST_OBJECTIVES["$quest_id,$obj_count,description"]="$objective_description"
    QUEST_OBJECTIVES["$quest_id,$obj_count,target"]="$objective_target"
    QUEST_OBJECTIVES["$quest_id,$obj_count,progress"]=0
    QUEST_OBJECTIVES["$quest_id,$obj_count,completed"]=false
    
    echo "Objectif '$objective_description' ajouté à la quête '$quest_id'."
}

# Ajouter une récompense à une quête
function add_quest_reward() {
    local quest_id=$1
    local reward_type=$2
    local reward_id=$3
    local reward_amount=${4:-1}
    
    # Vérifier si la quête existe
    if [[ -z "${QUESTS["$quest_id,name"]}" ]]; then
        echo "Erreur: Quête non trouvée: $quest_id"
        return 1
    fi
    
    # Stocker les données de la récompense
    local reward_count=0
    if [[ -n "${QUEST_REWARDS["$quest_id,count"]}" ]]; then
        reward_count=${QUEST_REWARDS["$quest_id,count"]}
    fi
    
    ((reward_count++))
    QUEST_REWARDS["$quest_id,count"]=$reward_count
    
    QUEST_REWARDS["$quest_id,$reward_count,type"]="$reward_type"
    QUEST_REWARDS["$quest_id,$reward_count,id"]="$reward_id"
    QUEST_REWARDS["$quest_id,$reward_count,amount"]="$reward_amount"
    
    echo "Récompense ajoutée à la quête '$quest_id': $reward_type $reward_id x$reward_amount."
}

# Ajouter une dépendance à une quête
function add_quest_dependency() {
    local quest_id=$1
    local dependency_quest_id=$2
    local required_state=$3
    
    # Vérifier si la quête existe
    if [[ -z "${QUESTS["$quest_id,name"]}" ]]; then
        echo "Erreur: Quête non trouvée: $quest_id"
        return 1
    fi
    
    # Vérifier si la quête dépendante existe
    if [[ -z "${QUESTS["$dependency_quest_id,name"]}" ]]; then
        echo "Erreur: Quête dépendante non trouvée: $dependency_quest_id"
        return 1
    fi
    
    # Stocker les données de la dépendance
    local dep_count=0
    if [[ -n "${QUEST_DEPENDENCIES["$quest_id,count"]}" ]]; then
        dep_count=${QUEST_DEPENDENCIES["$quest_id,count"]}
    fi
    
    ((dep_count++))
    QUEST_DEPENDENCIES["$quest_id,count"]=$dep_count
    
    QUEST_DEPENDENCIES["$quest_id,$dep_count,quest"]="$dependency_quest_id"
    QUEST_DEPENDENCIES["$quest_id,$dep_count,state"]="$required_state"
    
    echo "Dépendance ajoutée à la quête '$quest_id': $dependency_quest_id (état $required_state)."
}

# Ajouter un dialogue à une quête
function add_quest_dialog() {
    local quest_id=$1
    local dialog_type=$2  # start, progress, complete, fail, etc.
    local dialog_text=$3
    
    # Vérifier si la quête existe
    if [[ -z "${QUESTS["$quest_id,name"]}" ]]; then
        echo "Erreur: Quête non trouvée: $quest_id"
        return 1
    fi
    
    # Stocker le dialogue
    QUEST_DIALOGS["$quest_id,$dialog_type"]="$dialog_text"
    
    echo "Dialogue de type '$dialog_type' ajouté à la quête '$quest_id'."
}

# Vérifier si une quête est disponible
function is_quest_available() {
    local quest_id=$1
    
    # Vérifier si la quête existe
    if [[ -z "${QUESTS["$quest_id,name"]}" ]]; then
        return 1
    fi
    
    # Vérifier l'état actuel
    local current_state=${QUESTS["$quest_id,state"]}
    if [[ "$current_state" != "$QUEST_STATE_AVAILABLE" ]]; then
        return 1
    fi
    
    # Vérifier les dépendances
    local dep_count=${QUEST_DEPENDENCIES["$quest_id,count"]}
    if [[ -n "$dep_count" && "$dep_count" -gt 0 ]]; then
        for ((i=1; i<=dep_count; i++)); do
            local dep_quest=${QUEST_DEPENDENCIES["$quest_id,$i,quest"]}
            local req_state=${QUEST_DEPENDENCIES["$quest_id,$i,state"]}
            
            local dep_current_state=${QUESTS["$dep_quest,state"]}
            
            if [[ "$dep_current_state" != "$req_state" ]]; then
                return 1
            fi
        done
    fi
    
    return 0
}

# Accepter une quête
function accept_quest() {
    local quest_id=$1
    
    # Vérifier si la quête est disponible
    if is_quest_available "$quest_id"; then
        # Mettre à jour l'état
        QUESTS["$quest_id,state"]=$QUEST_STATE_ACTIVE
        
        # Afficher le dialogue de début
        local start_dialog=${QUEST_DIALOGS["$quest_id,start"]}
        if [[ -n "$start_dialog" ]]; then
            echo "$start_dialog"
        fi
        
        echo "Quête acceptée: ${QUESTS["$quest_id,name"]}"
        return 0
    else
        echo "Erreur: La quête n'est pas disponible."
        return 1
    fi
}

# Mettre à jour la progression d'un objectif
function update_objective_progress() {
    local quest_id=$1
    local objective_id=$2
    local progress_amount=${3:-1}
    
    # Vérifier si la quête est active
    if [[ "${QUESTS["$quest_id,state"]}" != "$QUEST_STATE_ACTIVE" ]]; then
        return 1
    fi
    
    # Trouver l'objectif
    local found=false
    local obj_count=${QUESTS["$quest_id,objective_count"]}
    
    for ((i=1; i<=obj_count; i++)); do
        if [[ "${QUEST_OBJECTIVES["$quest_id,$i,id"]}" == "$objective_id" ]]; then
            # Vérifier si l'objectif est déjà complété
            if [[ "${QUEST_OBJECTIVES["$quest_id,$i,completed"]}" == "true" ]]; then
                return 0
            fi
            
            # Mettre à jour la progression
            local current_progress=${QUEST_OBJECTIVES["$quest_id,$i,progress"]}
            local target=${QUEST_OBJECTIVES["$quest_id,$i,target"]}
            
            current_progress=$(bc <<< "$current_progress + $progress_amount")
            QUEST_OBJECTIVES["$quest_id,$i,progress"]=$current_progress
            
            # Vérifier si l'objectif est complété
            if (( $(bc <<< "$current_progress >= $target") )); then
                QUEST_OBJECTIVES["$quest_id,$i,completed"]=true
                echo "Objectif complété: ${QUEST_OBJECTIVES["$quest_id,$i,description"]}"
                
                # Vérifier si tous les objectifs sont complétés
                check_quest_completion "$quest_id"
            else
                echo "Progression de l'objectif: ${QUEST_OBJECTIVES["$quest_id,$i,description"]} ($current_progress/$target)"
            fi
            
            found=true
            break
        fi
    done
    
    if ! $found; then
        echo "Erreur: Objectif non trouvé: $objective_id"
        return 1
    fi
    
    return 0
}

# Vérifier si une quête est complétée
function check_quest_completion() {
    local quest_id=$1
    
    # Vérifier si la quête est active
    if [[ "${QUESTS["$quest_id,state"]}" != "$QUEST_STATE_ACTIVE" ]]; then
        return 1
    fi
    
    # Vérifier tous les objectifs
    local all_completed=true
    local obj_count=${QUESTS["$quest_id,objective_count"]}
    
    for ((i=1; i<=obj_count; i++)); do
        if [[ "${QUEST_OBJECTIVES["$quest_id,$i,completed"]}" != "true" ]]; then
            all_completed=false
            break
        fi
    done
    
    # Si tous les objectifs sont complétés, marquer la quête comme terminée
    if $all_completed; then
        complete_quest "$quest_id"
        return 0
    fi
    
    return 1
}

# Compléter une quête
function complete_quest() {
    local quest_id=$1
    
    # Mettre à jour l'état
    QUESTS["$quest_id,state"]=$QUEST_STATE_COMPLETED
    
    # Attribuer les récompenses
    local reward_count=${QUEST_REWARDS["$quest_id,count"]}
    
    if [[ -n "$reward_count" && "$reward_count" -gt 0 ]]; then
        echo "Récompenses obtenues:"
        
        for ((i=1; i<=reward_count; i++)); do
            local reward_type=${QUEST_REWARDS["$quest_id,$i,type"]}
            local reward_id=${QUEST_REWARDS["$quest_id,$i,id"]}
            local reward_amount=${QUEST_REWARDS["$quest_id,$i,amount"]}
            
            case "$reward_type" in
                "xp")
                    # Ajouter de l'expérience
                    PLAYER_XP=$(bc <<< "$PLAYER_XP + $reward_id")
                    echo "- $reward_id points d'expérience"
                    ;;
                "item")
                    # Ajouter un objet à l'inventaire
                    add_to_inventory "$reward_id" "$reward_amount"
                    echo "- $reward_amount x $reward_id"
                    ;;
                "gold")
                    # Ajouter de l'or
                    PLAYER_GOLD=$(bc <<< "$PLAYER_GOLD + $reward_id")
                    echo "- $reward_id pièces d'or"
                    ;;
                *)
                    echo "- Récompense inconnue: $reward_type"
                    ;;
            esac
        done
    fi
    
    # Afficher le dialogue de fin
    local complete_dialog=${QUEST_DIALOGS["$quest_id,complete"]}
    if [[ -n "$complete_dialog" ]]; then
        echo "$complete_dialog"
    fi
    
    # Jouer un son de complétion
    sound_level_complete
    
    # Mettre à jour les quêtes dépendantes
    update_dependent_quests "$quest_id"
    
    echo "Quête terminée: ${QUESTS["$quest_id,name"]}"
    return 0
}

# Échouer une quête
function fail_quest() {
    local quest_id=$1
    
    # Mettre à jour l'état
    QUESTS["$quest_id,state"]=$QUEST_STATE_FAILED
    
    # Afficher le dialogue d'échec
    local fail_dialog=${QUEST_DIALOGS["$quest_id,fail"]}
    if [[ -n "$fail_dialog" ]]; then
        echo "$fail_dialog"
    fi
    
    echo "Quête échouée: ${QUESTS["$quest_id,name"]}"
    return 0
}

# Mettre à jour les quêtes dépendantes
function update_dependent_quests() {
    local completed_quest_id=$1
    
    # Parcourir toutes les quêtes
    for quest_id in $(get_all_quests); do
        # Vérifier si la quête a une dépendance sur la quête complétée
        local dep_count=${QUEST_DEPENDENCIES["$quest_id,count"]}
        
        if [[ -n "$dep_count" && "$dep_count" -gt 0 ]]; then
            for ((i=1; i<=dep_count; i++)); do
                local dep_quest=${QUEST_DEPENDENCIES["$quest_id,$i,quest"]}
                local req_state=${QUEST_DEPENDENCIES["$quest_id,$i,state"]}
                
                if [[ "$dep_quest" == "$completed_quest_id" && "$req_state" == "$QUEST_STATE_COMPLETED" ]]; then
                    # Mettre à jour l'état si la quête est indisponible
                    if [[ "${QUESTS["$quest_id,state"]}" == "$QUEST_STATE_UNAVAILABLE" ]]; then
                        QUESTS["$quest_id,state"]=$QUEST_STATE_AVAILABLE
                        echo "Nouvelle quête disponible: ${QUESTS["$quest_id,name"]}"
                    fi
                fi
            done
        fi
    done
}

# Obtenir toutes les quêtes
function get_all_quests() {
    local quests=()
    
    # Parcourir toutes les quêtes
    for key in "${!QUESTS[@]}"; do
        # Extraire les IDs de quête (uniquement les clés de type "quest_id,name")
        if [[ "$key" == *",name" ]]; then
            local quest_id="${key%,name}"
            quests+=("$quest_id")
        fi
    done
    
    # Retourner la liste des quêtes
    echo "${quests[@]}"
}

# Obtenir toutes les quêtes actives
function get_active_quests() {
    local active_quests=()
    
    # Parcourir toutes les quêtes
    for quest_id in $(get_all_quests); do
        if [[ "${QUESTS["$quest_id,state"]}" == "$QUEST_STATE_ACTIVE" ]]; then
            active_quests+=("$quest_id")
        fi
    done
    
    # Retourner la liste des quêtes actives
    echo "${active_quests[@]}"
}

# Obtenir toutes les quêtes disponibles
function get_available_quests() {
    local available_quests=()
    
    # Parcourir toutes les quêtes
    for quest_id in $(get_all_quests); do
        if [[ "${QUESTS["$quest_id,state"]}" == "$QUEST_STATE_AVAILABLE" ]]; then
            available_quests+=("$quest_id")
        fi
    done
    
    # Retourner la liste des quêtes disponibles
    echo "${available_quests[@]}"
}

# Obtenir toutes les quêtes terminées
function get_completed_quests() {
    local completed_quests=()
    
    # Parcourir toutes les quêtes
    for quest_id in $(get_all_quests); do
        if [[ "${QUESTS["$quest_id,state"]}" == "$QUEST_STATE_COMPLETED" ]]; then
            completed_quests+=("$quest_id")
        fi
    done
    
    # Retourner la liste des quêtes terminées
    echo "${completed_quests[@]}"
}

# Afficher les informations d'une quête
function display_quest_info() {
    local quest_id=$1
    
    # Vérifier si la quête existe
    if [[ -z "${QUESTS["$quest_id,name"]}" ]]; then
        echo "Erreur: Quête non trouvée: $quest_id"
        return 1
    fi
    
    local quest_name=${QUESTS["$quest_id,name"]}
    local quest_desc=${QUESTS["$quest_id,description"]}
    local quest_xp=${QUESTS["$quest_id,xp"]}
    local quest_state=${QUESTS["$quest_id,state"]}
    
    # Convertir l'état en texte
    local state_text=""
    case "$quest_state" in
        $QUEST_STATE_UNAVAILABLE) state_text="Non disponible" ;;
        $QUEST_STATE_AVAILABLE) state_text="Disponible" ;;
        $QUEST_STATE_ACTIVE) state_text="En cours" ;;
        $QUEST_STATE_COMPLETED) state_text="Terminée" ;;
        $QUEST_STATE_FAILED) state_text="Échouée" ;;
        *) state_text="Inconnu" ;;
    esac
    
    echo "=== Quête: $quest_name ==="
    echo "Description: $quest_desc"
    echo "État: $state_text"
    echo "Récompense XP: $quest_xp"
    
    # Afficher les objectifs
    local obj_count=${QUESTS["$quest_id,objective_count"]}
    if [[ -n "$obj_count" && "$obj_count" -gt 0 ]]; then
        echo "Objectifs:"
        
        for ((i=1; i<=obj_count; i++)); do
            local obj_desc=${QUEST_OBJECTIVES["$quest_id,$i,description"]}
            local obj_progress=${QUEST_OBJECTIVES["$quest_id,$i,progress"]}
            local obj_target=${QUEST_OBJECTIVES["$quest_id,$i,target"]}
            local obj_completed=${QUEST_OBJECTIVES["$quest_id,$i,completed"]}
            
            local progress_text=""
            if [[ "$obj_completed" == "true" ]]; then
                progress_text="(Complété)"
            else
                progress_text="($obj_progress/$obj_target)"
            fi
            
            echo "- $obj_desc $progress_text"
        done
    fi
    
    # Afficher les récompenses
    local reward_count=${QUEST_REWARDS["$quest_id,count"]}
    if [[ -n "$reward_count" && "$reward_count" -gt 0 ]]; then
        echo "Récompenses:"
        
        for ((i=1; i<=reward_count; i++)); do
            local reward_type=${QUEST_REWARDS["$quest_id,$i,type"]}
            local reward_id=${QUEST_REWARDS["$quest_id,$i,id"]}
            local reward_amount=${QUEST_REWARDS["$quest_id,$i,amount"]}
            
            case "$reward_type" in
                "xp") echo "- $reward_id points d'expérience" ;;
                "item") echo "- $reward_amount x $reward_id" ;;
                "gold") echo "- $reward_id pièces d'or" ;;
                *) echo "- Récompense inconnue: $reward_type" ;;
            esac
        done
    fi
    
    return 0
}

# Initialiser le système de quêtes
init_quests
