# Elasticsearch Cluster on Docker Swarm with HAProxy
This project demonstrates how to run a secure, production-ready **Elasticsearch cluster** (3 nodes) on **Docker Swarm**, fronted by **HAProxy** for stable routing, SSL termination, and health checks.  
It also bootstraps certificates, users, and roles required for cluster health monitoring and Kibana access.

## Architecture
- **Elasticsearch**: 3 dedicated nodes (`es01`, `es02`, `es03`), each pinned to a Swarm node via placement constraints.
- **Kibana**: Web UI for Elasticsearch.
- **Setup service**: Initializes CA + certificates, sets passwords, creates roles/users, and waits until the cluster is green.
- **HAProxy**: Provides a single stable entrypoint (`:9200`) to the cluster with SSL, health checks, and load balancing.
- **NFS Volumes**: Shared persistent storage for data, certs, and configs.

Clients → HAProxy (9200) → es01/es02/es03

## Prerequisites
- Docker Swarm cluster with at least **3 worker nodes**.
- Node labels set to pin Elasticsearch instances:

```bash
docker node update --label-add es_node=1 <node1>
docker node update --label-add es_node=2 <node2>
docker node update --label-add es_node=3 <node3>
```

* NFS share mounted on all nodes at `/mnt/nfs/docker/volumes/....`
* `.env` file with required secrets:

```
STACK_VERSION=8.15.0
CLUSTER_NAME=es-docker-swarm
LICENSE=basic
ELASTIC_PASSWORD=changeme
KIBANA_PASSWORD=changeme
HEALTH_CHECK_PASSWORD=changeme
KIBANA_PORT=5601
```

## Deployment
1. Clone this repository and adjust paths in elasticsearch.yml to match your NFS mountpoints.
2. Deploy the stack:
```bash
docker stack deploy -c elasticsearch.yml elastic
```
3. Wait for the setup to complete - it will:
    * Generate CA and certs if missing.
    * Distribute certs into Elasticsearch and HAProxy.
    * Set `elastic`, `kibana_system`, and `health_check_user` credentials.
    * Verify cluster health is green.
4. Access services:
    * Elasticsearch via HAProxy: https://<any-node>:9200    
    * Kibana: http://<any-node>:5601

## File Overview
* **elasticsearch.yml** \
    Docker Compose v3.7 stack file defining all services. \
    Highlights:
    * setup: initialization container.
    * es01/es02/es03: cluster nodes with pinned placement.
    * kibana: dashboard UI.
    * haproxy: reverse proxy and load balancer.
* **setup/Dockerfile** \
    Wraps the official Elasticsearch image with a custom `entrypoint.sh` that handles cluster bootstrap logic.
* **setup/entrypoint.sh** \
    Responsibilities:
    * Generate CA and node certificates.
    * Set file permissions.
    * Create health_check_role and health_check_user.
    * Update kibana_system password.
    * Wait until cluster is healthy before exiting.
* **haproxy/entrypoint.sh** \
  Responsibilities:
    * Validate HEALTH_CHECK_PASSWORD.
    * Wait until cluster is green.
    * Generate haproxy.cfg dynamically with SSL and health checks.
    * Start HAProxy.

## HAProxy Highlights
```
frontend elasticsearch
    bind *:9200 ssl crt /home/haproxy/cluster.pem
    default_backend elasticsearch_nodes

backend elasticsearch_nodes
    balance roundrobin
    option httpchk
    http-check send meth GET uri /_cluster/health ver HTTP/1.1 \
        hdr Authorization "Basic ${AUTH_TOKEN}"
    http-check expect status 200
    server es01 es01:9200 check ssl verify required ca-file /home/haproxy/ca.crt
    server es02 es02:9200 check ssl verify required ca-file /home/haproxy/ca.crt
    server es03 es03:9200 check ssl verify required ca-file /home/haproxy/ca.crt
```
This ensures clients always hit a helathy Elasticsearch node and that SSL trust is enforced.
## Volumes Layout
* `/mnt/nfs/docker/volumes/escerts` → certificates & keys
* `/mnt/nfs/docker/volumes/esdata0X` → Elasticsearch data
* `/mnt/nfs/docker/volumes/kibanadata` → Kibana data
* `/mnt/nfs/docker/volumes/kibanaconfig` → custom Kibana config
* `/mnt/nfs/docker/volumes/elastic_stack_haproxy` → HAProxy config & certs
## Notes
* Default memory limits are set to 2G per Elasticsearch node. Adjust for your cluster size.
* This stack is configured with SSL everywhere (HTTP + transport).
* The setup container is one-shot: it initializes and exits once the cluster is healthy.
    * For production, consider:
    * External secret management (Vault, Docker secrets).
    * TLS SANs with real DNS names.
    * Adjusting HAProxy balance strategy.
## References
* [Elasticsearch Docker Docs](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-docker)
* [HAProxy Configuration Manual](https://www.haproxy.com/documentation/haproxy-configuration-manual/latest/)