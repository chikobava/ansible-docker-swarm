#!/bin/bash

# Base64 encode the credentials
AUTH_TOKEN=$(echo -n "health_check_user:${HEALTH_CHECK_PASSWORD}" | base64)

# Health check function, almost identical to check_cluster_health in setup/entrypoint
# but there is a catch: the cert path is different!
check_cluster_health() {
  local max_attempts=30
  local attempt=1
  local cert_path="/home/haproxy/ca.crt"
  local es_url="https://es01:9200/_cluster/health"

  echo "Checking Elasticsearch cluster health"

  while [ $attempt -le $max_attempts ]; do
    echo "Attempt ${attempt}/${max_attempts}..."

    # Use -w for status code, and capture both output and code
    response=$(curl -s -w "\n%{http_code}" \
      --cacert "${cert_path}" \
      -u "health_check_user:${HEALTH_CHECK_PASSWORD}" \
      -H 'Content-Type: application/json' \
      "${es_url}")

    # Separate JSON body and status code
    body=$(echo "$response" | sed '$d')
    status_code=$(echo "$response" | tail -n1)

    # Print raw body for visibility
    echo "Response body: $body"
    echo "HTTP status: $status_code"

    # If curl failed completely
    if [ -z "$status_code" ]; then
      echo "Curl failed — no HTTP response received"
    fi

    # Check for green status
    if echo "$body" | grep -q '"status":"green"'; then
      echo "Cluster health is green"
      return 0
    fi

    echo "Cluster not yet healthy. Retrying in 30 seconds..."
    sleep 30
    ((attempt++))
  done

  echo "Error: Cluster health did not reach 'green' after ${max_attempts} attempts"
  return 1
}

if [ -z "${HEALTH_CHECK_PASSWORD}" ]; then
  echo "Error: Set the HEALTH_CHECK_PASSWORD environment variable in the .env file"
  exit 1
fi

check_cluster_health

# Generate the haproxy.cfg dynamically
cat > /home/haproxy/haproxy.cfg <<EOF
global
    log stdout format raw local0
    maxconn 4096

defaults
    log      global
    mode     http
    option   httplog
    option   dontlognull
    retries 3
    timeout connect 50000
    timeout client 50000
    timeout server 120000

frontend elasticsearch
    bind *:9200 ssl crt /home/haproxy/cluster.pem
    default_backend elasticsearch_nodes

backend elasticsearch_nodes
    balance roundrobin
    option httpchk
    http-check send meth GET uri /_cluster/health ver HTTP/1.1 hdr Authorization "Basic ${AUTH_TOKEN}"
    http-check expect status 200
    server es01 es01:9200 check ssl verify required ca-file /home/haproxy/ca.crt
    server es02 es02:9200 check ssl verify required ca-file /home/haproxy/ca.crt
    server es03 es03:9200 check ssl verify required ca-file /home/haproxy/ca.crt
EOF

# Start HAProxy
exec haproxy -f /home/haproxy/haproxy.cfg