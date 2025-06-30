# Use official Elasticsearch base image
FROM docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}

# Set working directory
WORKDIR /usr/share/elasticsearch

# Copy the initialization script
COPY entrypoint.sh /usr/share/elasticsearch/entrypoint.sh

# Verify script exists and set execute permissions
RUN test -f /usr/share/elasticsearch/entrypoint.sh || (echo "Error: entrypoint.sh not found" && exit 1) \
    && chmod +x /usr/share/elasticsearch/entrypoint.sh

# Set the entrypoint to the initialization script
ENTRYPOINT ["/usr/share/elasticsearch/entrypoint.sh"]
