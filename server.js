const express = require('express');
const compression = require('compression');
const path = require('path');
const fs = require('fs');
const app = express();

// Enable compression for all requests
app.use(compression());

// Add a health check endpoint that Cloud Run can use to verify the server is running
app.get('/_ah/health', (req, res) => {
  res.status(200).send('OK');
});

// Check if the web directory exists
const webDirectoryPath = path.join(__dirname, 'build/web');
const exists = fs.existsSync(webDirectoryPath);

console.log(`Checking web directory: ${webDirectoryPath}`);
console.log(`Directory exists: ${exists}`);

if (!exists) {
  console.error(`ERROR: Directory ${webDirectoryPath} does not exist!`);
  
  // List contents of the parent directories to help debug
  try {
    const rootContents = fs.readdirSync(__dirname);
    console.log(`Contents of ${__dirname}:`, rootContents);
    
    if (rootContents.includes('build')) {
      const buildContents = fs.readdirSync(path.join(__dirname, 'build'));
      console.log(`Contents of ${path.join(__dirname, 'build')}:`, buildContents);
    }
  } catch (err) {
    console.error('Error listing directory contents:', err);
  }
}

// Serve static files from the Flutter web build directory
app.use(express.static(webDirectoryPath));

// For any other routes, serve the index.html file (SPA routing)
app.get('*', (req, res) => {
  // Check if index.html exists before trying to serve it
  const indexPath = path.join(webDirectoryPath, 'index.html');
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(500).send('index.html not found. Server misconfigured.');
    console.error(`ERROR: index.html not found at ${indexPath}`);
  }
});

// Get the port from the environment variable or use 8080 as default
const PORT = process.env.PORT || 8080;

// Start the server with error handling
const server = app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
  console.log(`Serving Flutter web app from ${webDirectoryPath}`);
});

server.on('error', (error) => {
  console.error('Server error:', error);
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
  // In production, try to keep the server running despite errors
  if (process.env.NODE_ENV !== 'production') {
    process.exit(1);
  }
});
