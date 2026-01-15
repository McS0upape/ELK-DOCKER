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
  kibana/
    siem_security_dashboard.ndjson
  scripts/
    generate_logs.sh
    generate_scenario.sh
    import_security_dashboard.sh
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

## Monitoring (WSL + Docker + Windows)
### WSL (host) + conteneurs Docker
Metricbeat est deja configure pour collecter :
- l'hote WSL (CPU, RAM, disque, process)
- les conteneurs Docker (cpu, memoire, reseau, etc.)

Apres modification, relance Metricbeat :
```bash
cd ELK-DOCKER/docker
docker compose up -d metricbeat
```

Dans Kibana :
- Cree un Data View `metricbeat-*`
- Va dans Discover ou Dashboard pour filtrer par `host.os.type` ou `container.name`

### Windows (machine distante)
Installe Metricbeat sur Windows et envoie vers Elasticsearch :

1) Telechargement :
- https://www.elastic.co/downloads/beats/metricbeat

2) Exemple de `metricbeat.yml` (minimal) :
```yaml
metricbeat.modules:
  - module: system
    metricsets:
      - cpu
      - memory
      - network
      - process
      - process_summary
      - filesystem
      - fsstat
      - uptime
    period: 10s

output.elasticsearch:
  hosts: ["http://ELK_HOST:9200"]
```

Remplace `ELK_HOST` par l'IP de ta machine ELK.

3) Lancer (PowerShell admin) :
```powershell
cd "C:\\Program Files\\Metricbeat"
.\metricbeat.exe -e
```

Dans Kibana, tu verras `host.os.type: windows` et `host.name` de la machine.

## Generer des logs de demo
```bash
cd ELK-DOCKER
./scripts/generate_logs.sh
```

Les logs sont ecrits dans `docker/logs/` et sont lus par Logstash + Filebeat.
Le script simule plusieurs machines, OS et reseaux.

Format des fichiers :
`<os>_<host>_<ip>_<reseau>_<type>.log`

Exemples :
- `linux_web01_10.0.10.21_corp_syslog.log`
- `unix_solaris01_172.16.20.11_dmz_auth.log`
- `macos_mbp01_192.168.50.42_lab_app.log`
- `linux_web01_10.0.10.21_corp_apache.log`

Ces infos sont automatiquement mappees dans Elasticsearch :
- `host.name`, `host.ip`, `host.os.type`
- `network.name`
- `log_type`

Verification rapide dans Kibana :
- Data Views : `logs-*` et `filebeat-*`
- Discover : filtre `log_type:apache` ou `log_type:syslog`

Pour relancer une generation de test :
```bash
./scripts/generate_logs.sh
```

## Scenarios (attaques) + tests recurents
Le script simule bruteforce SSH et sudo (privilege escalation) dans `docker/logs/`.

Execution manuelle (plusieurs fois si besoin) :
```bash
cd ELK-DOCKER
./scripts/generate_scenario.sh
```

Cron toutes les 10 minutes (optionnel) :
```bash
crontab -l 2>/dev/null | grep -v 'elk-scenario' > /tmp/cron.tmp
echo "*/10 * * * * /home/mcsoupape/ELK-DOCKER/scripts/generate_scenario.sh >/tmp/elk-scenario.log 2>&1 # elk-scenario" >> /tmp/cron.tmp
crontab /tmp/cron.tmp
```

## Ajouter Winlogbeat (Windows)
Objectif : envoyer les logs Windows vers Logstash (port 5044).

1) Installer Winlogbeat (ZIP) :
- https://www.elastic.co/downloads/beats/winlogbeat

2) Modifier `winlogbeat.yml` (exemple minimal) :
```yaml
winlogbeat.event_logs:
  - name: Application
  - name: System
  - name: Security

output.logstash:
  hosts: ["ELK_HOST:5044"]
```

Remplace `ELK_HOST` par l'IP de ta machine ELK (WSL2 ou VM).

3) Lancer Winlogbeat (PowerShell admin) :
```powershell
cd C:\Program Files\Winlogbeat
.\winlogbeat.exe -e
```

Verification : dans Kibana, creer `winlogbeat-*` et verifier les events.

## Importer le dashboard securite (Kibana)
Un dashboard Lens est fourni (Security overview).

```bash
cd ELK-DOCKER
./scripts/import_security_dashboard.sh
```

Si besoin : Stack Management -> Saved Objects -> Import
Fichier : `kibana/siem_security_dashboard.ndjson`

## Regles Kibana (alertes)
Regles creees pour la demo :
- Brute force SSH (>=6 fails / 5m)
- Privilege escalation sudo (any) / 5m
- Windows PowerShell Execution (4103/4104)
- Windows PowerShell Suspicious Keywords (4104)
- Windows Failed Logons (>=5 / 5m)
- Windows Account Lockout (4740)
- Windows Privileged Logon (4672)
- Windows RDP Logon (4624 LogonType 10)
- Windows New Local User (4720)
- Windows Service Installed (7045)
- Windows Admin Logon (4624)

## Data Views utiles (Kibana)
- `logs-*` (pipeline Logstash)
- `filebeat-*`
- `metricbeat-*`
- `winlogbeat-*`
- `stack-alerts` : `.internal.alerts-stack.alerts-*` (activer "Include hidden/system indices")
- `kibana-event-log` : `.kibana-event-log-*` ou `.ds-.kibana-event-log-ds-*` (activer "Include hidden/system indices")

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
