<#
.SYNOPSIS
Trendy Commercial Banking - Windows Docker Deployment
Run on a NEW lab deployment from an Administrator PowerShell prompt: .\deploy.ps1
#>

$ErrorActionPreference = "Stop"
$AppDir = $PSScriptRoot
if ($AppDir) { Set-Location $AppDir }

# Helper function to replace OpenSSL hex generation
function Get-RandomHex([int]$Bytes = 20) {
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $buffer = New-Object byte[] $Bytes
    $rng.GetBytes($buffer)
    return ([System.BitConverter]::ToString($buffer) -replace "-").ToLower()
}

Write-Host "[1/8] Checking for Docker..."
if (!(Get-Command docker -ErrorAction SilentlyContinue) -or !(docker compose version 2>$null)) {
    Write-Error "ERROR: Docker or Docker Compose is missing. Please install Docker Desktop for Windows and ensure it is running."
    exit 1
}

Write-Host "[2/8] Creating protected environment file..."
if (!(Test-Path ".env")) {
    $newPwd = Get-RandomHex
    Set-Content -Path ".env" -Value "ORACLE_PWD=$newPwd" -Encoding ASCII
}

# Parse ORACLE_PWD from .env
$envFile = Get-Content ".env" | Where-Object { $_ -match "^ORACLE_PWD=(.*)" }
$ORACLE_PWD = $matches[1]

if ([string]::IsNullOrWhiteSpace($ORACLE_PWD) -or $ORACLE_PWD -eq "CHANGE_ME_TO_A_STRONG_PASSWORD") {
    Write-Error "ERROR: Set a strong ORACLE_PWD in .env, then rerun."
    exit 1
}

Write-Host "[3/8] Pulling Oracle Database Free image..."
docker compose pull

Write-Host "[4/8] Starting Oracle..."
docker compose up -d

Write-Host "[5/8] Waiting for the default PDB FREEPDB1 (up to 30 minutes)..."
$startTime = Get-Date
$deadline = $startTime.AddMinutes(30)
$ready = $false

while ((Get-Date) -lt $deadline) {
    $checkCmd = docker exec trendy-commercial-banking-oracle bash -lc "echo 'SELECT 1 FROM DUAL;' | sqlplus -s `"SYSTEM/$ORACLE_PWD@//127.0.0.1:1521/FREEPDB1`" 2>/dev/null"
    if ($checkCmd -match "1") {
        $ready = $true
        break
    }
    
    $containerCheck = docker ps -a --format "{{.Names}}"
    if ($containerCheck -notmatch "trendy-commercial-banking-oracle") {
        Write-Error "ERROR: Oracle container was not created. Check image access and docker compose ps."
        docker compose ps
        exit 1
    }
    Start-Sleep -Seconds 10
}

if (-not $ready) {
    Write-Error "ERROR: Oracle did not become ready within 30 minutes."
    docker logs --tail 120 trendy-commercial-banking-oracle
    exit 1
}

Write-Host "[6/8] Creating TRENDYSERVICE PDB if missing..."
if (!(Test-Path ".pdb_admin_password")) {
    Get-RandomHex | Set-Content -Path ".pdb_admin_password" -NoNewline -Encoding ASCII
}
$PDB_ADMIN_PASSWORD = Get-Content ".pdb_admin_password" -Raw

$createPdbSql = @"
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  pdb_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO pdb_count FROM v`$pdbs WHERE name = 'TRENDYSERVICE';
  IF pdb_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE PLUGGABLE DATABASE TRENDYSERVICE ADMIN USER PDBADMIN IDENTIFIED BY "$PDB_ADMIN_PASSWORD" ROLES=(DBA)';
  END IF;
END;
/
ALTER PLUGGABLE DATABASE TRENDYSERVICE OPEN;
ALTER PLUGGABLE DATABASE TRENDYSERVICE SAVE STATE;
EXIT
"@
$createPdbSql | docker exec -i trendy-commercial-banking-oracle bash -lc "sqlplus -s / as sysdba"

Write-Host "[7/8] Creating TRENDY application schema in TRENDYSERVICE..."
if (!(Test-Path ".app_password")) {
    Get-RandomHex | Set-Content -Path ".app_password" -NoNewline -Encoding ASCII
}
$APP_PASSWORD = Get-Content ".app_password" -Raw

$createSchemaSql = @"
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = TRENDYSERVICE;
DECLARE
  user_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO user_exists FROM dba_users WHERE username = 'TRENDY';
  IF user_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER TRENDY IDENTIFIED BY "$APP_PASSWORD"';
  ELSE
    EXECUTE IMMEDIATE 'ALTER USER TRENDY IDENTIFIED BY "$APP_PASSWORD" ACCOUNT UNLOCK';
  END IF;
END;
/
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE TO TRENDY;
ALTER USER TRENDY QUOTA UNLIMITED ON USERS;
EXIT
"@
$createSchemaSql | docker exec -i trendy-commercial-banking-oracle bash -lc "sqlplus -s / as sysdba"

Write-Host "[8/8] Verifying TRENDYSERVICE and writing private credentials..."
$verifySql = @"
WHENEVER SQLERROR EXIT SQL.SQLCODE
SELECT name, open_mode FROM v`$pdbs WHERE name = 'TRENDYSERVICE';
ALTER SESSION SET CONTAINER = TRENDYSERVICE;
SELECT SYS_CONTEXT('USERENV','CON_NAME') AS current_pdb FROM dual;
EXIT
"@
$verifySql | docker exec -i trendy-commercial-banking-oracle bash -lc "sqlplus -s / as sysdba"

$credentials = @"
Project: Trendy Commercial Banking
Oracle engine: Oracle Database Free
CDB: FREE
PDB/service: TRENDYSERVICE
Host: 127.0.0.1
Port: 1521

CDB admin username: SYSTEM
CDB admin password: $ORACLE_PWD

PDB admin username: PDBADMIN
PDB admin password: $PDB_ADMIN_PASSWORD

Application schema/user: TRENDY
Application password: $APP_PASSWORD

SQL client connection:
Host: 127.0.0.1
Port: 1521
Connection type: Service name
Service: TRENDYSERVICE
Username: TRENDY
Password: application password above

Keep this file private. Do not commit it, .env, or password files to Git.
"@

Set-Content -Path "credentials.txt" -Value $credentials -Encoding ASCII

Write-Host "`nDeployment complete."
docker compose ps
Write-Host "Connection: 127.0.0.1:1521 / service TRENDYSERVICE"
Write-Host "Credentials: $(Join-Path$PWD 'credentials.txt')"
Write-Host "Logs: docker logs -f trendy-commercial-banking-oracle"