const express = require('express');
const compression = require('compression');
const path = require('path');
const app = express();

// Enable compression for all requests
app.use(compression());

// Serve static files from the Flutter web build directory
app.use(express.static(path.join(__dirname, 'build/web')));

// For any other routes, serve the index.html file (SPA routing)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build/web/index.html'));
});

// Get the port from the environment variable or use 8080 as default
const PORT = process.env.PORT || 8080;

// Start the server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Serving Flutter web app from ${path.join(__dirname, 'build/web')}`);
});

// Handle process termination gracefully
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});
