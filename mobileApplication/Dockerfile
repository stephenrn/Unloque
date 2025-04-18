FROM node:18-slim

WORKDIR /app

# Copy package.json, server.js and environment check script
COPY package.json server.js check-environment.js ./

# Copy the Flutter web build output
COPY build/web ./build/web

# Also copy the public directory for Firebase Hosting
COPY public ./public

# Install dependencies
RUN npm install --production

# Expose the port the app runs on
EXPOSE 8080

# Command to run the app
CMD ["npm", "start"]
