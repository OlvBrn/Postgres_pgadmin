#!/bin/bash
set -e

NAMESPACE="postgres"

# 🔍 Récupération dynamique du nom du pod Ubuntu-lab
POD=$(kubectl get pod -n $NAMESPACE -l app=ubuntu-lab -o jsonpath="{.items[0].metadata.name}")

# 🧠 Déduction du nom d'utilisateur et mot de passe PostgreSQL
USERNAME="log_${POD}"
PASSWORD="pass_${POD}"

echo "🔗 Connexion à PostgreSQL depuis le pod : $POD"
echo "👤 Utilisateur PostgreSQL : $USERNAME"

# 💻 Exécution de psql dans le pod avec PGPASSWORD exporté
kubectl exec -it -n $NAMESPACE "$POD" -- bash -c "
export PGPASSWORD=$PASSWORD && \
psql -h my-postgres.postgres.svc.cluster.local -U $USERNAME -d logs_db"
