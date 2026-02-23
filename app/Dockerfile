# Node.js runtime image
FROM nginx:alpine

# Set working directory inside container
WORKDIR /app

# Copy package info first and install dependencies
COPY index.html /usr/share/nginx/html/index.html

# App will listen on port 80
EXPOSE 80

# Start the Node app
CMD ["nginx", "-g", "daemon off;"]