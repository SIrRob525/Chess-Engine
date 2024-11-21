// html/modify_index.js
const fs = require('fs');
const path = require('path');

// Define the path to index.html
const indexFilePath = path.join(__dirname, '..', 'docs', 'index.html');

// Read the content of index.html
let content = fs.readFileSync(indexFilePath, 'utf8');

// Remove the <h1> tag and its content
content = content.replace(/<h1>[\s\S]*?<\/h1>/i, '');

// Remove the <footer> tag and its content
content = content.replace(/<footer>[\s\S]*?<\/footer>/i, '');

// Adjust the CSS to make the canvas fill the entire browser window
// Inject the CSS before the closing </head> tag
content = content.replace('</head>', `<style>
    html, body {
        margin: 0;
        padding: 0;
        background-color: rgb(242, 227, 199); /* RGB equivalent of (0.95, 0.89, 0.78) */
        overflow: hidden;
        width: 100%;
        height: 100%;
    }
    #canvas-container {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
    }
    canvas {
        display: block;
        max-width: 100vmin;
        max-height: 100vmin;
        width: 100%;
        height: auto;
    }
    </style></head>`);

// Remove any redundant empty lines
content = content.replace(/\n\s*\n/g, '\n');

// Write the modified content back to index.html
fs.writeFileSync(indexFilePath, content, 'utf8');
