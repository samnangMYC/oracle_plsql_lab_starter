# Trendy Commercial Banking — Oracle Database Free

This guide covers three deployment options for the **Trendy Commercial Banking** Oracle database:

1. **Local Windows** — Docker Desktop (recommended: run the deployment script from WSL2 Ubuntu).
2. **Local Ubuntu** — Docker Engine and Docker Compose.
3. **AWS EC2 Ubuntu** — Docker Engine and Docker Compose, accessed securely through an SSH tunnel.

## 1. Target configuration

| Setting | Value |
|---|---|
| Oracle image | `container-registry.oracle.com/database/free:latest` |
| Container name | `trendy-commercial-banking-oracle` |
| Docker Compose project | `trendy-commercial-banking` |
| Container Database (CDB) | `FREE` (default image CDB; confirm against the image release) |
| Pluggable Database (PDB) / service | `TRENDYDB` |
| Application schema / username | `TRENDY` |
| Oracle listener port | `1521` |
| Host port binding | `127.0.0.1:1521` |
| Persistent Docker volume | `oracle-data` |

**Important:** `TRENDYDB` is a new PDB created alongside the image's default `FREEPDB1`; it does not rename or replace `FREEPDB1`.

## 2. Requirements

- Docker with the Compose v2 plugin (`docker compose version`).
- Enough RAM and free disk space for Oracle Database Free.
  - **2 GiB RAM is not a reliable target**; the Oracle process may be killed by the Linux OOM killer during startup.
  - Use at least **4 GiB RAM** for a small development lab; 8 GiB is preferable if available.
- Network access to Oracle Container Registry. You may need to sign in to the registry and accept the image terms before pulling the image.
- A SQL client such as Oracle SQL Developer, if you want to inspect the database.

## 3. Get the project files

Clone your repository, or copy the deployment files into a project folder. The folder should contain:

```text
trendy-commercial-banking/
├── compose.yaml
├── deploy.sh
├── .env.example
├── .gitignore
├── README.md
└── sql/
    └── verify.sql
```

Do not commit `.env`, `credentials.txt`, `.app_password`, or `.pdb_admin_password`. These files contain secrets.

---

## 4. Local installation on Windows

### Option A — Windows with Docker Desktop and WSL2 (recommended)

1. Install **Docker Desktop for Windows** and enable the WSL2 backend.
2. Install or enable an Ubuntu distribution in WSL2.
3. Ensure Docker Desktop is running and that WSL integration is enabled for your Ubuntu distribution.
4. Open the Ubuntu (WSL) terminal and clone the repository:

   ```bash
   git clone <YOUR_GITHUB_REPOSITORY_URL>
   cd <YOUR_REPOSITORY_FOLDER>
   ```

5. Run the deployment script from the Ubuntu terminal:

   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

   The script checks/installs Docker on Ubuntu, creates a protected `.env` if missing, starts Oracle, creates the `TRENDYDB` PDB and the `TRENDY` schema, and writes private connection details to `credentials.txt`.

   If Docker Desktop provides the Docker daemon to WSL, do not install or start a second Docker daemon inside WSL unless you specifically intend to manage one.

6. Check the container and logs:

   ```bash
   docker compose ps
   docker logs --tail 100 trendy-commercial-banking-oracle
   ```

7. Connect from Windows SQL Developer using:
   - Host: `127.0.0.1`
   - Port: `1521`
   - Connection type: **Service name**
   - Service name: `TRENDYDB`
   - Username: `TRENDY`
   - Password: read the private `credentials.txt` created by the script.

### Option B — Native Windows PowerShell (without running `deploy.sh`)

The Bash deployment script is intended for Ubuntu. For native PowerShell, use Docker Desktop and run the following from the folder containing `compose.yaml`.

1. Create `.env` with exactly one setting line (use a strong password):

   ```powershell
   Copy-Item .env.example .env
   notepad .env
   ```

   Ensure the file contains a valid line such as `ORACLE_PWD=YourStrongPasswordHere` and no extra text. Do not share or commit it.

2. Start the Oracle container:

   ```powershell
   docker compose pull
   docker compose up -d
   docker compose ps
   docker logs -f trendy-commercial-banking-oracle
   ```

3. Wait for Oracle initialization to finish before opening SQL*Plus. Then enter the container:

   ```powershell
   docker exec -it trendy-commercial-banking-oracle bash
   sqlplus / as sysdba
   ```

4. At the SQL*Plus prompt, create the PDB and application user. Replace the example password values with strong passwords; passwords below are examples only.

   ```sql
   CREATE PLUGGABLE DATABASE TRENDYDB
     ADMIN USER PDBADMIN IDENTIFIED BY "ReplaceWithPdbAdminPassword_123"
     ROLES=(DBA);

   ALTER PLUGGABLE DATABASE TRENDYDB OPEN;
   ALTER PLUGGABLE DATABASE TRENDYDB SAVE STATE;

   ALTER SESSION SET CONTAINER = TRENDYDB;

   CREATE USER TRENDY IDENTIFIED BY "ReplaceWithAppPassword_123";
   GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
         CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE TO TRENDY;
   ALTER USER TRENDY QUOTA UNLIMITED ON USERS;

   SELECT SYS_CONTEXT('USERENV','CON_NAME') AS current_pdb FROM dual;
   EXIT;
   ```

   If the PDB already exists, do not run `CREATE PLUGGABLE DATABASE` again. Check it first with `SELECT name, open_mode FROM v$pdbs;`.

5. Connect SQL Developer with service name `TRENDYDB`, username `TRENDY`, and the password you chose.

**Native PowerShell note:** this manual path does not generate `credentials.txt`; store your passwords in a secure password manager. For repeatable setup, use Option A and `deploy.sh`.

---

## 5. Local installation on Ubuntu

These commands target a supported Ubuntu machine with `apt`.

1. Install Git and Docker/Compose if needed:

   ```bash
   sudo apt-get update
   sudo apt-get install -y git docker.io docker-compose-v2 openssl
   sudo systemctl enable --now docker
   ```

2. Clone the repository:

   ```bash
   git clone <YOUR_GITHUB_REPOSITORY_URL>
   cd <YOUR_REPOSITORY_FOLDER>
   ```

3. Run the deployment script:

   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

   The script may use `sudo` for Docker installation and service startup. If your user receives a Docker permission error, either run Docker commands with `sudo` or add your user to the `docker` group and sign out/in again. Membership in the `docker` group grants root-equivalent privileges.

4. Verify:

   ```bash
   docker compose ps
   docker exec -it trendy-commercial-banking-oracle bash -lc \
     'echo "SELECT name, open_mode FROM v\\$pdbs;" | sqlplus -s / as sysdba'
   ```

5. Connect using `127.0.0.1:1521`, service `TRENDYDB`, username `TRENDY`, and the password in the private `credentials.txt`.

---

## 6. Deploy on AWS EC2 (Ubuntu)

### 6.1 Prepare the EC2 instance

- Use an Ubuntu EC2 instance with **at least 4 GiB RAM** for a small lab; 8 GiB is preferable. A 2 GiB instance has already proven insufficient for this setup because Oracle was OOM-killed during startup.
- Use an EBS-backed root volume with sufficient free space.
- In the EC2 security group, allow **SSH TCP 22 only from your own public IP** (or your organization's approved source).
- **Do not add an inbound rule for TCP 1521.** Compose binds Oracle to `127.0.0.1` on the EC2 host; connect through SSH tunneling.

### 6.2 Connect from MobaXterm

Create an SSH session using:
- Remote host: your EC2 public IPv4/DNS
- Username: `ubuntu`
- Private key: your EC2 `.pem` key

Or use an SSH terminal:

```bash
ssh -i /path/to/key.pem ubuntu@EC2_PUBLIC_IP
```

### 6.3 Clone and deploy

After connecting to EC2:

```bash
sudo apt-get update
sudo apt-get install -y git
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd <YOUR_REPOSITORY_FOLDER>
chmod +x deploy.sh
./deploy.sh
```

The deployment script installs Docker and Compose if needed, creates a protected `.env`, starts Oracle, creates `TRENDYDB`, creates the `TRENDY` schema, and writes `credentials.txt`.

**Important:** use the deployment script from the current repository version that creates `TRENDYDB`. If your logs say it is only creating `TRENDY` inside `FREEPDB1`, stop and update the repository files before continuing.

### 6.4 Verify the database on EC2

```bash
docker compose ps
docker inspect --format 'Status={{.State.Status}} ExitCode={{.State.ExitCode}} OOMKilled={{.State.OOMKilled}}' trendy-commercial-banking-oracle
docker logs --tail 150 trendy-commercial-banking-oracle
```

Verify PDB state:

```bash
docker exec -it trendy-commercial-banking-oracle bash -lc 'sqlplus / as sysdba'
```

Then run:

```sql
SELECT status FROM v$instance;
SELECT name, open_mode FROM v$pdbs;
ALTER SESSION SET CONTAINER = TRENDYDB;
SELECT SYS_CONTEXT('USERENV','CON_NAME') AS current_pdb FROM dual;
EXIT;
```

Expected: the instance is `OPEN`, and `TRENDYDB` is `READ WRITE`.

If `OOMKilled=true`, increase EC2 memory before retrying. Do not delete the Docker volume. After resizing, check `free -h`, then use `docker compose restart oracle` and inspect the logs.

### 6.5 Connect from your Windows PC through an SSH tunnel

Keep the SSH tunnel open while using SQL Developer. Run this in Windows PowerShell, replacing the key path and public IP:

```powershell
ssh -i "C:\path\to\key.pem" -N -L 1521:127.0.0.1:1521 ubuntu@EC2_PUBLIC_IP
```

In SQL Developer, use:
- Host: `127.0.0.1`
- Port: `1521`
- Connection type: **Service name**
- Service name: `TRENDYDB`
- Username: `TRENDY`
- Password: the application password in EC2's private `credentials.txt`

If local port `1521` is already in use, use a different local port, for example `11521`:

```powershell
ssh -i "C:\path\to\key.pem" -N -L 11521:127.0.0.1:1521 ubuntu@EC2_PUBLIC_IP
```

Then configure SQL Developer with host `127.0.0.1` and port `11521`; the remote destination remains `127.0.0.1:1521`.

---

## 7. Useful operations

Run these commands from the project directory containing `compose.yaml`.

```bash
# Status
docker compose ps

# Recent logs
docker logs --tail 100 trendy-commercial-banking-oracle

# Follow logs
docker logs -f trendy-commercial-banking-oracle

# Restart Oracle
docker compose restart oracle

# Stop the container but keep database files
docker compose down

# Start it again
docker compose up -d
```

### Persistence and destructive commands

- Database files are stored in the Docker volume `oracle-data`.
- `docker compose down` removes the container/network but normally keeps the named volume.
- **Do not run `docker compose down -v`** unless you intentionally want to delete the database volume and all data stored in it.
- A Docker volume is not a backup. Keep Oracle-aware backups on separate storage.
- Keep `.env`, `credentials.txt`, `.app_password`, and `.pdb_admin_password` private. Never commit them to Git.

## 8. Troubleshooting

### Oracle exits or `ORA-01034: Oracle instance is not available`

Check:

```bash
docker inspect --format 'Status={{.State.Status}} OOMKilled={{.State.OOMKilled}} ExitCode={{.State.ExitCode}}' trendy-commercial-banking-oracle
free -h
docker logs --tail 200 trendy-commercial-banking-oracle
```

If `OOMKilled=true`, use an instance with more RAM. Do not repeatedly rerun PDB/user creation while the Oracle instance is not open.

### `.env` parse errors

`.env` must be plain `KEY=value` syntax, for example:

```dotenv
ORACLE_PWD=your_strong_password_without_spaces
```

Do not paste shell commands or a password on a separate line. Keep the file private (`chmod 600 .env` on Linux).

### PDB or service not found

Connect as SYSDBA inside the container and check:

```sql
SELECT name, open_mode FROM v$pdbs;
```

If `TRENDYDB` is missing, use the deployment script from the current project version or follow the manual PDB creation steps in the Windows section. Do not create it a second time if it already exists.

### Registry image pull fails

Sign in to Oracle Container Registry and accept the terms for the Oracle Database Free image, then retry:

```bash
docker compose pull
```

## 9. Security checklist

- [ ] EC2 security group exposes SSH only to approved source IPs.
- [ ] No public inbound rule for port `1521`.
- [ ] Oracle is published only on `127.0.0.1:1521`.
- [ ] Password files are excluded from Git.
- [ ] EC2 has enough memory and disk space.
- [ ] Backups are stored separately from the Docker volume.
