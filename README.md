# ELK-DOCKER (Elasticsearch + Logstash + Kibana + Beats)

Stack ELK 8.x prête a l'emploi en Docker Compose (WSL2/Linux), avec Filebeat + Metricbeat, et Packetbeat en option.

## Prerequis
- Docker + Docker Compose
- 4 Go de RAM minimum (WSL2 recommande 4 a 6 Go)
- Ports libres : 9200 (Elasticsearch), 5601 (Kibana), 5044 (Logstash Beats)

## Structure
```
ELK-DOCKER/
  docker/
    .env
    docker-compose.yml
    elasticsearch/elasticsearch.yml
    kibana/kibana.yml
    logstash/pipeline/main.conf
    filebeat/filebeat.yml
    filebeat/modules.d/system.yml
    metricbeat/metricbeat.yml
    metricbeat/modules.d/system.yml
    packetbeat/packetbeat.yml
    logs/
  scripts/
    generate_logs.sh
```

## Lancer la stack (ordre conseille)
```bash
cd ELK-DOCKER/docker

# 1) Demarrer ELK + beats de base
docker compose up -d

# 2) Verifier l'etat
docker compose ps

# 3) Acceder a Kibana
# http://localhost:5601
```

## Verifications rapides
```bash
# Elasticsearch
curl -s http://localhost:9200 | head -n 5

# Kibana
curl -s http://localhost:5601/api/status | head -n 5
```

## Generer des logs de demo
```bash
cd ELK-DOCKER
./scripts/generate_logs.sh
```

Les logs sont ecrits dans `docker/logs/` et sont lus par Logstash + Filebeat.

## Packetbeat (optionnel)
Packetbeat n'est pas lance par defaut. Pour l'activer :
```bash
cd ELK-DOCKER/docker
docker compose --profile packetbeat up -d
```

## Arreter / supprimer
```bash
cd ELK-DOCKER/docker

# Stopper
docker compose down

# Stopper et tout nettoyer (volumes ES inclus)
docker compose down -v
```

## Notes
- La pile des services est configuree en mode single-node.
- Le `docker-compose.yml` utilise `restart: unless-stopped` pour relancer apres reboot.
- La configuration se fait dans `docker/.env` (version, ports, heap).

## Depannage rapide
```bash
# Voir les logs d'un service
docker logs -f kibana

# Re-demarrer un service
docker compose restart logstash
```
