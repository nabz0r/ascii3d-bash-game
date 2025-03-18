#!/bin/bash
#
# Système d'effets sonores pour ASCII3D-Bash-Game
#

# Configuration des sons
SOUND_ENABLED=true
MUSIC_ENABLED=true
SOUND_VOLUME=70  # 0-100
MUSIC_VOLUME=50  # 0-100
CURRENT_MUSIC=""

# Dépendances possibles pour le son
PLAY_CMD=""
BEEP_CMD=""
SOX_CMD=""
APLAY_CMD=""
MPG123_CMD=""

# Initialiser le système sonore
function init_sound() {
    echo "Initialisation du système sonore..."
    
    # Vérifier les options du jeu
    if [[ -n "${GAME_OPTIONS["soundfx"]}" ]]; then
        SOUND_ENABLED=${GAME_OPTIONS["soundfx"]}
    fi
    
    if [[ -n "${GAME_OPTIONS["musique"]}" ]]; then
        MUSIC_ENABLED=${GAME_OPTIONS["musique"]}
    fi
    
    # Détecter les commandes disponibles pour le son
    if command -v play &> /dev/null; then
        SOX_CMD="play"
        echo "SoX détecté pour les effets sonores."
    elif command -v aplay &> /dev/null; then
        APLAY_CMD="aplay"
        echo "ALSA aplay détecté pour les effets sonores."
    elif command -v beep &> /dev/null; then
        BEEP_CMD="beep"
        echo "Beep détecté pour les effets sonores basiques."
    fi
    
    # Détecter les commandes disponibles pour la musique
    if command -v mpg123 &> /dev/null; then
        MPG123_CMD="mpg123"
        echo "mpg123 détecté pour la musique."
    elif command -v play &> /dev/null; then
        SOX_CMD="play"
        echo "SoX détecté pour la musique."
    fi
    
    # Créer les répertoires pour les sons s'ils n'existent pas
    mkdir -p "$SCRIPT_DIR/../assets/sounds/fx"
    mkdir -p "$SCRIPT_DIR/../assets/sounds/music"
    
    echo "Système sonore initialisé."
}

# Fonction pour jouer un son
function play_sound() {
    # Si les sons sont désactivés, ne rien faire
    if ! $SOUND_ENABLED; then
        return
    fi
    
    local sound_name=$1
    local volume=${2:-$SOUND_VOLUME}
    
    # Construire le chemin du fichier son
    local sound_file="$SCRIPT_DIR/../assets/sounds/fx/$sound_name"
    
    # Jouer le son de manière asynchrone (en arrière-plan)
    if [[ -n "$SOX_CMD" && -f "$sound_file" ]]; then
        $SOX_CMD -q "$sound_file" -v $volume gain -n &> /dev/null &
    elif [[ -n "$APLAY_CMD" && -f "$sound_file" ]]; then
        $APLAY_CMD -q "$sound_file" &> /dev/null &
    elif [[ -n "$BEEP_CMD" ]]; then
        # Simuler des sons avec beep
        case "$sound_name" in
            "shoot.wav")
                $BEEP_CMD -f 1000 -l 50 &> /dev/null &
                ;;
            "hit.wav")
                $BEEP_CMD -f 500 -l 100 &> /dev/null &
                ;;
            "explosion.wav")
                $BEEP_CMD -f 300 -l 200 -f 200 -l 200 &> /dev/null &
                ;;
            "jump.wav")
                $BEEP_CMD -f 800 -l 50 -f 1200 -l 50 &> /dev/null &
                ;;
            "pickup.wav")
                $BEEP_CMD -f 1200 -l 50 -f 1500 -l 50 &> /dev/null &
                ;;
            "menu.wav")
                $BEEP_CMD -f 800 -l 50 &> /dev/null &
                ;;
            *)
                # Son générique pour les autres effets
                $BEEP_CMD -f 800 -l 50 &> /dev/null &
                ;;
        esac
    else
        # En dernier recours, utiliser le bip du terminal
        echo -ne "\a" &> /dev/null &
    fi
}

# Variables pour le pid du processus de musique
MUSIC_PID=""

# Fonction pour jouer de la musique en boucle
function play_music() {
    # Si la musique est désactivée, ne rien faire
    if ! $MUSIC_ENABLED; then
        return
    fi
    
    local music_name=$1
    local volume=${2:-$MUSIC_VOLUME}
    
    # Si c'est déjà la musique en cours, ne rien faire
    if [[ "$CURRENT_MUSIC" == "$music_name" && -n "$MUSIC_PID" ]] && kill -0 $MUSIC_PID &> /dev/null; then
        return
    fi
    
    # Arrêter la musique en cours
    stop_music
    
    # Mettre à jour la musique en cours
    CURRENT_MUSIC="$music_name"
    
    # Construire le chemin du fichier musique
    local music_file="$SCRIPT_DIR/../assets/sounds/music/$music_name"
    
    # Jouer la musique en boucle en arrière-plan
    if [[ -n "$MPG123_CMD" && -f "$music_file" ]]; then
        $MPG123_CMD -q --loop -1 -v "$volume" "$music_file" &> /dev/null &
        MUSIC_PID=$!
    elif [[ -n "$SOX_CMD" && -f "$music_file" ]]; then
        $SOX_CMD -q -v "$volume" "$music_file" -p repeat 99999 &> /dev/null &
        MUSIC_PID=$!
    fi
}

# Fonction pour arrêter la musique
function stop_music() {
    if [[ -n "$MUSIC_PID" ]]; then
        kill $MUSIC_PID &> /dev/null || true
        MUSIC_PID=""
    fi
    
    CURRENT_MUSIC=""
}

# Fonction pour changer le volume des sons
function set_sound_volume() {
    SOUND_VOLUME=$1
    
    # Limiter le volume entre 0 et 100
    if (( SOUND_VOLUME < 0 )); then
        SOUND_VOLUME=0
    elif (( SOUND_VOLUME > 100 )); then
        SOUND_VOLUME=100
    fi
}

# Fonction pour changer le volume de la musique
function set_music_volume() {
    MUSIC_VOLUME=$1
    
    # Limiter le volume entre 0 et 100
    if (( MUSIC_VOLUME < 0 )); then
        MUSIC_VOLUME=0
    elif (( MUSIC_VOLUME > 100 )); then
        MUSIC_VOLUME=100
    fi
    
    # Si une musique est en cours, la redémarrer avec le nouveau volume
    local current_music_backup="$CURRENT_MUSIC"
    if [[ -n "$current_music_backup" ]]; then
        stop_music
        play_music "$current_music_backup"
    fi
}

# Fonction pour le bip du terminal (son basique disponible partout)
function terminal_beep() {
    echo -ne "\a" &> /dev/null
}

# Générer un son basé sur la fréquence
function generate_tone() {
    local freq=$1
    local duration=${2:-100}  # en millisecondes
    
    if [[ -n "$BEEP_CMD" ]]; then
        $BEEP_CMD -f $freq -l $duration &> /dev/null &
    else
        terminal_beep
    fi
}

# Générer une séquence de tons (mélodie simple)
function generate_melody() {
    local frequencies=("$@")
    local duration=100
    
    for freq in "${frequencies[@]}"; do
        generate_tone $freq $duration
        sleep 0.1
    done
}

# Sons prédéfinis
function sound_menu_select() {
    if $SOUND_ENABLED; then
        play_sound "menu.wav" || generate_tone 800
    fi
}

function sound_menu_move() {
    if $SOUND_ENABLED; then
        play_sound "menu_move.wav" || generate_tone 600
    fi
}

function sound_player_jump() {
    if $SOUND_ENABLED; then
        play_sound "jump.wav" || generate_tone 900 50
    fi
}

function sound_player_hit() {
    if $SOUND_ENABLED; then
        play_sound "hit.wav" || generate_tone 300 150
    fi
}

function sound_player_shoot() {
    if $SOUND_ENABLED; then
        play_sound "shoot.wav" || generate_tone 1200 50
    fi
}

function sound_explosion() {
    if $SOUND_ENABLED; then
        play_sound "explosion.wav" || generate_melody 300 200 100
    fi
}

function sound_pickup() {
    if $SOUND_ENABLED; then
        play_sound "pickup.wav" || generate_tone 1300 50
    fi
}

function sound_door_open() {
    if $SOUND_ENABLED; then
        play_sound "door.wav" || generate_tone 400 200
    fi
}

function sound_level_complete() {
    if $SOUND_ENABLED; then
        play_sound "level_complete.wav" || generate_melody 600 800 1000 1200
    fi
}

function sound_game_over() {
    if $SOUND_ENABLED; then
        play_sound "game_over.wav" || generate_melody 800 600 400 200
    fi
}

# Nettoyer les processus audio à la sortie
function cleanup_sound() {
    # Arrêter la musique
    stop_music
    
    # Tuer tous les processus audio en cours
    if [[ -n "$SOX_CMD" ]]; then
        pkill -f "$SOX_CMD" &> /dev/null || true
    fi
    
    if [[ -n "$APLAY_CMD" ]]; then
        pkill -f "$APLAY_CMD" &> /dev/null || true
    fi
    
    if [[ -n "$MPG123_CMD" ]]; then
        pkill -f "$MPG123_CMD" &> /dev/null || true
    fi
}

# Enregistrer le nettoyage à la sortie
trap cleanup_sound EXIT

# Initialiser le système sonore
init_sound
