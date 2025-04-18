const express = require('express');
const compression = require('compression');
const path = require('path');
const app = express();

// Enable compression for all requests
app.use(compression());

// Add a health check endpoint that Cloud Run can use to verify the server is running
app.get('/_ah/health', (req, res) => {
  res.status(200).send('OK');
});

// Serve static files from the Flutter web build directory
app.use(express.static(path.join(__dirname, 'build/web')));

// For any other routes, serve the index.html file (SPA routing)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build/web/index.html'));
});

// Get the port from the environment variable or use 8080 as default
const PORT = process.env.PORT || 8080;

// Start the server with error handling
const server = app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
  console.log(`Serving Flutter web app from ${path.join(__dirname, 'build/web')}`);
});

server.on('error', (error) => {
  console.error('Server error:', error);
  process.exit(1);
});

// Handle termination signals properly
['SIGINT', 'SIGTERM'].forEach(signal => {
  process.on(signal, () => {
    console.log(`${signal} received, shutting down gracefully`);
    server.close(() => {
      console.log('Server closed');
      process.exit(0);
    });
    
    // Force close if graceful shutdown takes too long
    setTimeout(() => {
      console.error('Forcing server close after timeout');
      process.exit(1);
    }, 10000); // 10 seconds
  });
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught exception:', error);
  process.exit(1);
});
