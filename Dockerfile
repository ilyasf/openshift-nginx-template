# Step 1: Build the project
FROM node:20 as build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# Step 2: Create the Nginx image
FROM openshift/origin-cli:v3.11.0

ENV NGINX_VERSION=1.15.6-1.el7_4.ngx

# Configure CentOS repositories
COPY ./nginx/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
COPY ./nginx/nginx.repo /etc/yum.repos.d/

RUN yum clean all && \
    yum repolist && \
    yum install yum-utils -y && \
    yum install -y nginx

# Create necessary directories and set permissions
RUN mkdir -p /var/lib/nginx/router/{certs,cacerts} && \
    mkdir -p /var/lib/nginx/{conf,run,log,cache} && \
    touch /var/lib/nginx/conf/nginx.conf && \
    setcap 'cap_net_bind_service=ep' /usr/sbin/nginx && \
    chown -R :0 /var/lib/nginx && \
    chmod -R g+w /var/lib/nginx && \
    ln -sf /var/lib/nginx/log/error.log /var/log/nginx/error.log

# Copy versioning files
COPY package.json /var/lib/nginx/router/package.json
COPY apply-versions.sh /var/lib/nginx/router/apply-versions.sh
COPY docker-entrypoint.sh /var/lib/nginx/router/docker-entrypoint.sh

# Make scripts executable
RUN chmod +x /var/lib/nginx/router/apply-versions.sh && \
    chmod +x /var/lib/nginx/router/docker-entrypoint.sh

COPY ./nginx /var/lib/nginx/
COPY --from=build /app/dist /var/lib/nginx/router/html

LABEL io.k8s.display-name="OpenShift Origin NGINX Router" \
      io.k8s.description="This is a component of OpenShift Origin and contains an NGINX instance that automatically exposes services within the cluster through routes, and offers TLS termination, reencryption, or SNI-passthrough on ports 80 and 443."

USER 1001
EXPOSE 80 443

WORKDIR /var/lib/nginx/router
ENV TEMPLATE_FILE=/var/lib/nginx/conf/nginx-config.template \
    RELOAD_SCRIPT=/var/lib/nginx/reload-nginx

# Change ENTRYPOINT to run our script
ENTRYPOINT ["/var/lib/nginx/router/docker-entrypoint.sh"]
