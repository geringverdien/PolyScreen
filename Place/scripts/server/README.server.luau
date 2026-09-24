--[=[
Screen sharing setup

1. Run an HTTP capture server and expose it through ngrok.
2. The GET endpoint returns an `application/octet-stream` video buffer.
   The buffer is little-endian and contains:
   - 4 bytes: protocol magic (`VFB1`)
  - 2 bytes: protocol version (`2`)
   - 2 bytes: width
   - 2 bytes: height
   - 4 bytes: frame count
   - 2 bytes: reserved
   - for each frame: 4-byte payload length, then zero or more 16-byte records
   - each record contains an 8-byte payload:
     - 4-byte pixel index
     - 1-byte red, 1-byte green, 1-byte blue
     - 1 reserved byte
3. Set URL in AuthHandler.server.luau to the public ngrok URL.
4. Start the stream in-game.

The game requests the endpoint repeatedly. The first request adds ?clear=1 so
an already-buffered backlog can be discarded by the capture server.
]=]
