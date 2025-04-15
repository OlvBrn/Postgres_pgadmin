# PostgreSQL Practice with Helm

Ce projet déploie un environnement complet Kubernetes avec :

- PostgreSQL 15 (`charts/my-postgres`)
- pgAdmin avec configuration automatique (`charts/pgadmin`)
- Pod Ubuntu avec outils préinstallés (`charts/ubuntu-lab`)
- Scripts d'automatisation (`scripts/`)

## Déploiement

```bash
./scripts/deploy_all.sh


Accès à pgAdmin

kubectl port-forward svc/pgadmin 8080:80 -n postgres
http://localhost:8080 (via port-forward)

Email : admin@example.com
Mot de passe : adminpass

Connexion à la base PostgreSQL
./scripts/connect.sh

Fonctionnement Ubuntu
Chaque pod ubuntu-lab :
Installe psql au démarrage
Crée un utilisateur PostgreSQL unique (log_<hostname>)
Peut se connecter à la base logs_db