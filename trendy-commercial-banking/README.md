# Trendy Commercial Banking — Oracle Database Free with TRENDYDB

This package targets a fresh Ubuntu 22.04/24.04 EC2 development lab.

It starts Oracle Database Free, then creates a separate pluggable database (PDB) named `TRENDYDB` and an application schema/user named `TRENDY` inside it.

## Deploy

1. In the EC2 security group, allow SSH TCP 22 from your own public IP `/32`. Do not expose TCP 1521 publicly.
2. Use an instance with enough memory/storage for Oracle. 4 GiB RAM is a practical starting point for a small lab, but workloads may need more.
3. Upload and extract this folder to EC2.
4. Run:

```bash
chmod +x deploy.sh
./deploy.sh
```

Oracle Container Registry may require you to sign in and accept image terms before `docker compose pull` succeeds.

## Connect from Windows

Start this SSH tunnel and leave it open:

```powershell
ssh -i "C:\path\to\key.pem" -N -L 1521:127.0.0.1:1521 ubuntu@EC2_PUBLIC_IP
```

SQL Developer:
- Host: `127.0.0.1`
- Port: `1521`
- Connection type: Service name
- Service name: `TRENDYDB`
- Username: `TRENDY`
- Password: `credentials.txt`

## Operations

```bash
docker compose ps
docker logs --tail 100 trendy-commercial-banking-oracle
docker logs -f trendy-commercial-banking-oracle
docker compose restart oracle
```

Database files are stored in the `oracle-data` Docker volume. Do not run `docker compose down -v` unless you intend to delete the database volume. The Docker volume is not a backup; take Oracle-aware backups to separate storage.

## Important

This script is for a new lab. Creating a new PDB consumes additional disk and memory. The script does not rename the default `FREEPDB1`; it creates `TRENDYDB` alongside it. Pin a tested image version after validating the release rather than relying on `latest` indefinitely.
