FROM nginx:alpine

# Copy the script to the nginx html directory
COPY install-bugbounty-tools.sh /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Set correct permissions
RUN chmod 644 /usr/share/nginx/html/install-bugbounty-tools.sh