# Docker Compose

> [!TIP]
> Pin images to a tag in the docker compose file. This prevents surprise failures due to updates.
> When new versions are available, update the docker-compose file and use the process below to update containers

## Update All Containers

The following commands with the existing Docker-Compose file will update all of the containers.

```bash
docker-compose pull
docker-compose up --force-recreate --build -d
docker image prune -f
```
