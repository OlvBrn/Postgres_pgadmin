#!/bin/bash

set -e

POD_NAME="ubuntu-pg"

# Fonction d'exécution dans le pod
kexec() {
    kubectl exec -i "$POD_NAME" -- bash -c "$1"
}

echo "📦 Vérification si PostgreSQL est déjà installé..."
if ! kexec "dpkg -l | grep postgresql-15" &>/dev/null; then
    echo "📥 Installation de PostgreSQL 15..."

    kexec "apt update && apt install -y wget gnupg2 lsb-release"

    # Correction ici : évaluer lsb_release correctement
    DISTRO_CODENAME=$(kubectl exec "$POD_NAME" -- bash -c "lsb_release -cs")
    kexec "echo 'deb http://apt.postgresql.org/pub/repos/apt/ ${DISTRO_CODENAME}-pgdg main' > /etc/apt/sources.list.d/pgdg.list"

    kexec "wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -"
    kexec "apt update && apt install -y postgresql-15"
else
    echo "✅ PostgreSQL 15 déjà installé."
fi

echo "📁 Vérification de l'initialisation de PostgreSQL..."
if ! kexec "[ -f /var/lib/postgresql/data/PG_VERSION ]"; then
    kexec "su - postgres -c '/usr/lib/postgresql/15/bin/initdb -D /var/lib/postgresql/data'"
else
    echo "✅ Cluster PostgreSQL déjà initialisé."
fi

echo "🚀 Lancement de PostgreSQL..."
if ! kexec "pgrep -u postgres postgres" &>/dev/null; then
    kexec "su - postgres -c '/usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/data -l logfile start'"
else
    echo "✅ PostgreSQL déjà en cours d’exécution."
fi

echo "👥 Création des utilisateurs log1 et log2 si nécessaires..."
for user in log1 log2; do
    if ! kexec "su - postgres -c \"psql -tAc \\\"SELECT 1 FROM pg_roles WHERE rolname='${user}'\\\"\"" | grep -q 1; then
        kexec "su - postgres -c \"psql -c \\\"CREATE USER $user WITH PASSWORD '${user}pass';\\\"\""
        echo "➕ Utilisateur $user créé."
    else
        echo "✅ Utilisateur $user déjà existant."
    fi
done

echo "🗄️ Création de la base logs_db si nécessaire..."
if ! kexec "su - postgres -c \"psql -tAc \\\"SELECT 1 FROM pg_database WHERE datname='logs_db'\\\"\"" | grep -q 1; then
    kexec "su - postgres -c \"psql -c \\\"CREATE DATABASE logs_db OWNER log1;\\\"\""
    echo "✅ Base logs_db créée."
else
    echo "✅ Base logs_db déjà existante."
fi

echo "🎉 PostgreSQL prêt, tout est configuré !"
