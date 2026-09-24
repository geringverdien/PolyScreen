# PolyScreen
A decently fast screenshare within Polytoria :3

# Requirements
- node.js
- [ngrok](https://ngrok.com) account, [authtoken](https://dashboard.ngrok.com/get-started/your-authtoken) needed
- if on Linux, i recommend an x11 session to fix a weird xdg-desktop-portal bug with the screenshot library 

# Setup 
## Server
```bash
cd ./Server
npm install

touch .env
echo "AUTHTOKEN" > .env

# runs in monitor mode
npm run dev
```

## Game (Place)
1. Open `scripts/server/ScreenServerHandler.server.luau`
2. Edit the `URL` variable in line 1 to be your server url (found [here](https://dashboard.ngrok.com/domains) or in terminal when running the server)
3. Save/Publish
4. Wait for Screen to finish building, click Start

# Configuration
### IMPORTANT: FPS and Resolution have to match between server and game, too high FPS/res causes lag or crashes or whatnot

## Server
- `FPS` - recorded framerate
- `SCREEN_RESOLUTION` - x and y size in pixels, should be in your monitor's [aspect ratio](https://calculateaspectratio.com/)
- `COLOR_THRESHOLD` - how much a pixel has to change color to be sent to the game

## Game
- Top Left:
    - Start/Stop: Starts or stops the screenshare. Always make sure server is running and fps/resolution match before starting
    - Redraw: Deletes the screen and remakes it. **USE AFTER CHANGING RESOLUTION AND DONT USE IT WHILE SCREENSHARE IS RUNNING**

- Bottom Right:
    - X/Y: Width and height of screen. **USE WHILE SCREENSHARE IS STOPPED AND REDRAW BEFORE STARTING IT**
    - FPS: Screenshare FPS, also only change while screenshare is paused to prevent desync/delay


- `ScreenServerHandler` contains some more config variables at the top, only touch these if you know what you are doing

- bottom left text label shows you the longest render time, only used for debugging

---
## Hope you enjoy this project :)