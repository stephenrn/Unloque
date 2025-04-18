const fs = require('fs');
const path = require('path');

console.log('--- Environment Check ---');
console.log(`Node version: ${process.version}`);
console.log(`Current directory: ${process.cwd()}`);
console.log(`__dirname: ${__dirname}`);

try {
  const webDir = path.join(__dirname, 'build/web');
  console.log(`Checking if ${webDir} exists: ${fs.existsSync(webDir)}`);
  
  if (fs.existsSync(webDir)) {
    const files = fs.readdirSync(webDir);
    console.log(`Files in build/web: ${files.join(', ')}`);
    
    // Check for index.html specifically
    const indexPath = path.join(webDir, 'index.html');
    console.log(`Checking if index.html exists: ${fs.existsSync(indexPath)}`);
  }
  
  // Check Dockerfile
  const dockerfilePath = path.join(__dirname, 'Dockerfile');
  if (fs.existsSync(dockerfilePath)) {
    console.log('Dockerfile exists');
    console.log('Dockerfile content:');
    console.log(fs.readFileSync(dockerfilePath, 'utf8'));
  } else {
    console.log('Dockerfile not found');
  }
  
  // List all files in the current directory
  console.log('Files in current directory:');
  console.log(fs.readdirSync(__dirname).join(', '));
  
} catch (error) {
  console.error('Error during environment check:', error);
}
console.log('--- End Environment Check ---');
