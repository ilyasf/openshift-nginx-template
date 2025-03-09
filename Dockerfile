# Step 1: Build the project
FROM node:20 as build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# Step 2: Create the Nginx image
FROM nginx:latest

# Install curl for healthchecks
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Create directory for versions
RUN mkdir -p /usr/share/nginx/html

# Copy versioning files
COPY package.json /etc/nginx/package.json
COPY apply-versions.sh /etc/nginx/apply-versions.sh
COPY docker-entrypoint.sh /etc/nginx/docker-entrypoint.sh

# Make scripts executable
RUN chmod +x /etc/nginx/apply-versions.sh && \
    chmod +x /etc/nginx/docker-entrypoint.sh

# Copy static files from build stage
COPY --from=build /app/dist /usr/share/nginx/html/

WORKDIR /etc/nginx

# Expose ports
EXPOSE 80 443

# Set entrypoint
ENTRYPOINT ["/etc/nginx/docker-entrypoint.sh"]
