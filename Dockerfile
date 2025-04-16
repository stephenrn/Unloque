FROM node:18-slim

WORKDIR /app

# Copy package.json and server.js
COPY package.json server.js ./

# Copy the Flutter web build output
COPY build/web ./build/web

# Install dependencies
RUN npm install --production

# Expose the port the app runs on
EXPOSE 8080

# Command to run the app
CMD ["npm", "start"]
