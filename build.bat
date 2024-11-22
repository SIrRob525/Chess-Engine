@echo off

cd build && zip -r ../game.love ./* && cd ..

:: Step 1: Build the game
call npx love.js.cmd -t chess game.love docs

:: Step 2: Copy enable-threads.js to the output directory
copy html\enable-threads.js docs\
copy html\netlify.toml docs\

:: Step 3: Run modify_index.js to modify index.html
node html\modify_index.js

del docs\theme\bg.png

echo Build completed successfully with enable-threads.js included and index.html modified.
