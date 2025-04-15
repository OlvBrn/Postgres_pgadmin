#!/bin/bash
set -e

NAMESPACE="postgres"

echo "🔄 Vérification/création du namespace..."
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "🚀 Déploiement de PostgreSQL..."
helm upgrade --install my-postgres ./charts/my-postgres --namespace $NAMESPACE

echo "🌐 Déploiement de pgAdmin..."
helm upgrade --install pgadmin ./charts/pgadmin --namespace $NAMESPACE

echo "🧰 Déploiement de Ubuntu-lab..."
helm upgrade --install ubuntu-lab ./charts/ubuntu-lab --namespace $NAMESPACE

echo "✅ Tous les charts sont déployés proprement."

kubectl get all -n postgres