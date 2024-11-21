const express = require("express");
const path = require("path");

const app = express();
const port = 8000;

// Serve static files
app.use(express.static(path.join(__dirname, "docs"), {
    setHeaders: (res, path) => {
        res.set("Cross-Origin-Embedder-Policy", "require-corp");
        res.set("Cross-Origin-Opener-Policy", "same-origin");
    }
}));

app.listen(port, () => {
    console.log(`Server is running at http://localhost:${port}`);
});
