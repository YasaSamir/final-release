/**
 * API Calls Scanner
 * 
 * This script scans the backend directory to identify and print all API endpoints
 * and Socket.IO events in the codebase.
 */

const fs = require('fs');
const path = require('path');

// Configuration
const rootDir = path.resolve(__dirname);
const excludeDirs = ['node_modules', '.git'];

// Results storage
const results = {
  httpEndpoints: [],
  socketEvents: {
    server: {
      on: [],
      emit: []
    },
    client: {
      on: [],
      emit: []
    }
  }
};

/**
 * Scan a file for API endpoints and Socket.IO events
 * @param {string} filePath - Path to the file
 */
function scanFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const fileExt = path.extname(filePath);
    
    // Only scan JavaScript files
    if (fileExt !== '.js') return;
    
    const relativePath = path.relative(rootDir, filePath);
    console.log(`Scanning ${relativePath}...`);
    
    // Scan for HTTP endpoints (Express.js)
    scanForHttpEndpoints(content, relativePath);
    
    // Scan for Socket.IO events
    scanForSocketEvents(content, relativePath);
    
  } catch (error) {
    console.error(`Error scanning file ${filePath}:`, error.message);
  }
}

/**
 * Scan for HTTP endpoints (Express.js)
 * @param {string} content - File content
 * @param {string} filePath - Relative file path
 */
function scanForHttpEndpoints(content, filePath) {
  // Match Express route patterns: app.METHOD(path, ...
  const routeRegex = /app\.(get|post|put|delete|patch)\s*\(\s*['"`]([^'"`]+)['"`]/g;
  let match;
  
  while ((match = routeRegex.exec(content)) !== null) {
    const method = match[1].toUpperCase();
    const path = match[2];
    
    results.httpEndpoints.push({
      method,
      path,
      file: filePath,
      line: getLineNumber(content, match.index)
    });
  }
  
  // Match router route patterns: router.METHOD(path, ...
  const routerRegex = /router\.(get|post|put|delete|patch)\s*\(\s*['"`]([^'"`]+)['"`]/g;
  
  while ((match = routerRegex.exec(content)) !== null) {
    const method = match[1].toUpperCase();
    const path = match[2];
    
    results.httpEndpoints.push({
      method,
      path,
      file: filePath,
      line: getLineNumber(content, match.index)
    });
  }
}

/**
 * Scan for Socket.IO events
 * @param {string} content - File content
 * @param {string} filePath - Relative file path
 */
function scanForSocketEvents(content, filePath) {
  // Server-side socket.on events
  const socketOnRegex = /socket\.on\s*\(\s*['"`]([^'"`]+)['"`]/g;
  let match;
  
  while ((match = socketOnRegex.exec(content)) !== null) {
    const event = match[1];
    
    results.socketEvents.server.on.push({
      event,
      file: filePath,
      line: getLineNumber(content, match.index)
    });
  }
  
  // Server-side io.emit events
  const ioEmitRegex = /io\.emit\s*\(\s*['"`]([^'"`]+)['"`]/g;
  
  while ((match = ioEmitRegex.exec(content)) !== null) {
    const event = match[1];
    
    results.socketEvents.server.emit.push({
      event,
      file: filePath,
      line: getLineNumber(content, match.index)
    });
  }
  
  // Server-side socket.emit events
  const socketEmitRegex = /socket\.emit\s*\(\s*['"`]([^'"`]+)['"`]/g;
  
  while ((match = socketEmitRegex.exec(content)) !== null) {
    const event = match[1];
    
    results.socketEvents.client.emit.push({
      event,
      file: filePath,
      line: getLineNumber(content, match.index)
    });
  }
  
  // Server-side io.to().emit events
  const ioToEmitRegex = /io\.to\([^)]+\)\.emit\s*\(\s*['"`]([^'"`]+)['"`]/g;
  
  while ((match = ioToEmitRegex.exec(content)) !== null) {
    const event = match[1];
    
    results.socketEvents.server.emit.push({
      event,
      file: filePath,
      line: getLineNumber(content, match.index)
    });
  }
}

/**
 * Get line number from character index
 * @param {string} content - File content
 * @param {number} index - Character index
 * @returns {number} Line number
 */
function getLineNumber(content, index) {
  const lines = content.slice(0, index).split('\n');
  return lines.length;
}

/**
 * Recursively scan a directory
 * @param {string} dir - Directory to scan
 */
function scanDirectory(dir) {
  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      
      if (entry.isDirectory()) {
        // Skip excluded directories
        if (excludeDirs.includes(entry.name)) continue;
        
        scanDirectory(fullPath);
      } else {
        scanFile(fullPath);
      }
    }
  } catch (error) {
    console.error(`Error scanning directory ${dir}:`, error.message);
  }
}

/**
 * Print results in a formatted way
 */
function printResults() {
  console.log('\n=== API CALLS SCANNER RESULTS ===\n');
  
  // Print HTTP endpoints
  console.log('HTTP ENDPOINTS:');
  console.log('----------------');
  
  if (results.httpEndpoints.length === 0) {
    console.log('No HTTP endpoints found.');
  } else {
    results.httpEndpoints.forEach(endpoint => {
      console.log(`${endpoint.method} ${endpoint.path}`);
      console.log(`  File: ${endpoint.file}:${endpoint.line}\n`);
    });
  }
  
  // Print Socket.IO events
  console.log('\nSOCKET.IO EVENTS:');
  console.log('-----------------');
  
  console.log('\nServer listening events (socket.on):');
  if (results.socketEvents.server.on.length === 0) {
    console.log('No server listening events found.');
  } else {
    results.socketEvents.server.on.forEach(event => {
      console.log(`Event: "${event.event}"`);
      console.log(`  File: ${event.file}:${event.line}`);
    });
  }
  
  console.log('\nServer emitting events (io.emit, io.to().emit):');
  if (results.socketEvents.server.emit.length === 0) {
    console.log('No server emitting events found.');
  } else {
    results.socketEvents.server.emit.forEach(event => {
      console.log(`Event: "${event.event}"`);
      console.log(`  File: ${event.file}:${event.line}`);
    });
  }
  
  console.log('\nClient emitting events (socket.emit):');
  if (results.socketEvents.client.emit.length === 0) {
    console.log('No client emitting events found.');
  } else {
    results.socketEvents.client.emit.forEach(event => {
      console.log(`Event: "${event.event}"`);
      console.log(`  File: ${event.file}:${event.line}`);
    });
  }
}

// Main execution
console.log('Starting API Calls Scanner...');
scanDirectory(rootDir);
printResults();
