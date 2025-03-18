#!/bin/bash
#
# Script d'installation pour ASCII3D-Bash-Game
#

# Définir les couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher un message d'information
function info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Fonction pour afficher un succès
function success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Fonction pour afficher un avertissement
function warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Fonction pour afficher une erreur
function error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour vérifier une dépendance
function check_dependency() {
    local cmd=$1
    local package=$2
    local package_manager=$3
    
    if command -v $cmd &> /dev/null; then
        success "$cmd est déjà installé."
        return 0
    else
        warning "$cmd n'est pas installé."
        echo "Ce programme est nécessaire pour certaines fonctionnalités."
        if [[ -n "$package" && -n "$package_manager" ]]; then
            echo "Vous pouvez l'installer avec: $package_manager $package"
        fi
        return 1
    fi
}

# Afficher une bannière ASCII
echo -e "${GREEN}"
echo "    _    ____   ____ ___ ___ ____  ____  "
echo "   / \  / ___| / ___|_ _|_ _|___ \|  _ \ "
echo "  / _ \ \___ \| |    | | | |  __) | | | |"
echo " / ___ \ ___) | |___ | | | | / __/| |_| |"
echo "/_/   \_\____/ \____|___|___|_____|____/ "
echo "                                        "
echo " ____   _    ____  _   _    ____    _    __  __ _____ "
echo "| __ ) / \  / ___|| | | |  / ___|  / \  |  \/  | ____|"
echo "|  _ \/ _ \ \___ \| |_| | | |  _  / _ \ | |\/| |  _|  "
echo "| |_) / ___ \ ___) |  _  | | |_| |/ ___ \| |  | | |___ "
echo "|____/_/   \_\____/|_| |_|  \____/_/   \_\_|  |_|_____|"
echo -e "${NC}"
echo "Script d'installation pour ASCII3D-Bash-Game"
echo "===========================================" 
echo ""

# Vérifier la version de Bash
bash_version=$(bash --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+')
bash_major=$(echo $bash_version | cut -d. -f1)
bash_minor=$(echo $bash_version | cut -d. -f2)

if (( bash_major < 4 )); then
    error "Ce jeu nécessite Bash 4.0 ou supérieur. Version détectée: $bash_version"
    exit 1
else
    success "Version de Bash compatible détectée: $bash_version"
fi

# Vérifier la présence de bc
check_dependency "bc" "bc" "apt-get install" || true

# Déterminer le gestionnaire de paquets
if command -v apt-get &> /dev/null; then
    PACKAGE_MANAGER="apt-get install"
elif command -v dnf &> /dev/null; then
    PACKAGE_MANAGER="dnf install"
elif command -v yum &> /dev/null; then
    PACKAGE_MANAGER="yum install"
elif command -v pacman &> /dev/null; then
    PACKAGE_MANAGER="pacman -S"
elif command -v brew &> /dev/null; then
    PACKAGE_MANAGER="brew install"
else
    PACKAGE_MANAGER=""
fi

# Vérifier les dépendances optionnelles pour le son
check_dependency "beep" "beep" "$PACKAGE_MANAGER" || true
check_dependency "play" "sox" "$PACKAGE_MANAGER" || true
check_dependency "aplay" "alsa-utils" "$PACKAGE_MANAGER" || true
check_dependency "mpg123" "mpg123" "$PACKAGE_MANAGER" || true

echo ""
info "Création des répertoires nécessaires..."

# Créer les répertoires nécessaires s'ils n'existent pas
mkdir -p assets/levels
mkdir -p assets/models
mkdir -p assets/sounds/fx
mkdir -p assets/sounds/music
mkdir -p config
mkdir -p saves
mkdir -p docs

success "Répertoires créés avec succès."

# Rendre les scripts exécutables
echo ""
info "Configuration des permissions..."

chmod +x src/main.sh
chmod +x src/menu.sh
chmod +x src/editor.sh

success "Scripts rendus exécutables."

# Vérifier les dimensions du terminal
term_cols=$(tput cols)
term_lines=$(tput lines)

echo ""
info "Vérification des dimensions du terminal..."
echo "Dimensions actuelles: ${term_cols}x${term_lines}"

if (( term_cols < 80 || term_lines < 24 )); then
    warning "Pour une expérience optimale, votre terminal devrait avoir au moins 80x24 caractères."
    warning "Dimensions actuelles: ${term_cols}x${term_lines}"
else
    success "Dimensions du terminal adéquates pour le jeu."
fi

echo ""
success "Installation terminée !"
echo ""
echo "Pour lancer le jeu:"
echo "  ./src/menu.sh    - Menu principal"
echo "  ./src/main.sh    - Lancer directement le jeu"
echo "  ./src/editor.sh  - Lancer l'éditeur de niveaux"
echo ""
echo "Bon jeu !"

# Proposer de lancer le jeu directement
echo ""
read -p "Voulez-vous lancer le jeu maintenant? (o/n): " launch_now

if [[ "$launch_now" == "o" || "$launch_now" == "O" || "$launch_now" == "oui" || "$launch_now" == "Oui" ]]; then
    ./src/menu.sh
fi
