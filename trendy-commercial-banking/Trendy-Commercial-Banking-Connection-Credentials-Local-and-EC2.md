# Trendy Commercial Banking — Oracle Setup and Connection Notes

**Last updated:** 15 October 2026  
**Environment:** Windows + PowerShell + Docker Desktop for local development; AWS EC2 Ubuntu for remote deployment  
**SQL client:** PL/SQL Developer

## 1. Database configuration

| Setting | Local Windows | AWS EC2 |
|---|---|---|
| Oracle container | `trendy-commercial-banking-oracle` | `trendy-commercial-banking-oracle` |
| CDB | `FREE` | `FREE` |
| Intended PDB/service | `TRENDYDB` | `TRENDYDB` |
| Application schema/user | `TRENDY` | `TRENDY` |
| Oracle listener port | `1521` | `1521` |
| Client host | `127.0.0.1` | `127.0.0.1` through SSH tunnel |
| Application password source | Local project's private `credentials.txt` | EC2 project's private `credentials.txt` |

**Current status note:** The last local database check showed the instance as `OPEN`, with `FREEPDB1` open read/write. `TRENDYDB` had not yet been created; creation failed with `ORA-65016: FILE_NAME_CONVERT must be specified`. Use the actual Oracle file configuration before attempting to create it again. The connection profiles below for `TRENDYDB` apply after that service exists.

## 2. PL/SQL Developer — Local Windows connection

Start Docker Desktop, then open PowerShell in the local project folder.

Check the container:

```powershell
docker ps
docker logs --tail 100 trendy-commercial-banking-oracle
```

In PL/SQL Developer, create a connection profile:

| Field | Value |
|---|---|
| Connection name | `Trendy Local` |
| Username | `TRENDY` |
| Password | The application password in the local project's private `credentials.txt` |
| Connect as | `Normal` |
| Host | `127.0.0.1` |
| Port | `1521` |
| Service name | `TRENDYDB` |

If your PL/SQL Developer version uses one **Database** field rather than separate host/port/service fields, try the Easy Connect form:

```text
127.0.0.1:1521/TRENDYDB
```

### Temporary local administrator connection

Until `TRENDYDB` has been created, you can connect to the existing `FREEPDB1` service to inspect the database:

| Field | Value |
|---|---|
| Connection name | `Trendy Local Admin (temporary)` |
| Username | `SYSTEM` |
| Password | The configured Oracle `SYSTEM` password |
| Connect as | `Normal` |
| Database/service | `127.0.0.1:1521/FREEPDB1` |

Use an administrator account only for setup and troubleshooting; use `TRENDY` for normal application development.

## 3. PL/SQL Developer — AWS EC2 connection

**Do not expose port 1521 in the EC2 security group.** Keep Oracle bound to the EC2 loopback interface and connect through SSH tunneling.

### Step A — Start the SSH tunnel on Windows

Open a separate Windows PowerShell window. Replace the key path and EC2 public IP/DNS with your actual values:

```powershell
ssh -i "C:\path\to\key.pem" -N -L 1521:127.0.0.1:1521 ubuntu@EC2_PUBLIC_IP
```

Keep this PowerShell window open while using PL/SQL Developer. If SSH reports that local port `1521` is already in use, use local port `11521` instead:

```powershell
ssh -i "C:\path\to\key.pem" -N -L 11521:127.0.0.1:1521 ubuntu@EC2_PUBLIC_IP
```

With the second command, use port `11521` in PL/SQL Developer. The remote Oracle port remains `1521`.

### Step B — Create the PL/SQL Developer profile

With the SSH tunnel running, configure:

| Field | Value |
|---|---|
| Connection name | `Trendy EC2` |
| Username | `TRENDY` |
| Password | The application password in EC2's private `credentials.txt` |
| Connect as | `Normal` |
| Host | `127.0.0.1` |
| Port | `1521` (or `11521` if you used the alternate tunnel command) |
| Service name | `TRENDYDB` |

If your PL/SQL Developer version uses a single **Database** field, use `127.0.0.1:1521/TRENDYDB` (or `127.0.0.1:11521/TRENDYDB` for the alternate tunnel).

The local and EC2 credentials may be different. Use the password file from the matching environment.

## 4. Verify which database you connected to

Run this in PL/SQL Developer after connecting:

```sql
SELECT
    SYS_CONTEXT('USERENV', 'CON_NAME') AS PDB_NAME,
    SYS_CONTEXT('USERENV', 'SERVICE_NAME') AS SERVICE_NAME,
    USER AS CONNECTED_USER
FROM dual;
```

For the application profile, expect PDB/service `TRENDYDB` and user `TRENDY`.

## 5. Troubleshooting

### `TRENDYDB` is not found

The last known database state contained `FREEPDB1` and `PDB$SEED` only. Connect as SYSDBA and inspect the real Oracle configuration before creating the PDB:

```sql
SELECT status FROM v$instance;
SELECT name, open_mode FROM v$pdbs;
SHOW PARAMETER db_create_file_dest;
SELECT name FROM v$datafile;
SELECT name FROM v$controlfile;
```

The prior creation attempt failed with `ORA-65016`. If `db_create_file_dest` is empty, determine the actual source/destination datafile paths before using `FILE_NAME_CONVERT`. Do not guess paths.

### SSH connection fails

- Confirm the EC2 public IP/DNS and `.pem` key path.
- Confirm the EC2 security group allows SSH (TCP 22) from your current public IP.
- Confirm the EC2 instance and Docker container are running.
- Keep the SSH tunnel terminal open while connected.
- Do not create a public inbound security-group rule for TCP 1521.

### Oracle is not available

From PowerShell, for local Docker:

```powershell
docker ps
docker inspect --format "Status={{.State.Status}} OOMKilled={{.State.OOMKilled}} ExitCode={{.State.ExitCode}}" trendy-commercial-banking-oracle
docker logs --tail 150 trendy-commercial-banking-oracle
```

For EC2, run the same Docker commands after connecting to the EC2 host over SSH. If `OOMKilled=true`, increase available memory before retrying setup.

## 6. Credential safety

- Never commit `.env`, `credentials.txt`, password files, or private SSH keys to Git.
- Keep local and EC2 credentials separate; do not assume the passwords match.
- Do not paste real passwords into notes, source code, screenshots, or chat.
- A password appeared in terminal output during prior troubleshooting. If it is still active, rotate it.
- Do not run `docker compose down -v` unless you intend to delete the database volume and all data stored in it.

## 7. Completion checklist

- [ ] Local Oracle instance is running.
- [ ] Local `TRENDYDB` exists and is `READ WRITE`.
- [ ] Local PL/SQL Developer profile connects as `TRENDY`.
- [ ] EC2 Oracle instance is running and `TRENDYDB` is `READ WRITE`.
- [ ] SSH tunnel works from Windows to EC2.
- [ ] EC2 PL/SQL Developer profile connects as `TRENDY`.
- [ ] Local and EC2 passwords are stored securely and are not committed to Git.
