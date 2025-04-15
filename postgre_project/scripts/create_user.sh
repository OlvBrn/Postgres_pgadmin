#!/bin/bash

HOSTNAME=$(hostname)
USERNAME="log_${HOSTNAME}"
PASSWORD="pass_${HOSTNAME}"

echo "👤 Vérification ou création de l’utilisateur PostgreSQL : $USERNAME"

psql -h my-postgres.postgres.svc.cluster.local -U log1 -d logs_db -c "
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$USERNAME') THEN
    CREATE USER $USERNAME WITH PASSWORD '$PASSWORD';
  END IF;
END
\$\$;"
