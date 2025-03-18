#!/bin/bash
#
# Script de compatibilité pour Bash 3.2 (macOS)
#

# Détecter la version de Bash
BASH_VERSION_MAJOR=${BASH_VERSION%%.*}

# Fonction pour émuler les tableaux associatifs sur Bash 3.2
if [[ $BASH_VERSION_MAJOR -lt 4 ]]; then
    echo "Mode de compatibilité activé pour Bash $BASH_VERSION"
    
    # Fonctions pour gérer les tableaux associatifs émulés
    function declare_A() {
        local var_name=$1
        eval "${var_name}=()"
    }
    
    function associative_set() {
        local array_name=$1
        local key=$2
        local value=$3
        # Échapper les caractères spéciaux
        key=$(echo "$key" | sed 's/[\/&]/\\&/g')
        value=$(echo "$value" | sed 's/[\/&]/\\&/g')
        eval "${array_name}_${key}=\"${value}\""
    }
    
    function associative_get() {
        local array_name=$1
        local key=$2
        local var_name="${array_name}_${key}"
        eval "echo \"\${$var_name}\""
    }
    
    function associative_exists() {
        local array_name=$1
        local key=$2
        local var_name="${array_name}_${key}"
        eval "[[ -n \"\${$var_name+x}\" ]]"
        return $?
    }
    
    function associative_keys() {
        local array_name=$1
        local prefix="${array_name}_"
        local vars=$(set | grep "^${prefix}" | cut -d= -f1)
        for var in $vars; do
            echo "${var#$prefix}"
        done
    }
    
    function associative_unset() {
        local array_name=$1
        local key=$2
        local var_name="${array_name}_${key}"
        eval "unset $var_name"
    }
    
    # Redéfinir les fonctions qui utilisent des tableaux associatifs
    # Pour utiliser dans les scripts, remplacez:
    # declare -A MYARRAY → declare_A MYARRAY
    # MYARRAY["key"]="value" → associative_set MYARRAY "key" "value"
    # echo "${MYARRAY["key"]}" → echo "$(associative_get MYARRAY "key")"
    # if [[ -n "${MYARRAY["key"]}" ]] → if associative_exists MYARRAY "key"
    # unset MYARRAY["key"] → associative_unset MYARRAY "key"
    # for key in "${!MYARRAY[@]}" → for key in $(associative_keys MYARRAY)
    
    echo "Les tableaux associatifs ont été émulés pour la compatibilité."
    echo "Certaines fonctionnalités pourraient être plus lentes."
else
    # Bash 4.0+, pas besoin d'émulation
    function declare_A() {
        local var_name=$1
        eval "declare -A ${var_name}"
    }
    
    function associative_set() {
        local array_name=$1
        local key=$2
        local value=$3
        eval "${array_name}[\"${key}\"]=\"${value}\""
    }
    
    function associative_get() {
        local array_name=$1
        local key=$2
        eval "echo \"\${${array_name}[\"${key}\"]}\""
    }
    
    function associative_exists() {
        local array_name=$1
        local key=$2
        eval "[[ -n \"\${${array_name}[\"${key}\"]+x}\" ]]"
        return $?
    }
    
    function associative_keys() {
        local array_name=$1
        eval "echo \"\${!${array_name}[@]}\""
    }
    
    function associative_unset() {
        local array_name=$1
        local key=$2
        eval "unset ${array_name}[\"${key}\"]"
    }
fi
