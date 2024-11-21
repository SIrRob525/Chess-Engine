@echo off

cd build && zip -r ../game.love ./* && cd .. 

:: Step 1: Build the game
call npx love.js.cmd -t chess game.love docs

:: Step 2: Copy enable-threads.js to the output directory
copy enable-threads.js docs\

:: Step 3: Inject the script into index.html if not already present
findstr /C:"enable-threads.js" docs\index.html >nul
if %ERRORLEVEL% neq 0 (
    powershell -Command "(Get-Content docs\index.html) -replace '</head>', '<script src=\"enable-threads.js\"></script></head>' | Set-Content docs\index.html"
)

echo Build completed successfully with enable-threads.js included.