#!/bin/bash
#
# Script de lancement pour ASCII3D-Bash-Game
# Compatible avec Bash 3.2+ (macOS) et Bash 4.0+
#

# Définir les couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Bannière ASCII
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

# Vérifier la version de Bash
bash_version=$(bash --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+')
bash_major=$(echo $bash_version | cut -d. -f1)
bash_minor=$(echo $bash_version | cut -d. -f2)

echo -e "${BLUE}[INFO]${NC} Vérification de la version de Bash..."
echo "Version détectée : $bash_version"

# Chercher un Bash plus récent si nécessaire
newer_bash=""
if (( bash_major < 4 )); then
    echo -e "${YELLOW}[ATTENTION]${NC} Vous utilisez Bash $bash_version qui ne supporte pas les tableaux associatifs."
    echo "Le mode de compatibilité sera activé automatiquement, mais les performances peuvent être réduites."
    
    # Chercher Bash 4+ sur le système
    potential_paths=(
        "/usr/local/bin/bash"
        "/opt/homebrew/bin/bash"
        "/opt/local/bin/bash"
        "$(which bash)"
    )
    
    for path in "${potential_paths[@]}"; do
        if [[ -x "$path" ]]; then
            test_version=$("$path" --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+')
            test_major=$(echo $test_version | cut -d. -f1)
            
            if (( test_major >= 4 )); then
                newer_bash="$path"
                echo -e "${GREEN}[TROUVÉ]${NC} Une version plus récente de Bash ($test_version) a été trouvée à $path"
                break
            fi
        fi
    done
    
    if [[ -n "$newer_bash" ]]; then
        echo -e "${YELLOW}[QUESTION]${NC} Souhaitez-vous utiliser cette version plus récente pour de meilleures performances? (o/n)"
        read -r use_newer
        
        if [[ "$use_newer" == "o" || "$use_newer" == "O" || "$use_newer" == "oui" || "$use_newer" == "Oui" ]]; then
            echo -e "${BLUE}[INFO]${NC} Lancement avec Bash $test_version..."
            exec "$newer_bash" "src/menu.sh" "$@"
            exit 0
        fi
    else
        echo -e "${YELLOW}[ATTENTION]${NC} Aucune version plus récente de Bash n'a été trouvée."
        echo "Conseils pour installer Bash 4+ sur macOS :"
        echo "  1. Installer Homebrew : /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "  2. Installer Bash : brew install bash"
    fi
fi

# Options de lancement
echo ""
echo -e "${BLUE}[INFO]${NC} Que souhaitez-vous lancer ?"
echo "  1. Menu principal"
echo "  2. Jeu directement"
echo "  3. Éditeur de niveaux"
echo "  q. Quitter"
echo ""
echo -n "Votre choix (1/2/3/q) : "
read -r choice

case "$choice" in
    1)
        echo -e "${GREEN}[LANCEMENT]${NC} Menu principal..."
        ./src/menu.sh
        ;;
    2)
        echo -e "${GREEN}[LANCEMENT]${NC} Jeu..."
        ./src/main.sh
        ;;
    3)
        echo -e "${GREEN}[LANCEMENT]${NC} Éditeur de niveaux..."
        ./src/editor.sh
        ;;
    q|Q)
        echo -e "${BLUE}[INFO]${NC} Au revoir !"
        exit 0
        ;;
    *)
        echo -e "${YELLOW}[ATTENTION]${NC} Choix invalide. Lancement du menu principal par défaut..."
        ./src/menu.sh
        ;;
esac
