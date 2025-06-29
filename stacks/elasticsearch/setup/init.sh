#!/bin/bash

# Function to check Elasticsearch cluster health
check_cluster_health() {
  local max_attempts=30
  local attempt=1
  local cert_path="config/certs/ca/ca.crt"
  local es_url="https://es01:9200/_cluster/health"

  echo "Checking Elasticsearch cluster health"
  until curl -s \
    --cacert "${cert_path}" \
    -u "elastic:${ELASTIC_PASSWORD}" \
    -H 'Content-Type: application/json' \
    "${es_url}" | grep -q '"status":"green"'; do
    if [ ${attempt} -ge ${max_attempts} ]; then
      echo "Error: Cluster health did not reach 'green' after ${max_attempts} attempts"
      exit 1
    fi
    echo "Cluster not yet healthy (attempt ${attempt}/${max_attempts}). Retrying in 10 seconds..."
    sleep 10
    ((attempt++))
  done
  echo "Cluster health is green"
}

# Function to create Elasticsearch role
create_es_role() {
  local role_name="$1"
  local payload="$2"
  local max_attempts=30
  local attempt=1
  local cert_path="config/certs/ca/ca.crt"
  local es_url="https://es01:9200/_security/role/${role_name}"

  # Check if role already exists
  echo "Checking if ${role_name} already exists"
  if curl -s \
    --cacert "${cert_path}" \
    -u "elastic:${ELASTIC_PASSWORD}" \
    -H 'Content-Type: application/json' \
    "${es_url}" | grep -q "\"${role_name}\""; then
    echo "${role_name} already exists, skipping creation"
    return 0
  fi

  echo "Creating ${role_name}"
  until curl -s -X POST \
    --cacert "${cert_path}" \
    -u "elastic:${ELASTIC_PASSWORD}" \
    -H 'Content-Type: application/json' \
    "${es_url}" \
    -d "${payload}" | grep -q '"created":\(true\|false\)'; do
    if [ ${attempt} -ge ${max_attempts} ]; then
      echo "Error: Failed to create or update ${role_name} after ${max_attempts} attempts"
      exit 1
    fi
    echo "${role_name} creation not yet successful (attempt ${attempt}/${max_attempts}). Retrying in 10 seconds..."
    sleep 10
    ((attempt++))
  done
  echo "${role_name} created or updated successfully"
}

# Function to create Elasticsearch user
create_es_user() {
  local user_name="$1"
  local payload="$2"
  local max_attempts=30
  local attempt=1
  local cert_path="config/certs/ca/ca.crt"
   local es_url="https://es01:9200/_security/user/${user_name}"

   # Check if user already exists
   echo "Checking if ${user_name} already exists"
   if curl -s \
     --cacert "${cert_path}" \
     -u "elastic:${ELASTIC_PASSWORD}" \
     -H 'Content-Type: application/json' \
     "${es_url}" | grep -q "\"${user_name}\""; then
     echo "${user_name} already exists, skipping creation"
     return 0
   fi

   echo "Creating ${user_name}"
   until curl -s -X POST \
     --cacert "${cert_path}" \
     -u "elastic:${ELASTIC_PASSWORD}" \
     -H 'Content-Type: application/json' \
     "${es_url}" \
     -d "${payload}" | grep -q '{"created":true}'; do
     if [ ${attempt} -ge ${max_attempts} ]; then
       echo "Error: Failed to create ${user_name} after ${max_attempts} attempts"
       exit 1
     fi
     echo "${user_name} creation not yet successful (attempt ${attempt}/${max_attempts}). Retrying in 10 seconds..."
     sleep 10
     ((attempt++))
   done
   echo "${user_name} created successfully"
 }

 # Function to set Elasticsearch user password
 set_es_user_password() {
   local user_name="$1"
   local payload="$2"
   local max_attempts=30
   local attempt=1
   local cert_path="config/certs/ca/ca.crt"
   local es_url="https://es01:9200/_security/user/${user_name}/_password"

   echo "Setting password for ${user_name}"
   until curl -s -X POST \
     --cacert "${cert_path}" \
     -u "elastic:${ELASTIC_PASSWORD}" \
     -H 'Content-Type: application/json' \
     "${es_url}" \
     -d "${payload}" | grep -q '^{}'; do
     if [ ${attempt} -ge ${max_attempts} ]; then
       echo "Error: Failed to set password for ${user_name} after ${max_attempts} attempts"
       exit 1
     fi
     echo "${user_name} password update not yet successful (attempt ${attempt}/${max_attempts}). Retrying in 10 seconds..."
     sleep 10
     ((attempt++))
   done
   echo "${user_name} password set successfully"
 }

 # Check required environment variables
 for var in ELASTIC_PASSWORD KIBANA_PASSWORD HEALTH_CHECK_PASSWORD; do
   if [ -z "${var}" ]; then
     echo "Error: Set the $var environment variable in the .env file"
     exit 1
   fi
 done

 # Create CA if it doesn't exist
 if [ ! -f config/certs/ca.zip ]; then
   echo "Creating CA"
   bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip
   unzip config/certs/ca.zip -d config/certs
 fi

 # Create certificates if they don't exist
 if [ ! -f config/certs/certs.zip ]; then
   echo "Creating certs"
   cat > config/certs/instances.yml <<EOF
 instances:
   - name: es01
     dns:
       - es01
       - localhost
     ip:
       - 127.0.0.1
   - name: es02
     dns:
       - es02
       - localhost
     ip:
       - 127.0.0.1
   - name: es03
     dns:
       - es03
       - localhost
     ip:
       - 127.0.0.1
EOF
   bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip \
     --in config/certs/instances.yml \
     --ca-cert config/certs/ca/ca.crt \
     --ca-key config/certs/ca/ca.key
   unzip config/certs/certs.zip -d config/certs
 fi

 # Set file permissions
 echo "Setting file permissions"
 chown -R root:root config/certs
 find . -type d -exec chmod 750 {} \;
 find . -type f -exec chmod 640 {} \;

 # Wait for cluster health to be green
 check_cluster_health

 # Create health_check_role using the function
 create_es_role "health_check_role" '{
   "cluster": ["monitor"],
   "indices": [
     {
       "names": ["*"],
       "privileges": ["monitor"]
     }
   ]
 }'

 # Create health_check_user using the function
 create_es_user "health_check_user" '{
   "password": "'"${HEALTH_CHECK_PASSWORD}"'",
   "roles": ["health_check_role"],
   "full_name": "Health Check User",
   "email": "health_check_user@example.com"
 }'

 # Set kibana_system password using the function
 set_es_user_password "kibana_system" '{"password":"'"${KIBANA_PASSWORD}"'"}'

 echo "All done!"