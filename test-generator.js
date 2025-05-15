const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Create output directory if it doesn't exist
const outputDir = path.join(__dirname, 'TestOutput');
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// Create a simple script to build and run our code
// We'll use the Swift Package Manager to build the project
try {
  console.log('Building the project...');
  execSync('swift build', { stdio: 'inherit' });

  console.log('Running the PetStore example...');
  // Use the existing generate-openapi-docc.sh script
  execSync('bash scripts/generate-openapi-docc.sh TestExamples/petstore-openapi3.yaml TestOutput PetStore',
    { stdio: 'inherit' });

  console.log('Done! Check the TestOutput directory for the generated documentation.');
} catch (error) {
  console.error('Error:', error.message);
}
