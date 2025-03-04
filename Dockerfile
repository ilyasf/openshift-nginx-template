# Step 1: Build the project
FROM node:20 as build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# Step 2: Create the Nginx image
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html

# Create necessary directories and adjust permissions
# RUN mkdir -p /var/cache/nginx/client_temp \
#     && chmod -R 777 /var/cache/nginx \
#     && chown -R nginx:nginx /var/cache/nginx \
#     && chown -R nginx:nginx /usr/share/nginx/html \
#     && mkdir -p /var/run/nginx \
#     && chown -R nginx:nginx /var/run/nginx

# # Copy custom Nginx configuration file
# COPY nginx.conf /etc/nginx/nginx.conf

# # Copy custom entrypoint script
# COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
# RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# USER nginx

# ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
# CMD ["nginx", "-g", "daemon off;"]

EXPOSE 80
