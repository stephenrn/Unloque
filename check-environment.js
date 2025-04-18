const fs = require('fs');
const path = require('path');

console.log('--- Environment Check ---');
console.log(`Node version: ${process.version}`);
console.log(`Current directory: ${process.cwd()}`);
console.log(`__dirname: ${__dirname}`);
console.log(`PORT environment variable: ${process.env.PORT || 'not set (will default to 8080)'}`);

let criticalError = false;

try {
  const webDir = path.join(__dirname, 'build/web');
  console.log(`Checking if ${webDir} exists: ${fs.existsSync(webDir)}`);
  
  if (fs.existsSync(webDir)) {
    const files = fs.readdirSync(webDir);
    console.log(`Files in build/web: ${files.join(', ')}`);
    
    // Check for index.html specifically
    const indexPath = path.join(webDir, 'index.html');
    const indexExists = fs.existsSync(indexPath);
    console.log(`Checking if index.html exists: ${indexExists}`);
    
    if (!indexExists) {
      console.error('CRITICAL ERROR: index.html not found in build/web directory');
      criticalError = true;
    }
  } else {
    console.error('CRITICAL ERROR: build/web directory not found');
    criticalError = true;
  }
  
  // Check server.js file
  const serverJsPath = path.join(__dirname, 'server.js');
  if (fs.existsSync(serverJsPath)) {
    console.log('server.js exists, checking content...');
    
    const serverContent = fs.readFileSync(serverJsPath, 'utf8');
    
    // Check if server.js is listening on the PORT environment variable
    if (serverContent.includes('process.env.PORT')) {
      console.log('✓ server.js appears to use process.env.PORT correctly');
    } else {
      console.error('CRITICAL ERROR: server.js may not be using process.env.PORT');
      criticalError = true;
    }
    
    // Check if server actually starts a listener
    if (serverContent.includes('.listen(') || serverContent.includes('.listen (')) {
      console.log('✓ server.js appears to start a listener');
    } else {
      console.error('CRITICAL ERROR: No .listen() call found in server.js');
      criticalError = true;
    }
  } else {
    console.error('CRITICAL ERROR: server.js not found');
    criticalError = true;
  }
  
  // Check Dockerfile
  const dockerfilePath = path.join(__dirname, 'Dockerfile');
  if (fs.existsSync(dockerfilePath)) {
    console.log('Dockerfile exists');
    console.log('Dockerfile content:');
    console.log(fs.readFileSync(dockerfilePath, 'utf8'));
    
    const dockerContent = fs.readFileSync(dockerfilePath, 'utf8');
    if (!dockerContent.includes('EXPOSE')) {
      console.warn('WARNING: No EXPOSE instruction in Dockerfile');
    }
    
    if (!dockerContent.includes('CMD')) {
      console.error('CRITICAL ERROR: No CMD instruction in Dockerfile');
      criticalError = true;
    }
  } else {
    console.log('Dockerfile not found');
  }
  
  // List all files in the current directory
  console.log('Files in current directory:');
  console.log(fs.readdirSync(__dirname).join(', '));
  
  // Check package.json for start script
  const packageJsonPath = path.join(__dirname, 'package.json');
  if (fs.existsSync(packageJsonPath)) {
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
    if (packageJson.scripts && packageJson.scripts.start) {
      console.log(`Start script: ${packageJson.scripts.start}`);
      
      // If start script references check-environment.js but doesn't actually start the server
      if (packageJson.scripts.start.includes('check-environment.js') && 
          !packageJson.scripts.start.includes('server.js')) {
        console.error('CRITICAL ERROR: Start script only runs check-environment.js but not server.js');
        criticalError = true;
      }
    } else {
      console.error('CRITICAL ERROR: No start script found in package.json');
      criticalError = true;
    }
  } else {
    console.error('CRITICAL ERROR: package.json not found');
    criticalError = true;
  }
  
} catch (error) {
  console.error('Error during environment check:', error);
  criticalError = true;
}

console.log('--- End Environment Check ---');

// Exit with error code if critical errors were found
if (criticalError) {
  console.error('Critical errors were found that may prevent the server from starting');
  // When running in a container in development, we might want to continue
  // but in production this helps identify issues
  if (process.env.NODE_ENV === 'production') {
    process.exit(1);
  }
}
