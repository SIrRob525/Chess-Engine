// model.js

function getRandomEvaluation(position) {
    // Return a random number between -1 and 1
    const randomValue = Math.random() * 2 - 1;
    return randomValue;
}

// If running in Node.js, execute directly
if (typeof process !== 'undefined' && process.argv) {
    const randomValue = getRandomEvaluation();
    console.log(randomValue);  // Output the value so Lua can read it
}

// Make it available in the browser environment
if (typeof window !== 'undefined') {
    window.getRandomEvaluation = getRandomEvaluation;
}
