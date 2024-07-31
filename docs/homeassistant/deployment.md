# Deployment

## Setup

```bash
mkdir homeassistant
mkdir homeassistant/config
```

## Deploy Containers

```bash
docker-compose up 
```

## Update Containers

The following commands will update the containers

```bash
docker-compose build
docker-compose down
docker-compose up -d --force-recreate
docker rmi $(docker images -f "dangling=true" -q) -f
```
