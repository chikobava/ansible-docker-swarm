# Use official Elasticsearch base image
FROM docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}

# Set working directory
WORKDIR /usr/share/elasticsearch

# Copy the initialization script
COPY init.sh /usr/share/elasticsearch/init.sh

# Verify script exists and set execute permissions
RUN test -f /usr/share/elasticsearch/init.sh || (echo "Error: init.sh not found" && exit 1) \
    && chmod +x /usr/share/elasticsearch/init.sh

# Set the entrypoint to the initialization script
ENTRYPOINT ["/usr/share/elasticsearch/init.sh"]