#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

# Trendy Commercial Banking - Ubuntu 22.04/24.04 EC2.
# Creates a separate PDB TRENDYDB from the default Oracle Free CDB.
# Run on a NEW lab deployment: chmod +x deploy.sh && ./deploy.sh
# WARNING: do not use this script to replace a database containing valuable data.

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$APP_DIR"
SUDO=""
if [[ $EUID -ne 0 ]]; then SUDO="sudo"; fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "ERROR: This script expects Ubuntu/Debian with apt-get."
  exit 1
fi

echo "[1/8] Installing Docker, Compose, and OpenSSL if needed..."
if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  $SUDO apt-get update
  $SUDO apt-get install -y docker.io docker-compose-v2 openssl
elif ! command -v openssl >/dev/null 2>&1; then
  $SUDO apt-get update
  $SUDO apt-get install -y openssl
fi
$SUDO systemctl enable --now docker

echo "[2/8] Creating protected environment file..."
if [[ ! -f .env ]]; then
  printf 'ORACLE_PWD=%s\n' "$(openssl rand -hex 20)" > .env
fi
# shellcheck disable=SC1091
source .env
if [[ -z "${ORACLE_PWD:-}" || "${ORACLE_PWD}" == "CHANGE_ME_TO_A_STRONG_PASSWORD" ]]; then
  echo "ERROR: Set a strong ORACLE_PWD in .env, then rerun."
  exit 1
fi
chmod 600 .env

echo "[3/8] Pulling Oracle Database Free image..."
docker compose pull

echo "[4/8] Starting Oracle..."
docker compose up -d

echo "[5/8] Waiting for the default PDB FREEPDB1 (up to 30 minutes)..."
deadline=$((SECONDS + 1800))
ready=0
while (( SECONDS < deadline )); do
  if docker exec trendy-commercial-banking-oracle bash -lc \
    'echo "SELECT 1 FROM DUAL;" | sqlplus -s "SYSTEM/'"${ORACLE_PWD}"'@//127.0.0.1:1521/FREEPDB1" 2>/dev/null | grep -q "1"' \
    >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! docker ps -a --format '{{.Names}}' | grep -qx trendy-commercial-banking-oracle; then
    echo "ERROR: Oracle container was not created. Check image access and docker compose ps."
    docker compose ps || true
    exit 1
  fi
  sleep 10
done
if [[ "$ready" -ne 1 ]]; then
  echo "ERROR: Oracle did not become ready within 30 minutes."
  docker logs --tail 120 trendy-commercial-banking-oracle || true
  exit 1
fi

echo "[6/8] Creating TRENDYDB PDB if missing..."
# PDB creation uses Oracle's documented CREATE PLUGGABLE DATABASE workflow.
# The PDB admin password is generated as hex to avoid SQL quoting problems.
if [[ ! -f .pdb_admin_password ]]; then
  openssl rand -hex 20 > .pdb_admin_password
fi
PDB_ADMIN_PASSWORD="$(tr -d '\r\n' < .pdb_admin_password)"
if [[ ! "$PDB_ADMIN_PASSWORD" =~ ^[a-fA-F0-9]{40}$ ]]; then
  echo "ERROR: .pdb_admin_password is invalid."
  exit 1
fi
chmod 600 .pdb_admin_password

docker exec -i trendy-commercial-banking-oracle bash -lc 'sqlplus -s / as sysdba' <<SQL
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  pdb_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO pdb_count FROM v\$pdbs WHERE name = 'TRENDYDB';
  IF pdb_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE PLUGGABLE DATABASE TRENDYDB ADMIN USER PDBADMIN IDENTIFIED BY "${PDB_ADMIN_PASSWORD}" ROLES=(DBA)';
  END IF;
END;
/
ALTER PLUGGABLE DATABASE TRENDYDB OPEN;
ALTER PLUGGABLE DATABASE TRENDYDB SAVE STATE;
EXIT
SQL

echo "[7/8] Creating TRENDY application schema in TRENDYDB..."
if [[ ! -f .app_password ]]; then
  openssl rand -hex 20 > .app_password
fi
APP_PASSWORD="$(tr -d '\r\n' < .app_password)"
if [[ ! "$APP_PASSWORD" =~ ^[a-fA-F0-9]{40}$ ]]; then
  echo "ERROR: .app_password is invalid."
  exit 1
fi
chmod 600 .app_password

docker exec -i trendy-commercial-banking-oracle bash -lc 'sqlplus -s / as sysdba' <<SQL
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = TRENDYDB;
DECLARE
  user_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO user_exists FROM dba_users WHERE username = 'TRENDY';
  IF user_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER TRENDY IDENTIFIED BY "${APP_PASSWORD}"';
  ELSE
    EXECUTE IMMEDIATE 'ALTER USER TRENDY IDENTIFIED BY "${APP_PASSWORD}" ACCOUNT UNLOCK';
  END IF;
END;
/
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE TO TRENDY;
ALTER USER TRENDY QUOTA UNLIMITED ON USERS;
EXIT
SQL

echo "[8/8] Verifying TRENDYDB and writing private credentials..."
docker exec -i trendy-commercial-banking-oracle bash -lc 'sqlplus -s / as sysdba' <<'SQL'
WHENEVER SQLERROR EXIT SQL.SQLCODE
SELECT name, open_mode FROM v$pdbs WHERE name = 'TRENDYDB';
ALTER SESSION SET CONTAINER = TRENDYDB;
SELECT SYS_CONTEXT('USERENV','CON_NAME') AS current_pdb FROM dual;
EXIT
SQL

cat > credentials.txt <<EOF
Project: Trendy Commercial Banking
Oracle engine: Oracle Database Free
CDB: FREE (default image CDB; verify on your image release)
PDB/service: TRENDYDB
Host on EC2: 127.0.0.1
Port: 1521
CDB admin username: SYSTEM
CDB admin password: ${ORACLE_PWD}

PDB admin username: PDBADMIN
PDB admin password: ${PDB_ADMIN_PASSWORD}

Application schema/user: TRENDY
Application password: ${APP_PASSWORD}

Windows SSH tunnel (replace key path and EC2 address):
ssh -i "C:\\path\\to\\key.pem" -N -L 1521:127.0.0.1:1521 ubuntu@EC2_PUBLIC_IP

SQL client:
Host: 127.0.0.1
Port: 1521
Connection type: Service name
Service: TRENDYDB
Username: TRENDY
Password: application password above

Keep this file private. Do not commit it, .env, or password files to Git.
EOF
chmod 600 credentials.txt .env .app_password .pdb_admin_password

echo
echo "Deployment complete."
docker compose ps
echo "Connection: 127.0.0.1:1521 / service TRENDYDB (through SSH tunnel)"
echo "Credentials: $APP_DIR/credentials.txt (private; mode 600)"
echo "Logs: docker logs -f trendy-commercial-banking-oracle"
echo "Keep inbound TCP 1521 closed in the EC2 security group."
