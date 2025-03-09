FROM docker.jfrog.io/artifactory/artifactory-oss:latest

# Set environment variables
ENV ARTIFACTORY_HOME=/var/opt/jfrog/artifactory \
    JF_ROUTER_ENTRYPOINTS_EXTERNALPORT=8082

# Create necessary directories
USER root
RUN mkdir -p /var/opt/jfrog/artifactory/etc/artifactory \
    && chown -R artifactory:artifactory /var/opt/jfrog/artifactory

# Curl should already be installed in this image
# Switch back to artifactory user
USER artifactory

# Copy any custom configuration if needed
COPY artifactory.config.xml ${ARTIFACTORY_HOME}/etc/artifactory/

# Expose ports
EXPOSE 8081 8082

# Volume configuration
VOLUME ${ARTIFACTORY_HOME}

# The entrypoint and cmd are inherited from the base image 