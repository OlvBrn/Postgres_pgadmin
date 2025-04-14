#!/bin/bash

set -e

POD_NAME="ubuntu-pg"

# Petite fonction utilitaire pour exécuter dans le pod
kexec() {
    kubectl exec -i "$POD_NAME" -- bash -c "$1"
}

echo "📦 Vérification si PostgreSQL est déjà installé..."
if ! kexec "dpkg -l | grep postgresql-15" &>/dev/null; then
    echo "📥 Installation de PostgreSQL 15..."

    kexec "apt update && apt install -y wget gnupg2 lsb-release"
    DISTRO_CODENAME=$(kubectl exec "$POD_NAME" -- bash -c "lsb_release -cs")
    kexec "echo 'deb http://apt.postgresql.org/pub/repos/apt/ ${DISTRO_CODENAME}-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
    kexec "wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -"
    kexec "apt update && apt install -y postgresql-15"
else
    echo "✅ PostgreSQL 15 est déjà installé."
fi

# Init DB si le dossier est vide
echo "📁 Vérification de l'initialisation de la base de données..."
if ! kexec "[ -f /var/lib/postgresql/data/PG_VERSION ]"; then
    echo "📁 Initialisation de PostgreSQL..."
    kexec "su - postgres -c '/usr/lib/postgresql/15/bin/initdb -D /var/lib/postgresql/data'"
else
    echo "✅ Cluster PostgreSQL déjà initialisé."
fi

# Démarrage du serveur PostgreSQL si pas déjà en route
echo "🚀 Lancement de PostgreSQL..."
if ! kexec "pgrep -u postgres postgres" &>/dev/null; then
    kexec "su - postgres -c '/usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/data -l logfile start'"
else
    echo "✅ PostgreSQL est déjà en cours d’exécution."
fi

# Création des users si non existants
echo "👤 Création des utilisateurs PostgreSQL si nécessaires..."

for user in log1 log2; do
    if ! kexec "su - postgres -c \"psql -tAc \\\"SELECT 1 FROM pg_roles WHERE rolname='${user}'\\\"\"" | grep -q 1; then
        echo "➕ Création de l'utilisateur $user..."
        kexec "su - postgres -c \"psql -c \\\"CREATE USER $user WITH PASSWORD '${user}pass';\\\"\""
    else
        echo "✅ Utilisateur $user déjà existant."
    fi
done

# Création de la base logs_db si non existante
echo "🗄️ Création de la base de données logs_db si nécessaire..."
if ! kexec "su - postgres -c \"psql -tAc \\\"SELECT 1 FROM pg_database WHERE datname='logs_db'\\\"\"" | grep -q 1; then
    kexec "su - postgres -c \"psql -c \\\"CREATE DATABASE logs_db OWNER log1;\\\"\""
    echo "✅ Base logs_db créée."
else
    echo "✅ Base logs_db déjà existante."
fi

echo "🎉 PostgreSQL prêt, utilisateurs et base configurés."
