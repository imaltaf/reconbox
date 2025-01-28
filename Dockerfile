FROM nginx:alpine

# Copy the script to the nginx html directory
COPY recon-box.sh /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Set correct permissions
RUN chmod 644 /usr/share/nginx/html/recon-box.sh