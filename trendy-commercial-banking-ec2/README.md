# Trendy Commercial Banking — Oracle on AWS EC2

This is a ready-to-run Docker Compose deployment for a fresh Ubuntu 22.04/24.04 EC2 instance.

## Naming and version notes

- Project/Compose name: `trendy-commercial-banking`
- Container: `trendy-commercial-banking-oracle`
- Image: Oracle Database Free (`container-registry.oracle.com/database/free:latest`)
- Default PDB/service: `FREEPDB1`
- Application schema/user created by the script: `TRENDY`

The Oracle Free image controls the internal CDB/PDB names during first initialization. This package deliberately does **not** claim that changing the Compose project or schema name renames Oracle's internal database. If you require an actual CDB name such as `TRENDY`, verify the supported initialization variables and Oracle image documentation for the exact image release before changing initialization behavior.

The `latest` tag can move to a different release. Pin a tested version/digest after validating the deployment. Oracle Container Registry may require login and acceptance of the image terms.

## Deploy on a fresh EC2 Ubuntu instance

1. Security group: allow SSH TCP 22 only from your own public IP `/32`. Do not add inbound TCP 1521.
2. Ensure the instance has sufficient memory and EBS space. 4 GiB RAM is a reasonable starting point for a small development lab, but workloads may require more.
3. Upload and extract this folder on EC2.
4. Run:

```bash
chmod +x deploy.sh
./deploy.sh
```

The script installs Docker/Compose if missing, generates private passwords, starts Oracle, waits for SQL readiness, and creates the `TRENDY` schema in `FREEPDB1`.

If the Oracle image pull fails, authenticate to Oracle Container Registry and accept the image terms, then retry `docker compose pull`.

## Connect from Windows

Keep the following SSH tunnel open in PowerShell:

```powershell
ssh -i "C:\path\to\key.pem" -N -L 1521:127.0.0.1:1521 ubuntu@EC2_PUBLIC_IP
```

SQL Developer settings:
- Host: `127.0.0.1`
- Port: `1521`
- Connection type: Service name
- Service: `FREEPDB1`
- Username: `TRENDY`
- Password: see `credentials.txt`

If local port 1521 is busy, use `-L 11521:127.0.0.1:1521` and connect locally to port 11521.

## Operations

```bash
docker compose ps
docker logs --tail 100 trendy-commercial-banking-oracle
docker logs -f trendy-commercial-banking-oracle
docker compose restart oracle
docker compose stop
docker compose start
```

Data is persisted in the `oracle-data` named volume. Do not run `docker compose down -v` unless you intend to delete the database volume.

## Security

- Keep `.env`, `.app_password`, and `credentials.txt` private. They are excluded by `.gitignore`.
- Port 1521 is bound to EC2 loopback only; use SSH tunneling.
- A Docker volume is not a backup. Make Oracle-aware backups and copy them to separate durable storage.
