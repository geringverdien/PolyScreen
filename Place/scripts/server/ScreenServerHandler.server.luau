URL = "https://component-improve-augmented.ngrok-free.dev"
RESOLUTION = Vector2.New(80, 45)-- 16:9 ratio
FPS = 5


INITIAL_BUFFER_DELAY = 1
REQUESTS_PER_MINUTE = 95


local Monitor: Part = Environment:WaitChild("Monitor")
local LoadedValue: BoolValue = Monitor:WaitChild("Loaded")

local IsStreamingValue = Hidden:WaitChild("IsStreaming")
local HighestDrawTimeValue = Hidden:WaitChild("HighestDrawTime")

local RedrawScreen: NetworkEvent = Hidden:WaitChild("RedrawScreen")
local SetFPS: NetworkEvent = Hidden:WaitChild("SetFPS")
local SetResolution: NetworkEvent = Hidden:WaitChild("SetResolution")

local Libraries = ScriptService:WaitChild("Libraries")
local ScreenManager = require(Libraries:WaitChild("ScreenManager"))
local ServerRequest = require(Libraries:WaitChild("ServerRequest"))


local drawTime = 0
local frameQueue = {}
local queueHead = 1
local queueTail = 0
local playbackElapsed = 0
local clearBacklogRequested = true
local PROTOCOL_MAGIC = 0x31424656
local PROTOCOL_VERSION = 2
local PROTOCOL_HEADER_BYTES = 16
local FRAME_RECORD_BYTES = 8

repeat wait(0) until #Players:GetPlayers() > 0

ScreenManager:SetResolution(RESOLUTION)

ScreenManager:MakeScreen()

print("ScreenServerHandler loaded")

repeat wait(0) until LoadedValue.Value

print("Screen grid loaded")

local function enqueueFrames(dataBuffer: buffer)
    local bufferLength = buffer.len(dataBuffer)
    if bufferLength < PROTOCOL_HEADER_BYTES
        or buffer.readu32(dataBuffer, 0) ~= PROTOCOL_MAGIC then
        print("invalid binary")
        return
    end

    local version = buffer.readu16(dataBuffer, 4)
    local width = buffer.readu16(dataBuffer, 6)
    local height = buffer.readu16(dataBuffer, 8)
    local frameCount = buffer.readu32(dataBuffer, 10)
    if version ~= PROTOCOL_VERSION then
        print("old frames, v: " .. version)
        return
    end
    if width ~= RESOLUTION.X or height ~= RESOLUTION.Y then
        print("video resolution mismatch")
        return
    end

    local frameOffset = PROTOCOL_HEADER_BYTES
    local framesRead = 0
    while framesRead < frameCount do
        if frameOffset + 4 > bufferLength then
            print("abrupt end")
            break
        end

        local frameLength = buffer.readu32(dataBuffer, frameOffset)
        frameOffset += 4
        if frameLength % FRAME_RECORD_BYTES ~= 0
            or frameOffset + frameLength > bufferLength then
            print("invalid frame length")
            break
        end

        queueTail += 1
        frameQueue[queueTail] = {
            Buffer = dataBuffer,
            Offset = frameOffset,
            Length = frameLength
        }
        frameOffset += frameLength
        framesRead += 1
    end

    local maxQueuedFrames = math.max(2, math.ceil(INITIAL_BUFFER_DELAY * FPS + 2))
    local firstQueuedFrame = queueTail - maxQueuedFrames + 1
    if queueHead < firstQueuedFrame then
        for queuedFrame = queueHead, firstQueuedFrame - 1 do
            frameQueue[queuedFrame] = nil
        end
        queueHead = firstQueuedFrame
    end
end

local function getRequestInterval(): number
    return 60 / REQUESTS_PER_MINUTE
end

local function requestFrames()
    local nextRequestTime = time()

    while true do
        if not IsStreamingValue.Value then
            wait()
            continue
        end

        if clearBacklogRequested then
            local clearSuccess = ServerRequest:GetData(URL, true)
            if not clearSuccess then
                wait()
                continue
            end
            clearBacklogRequested = false
            wait(INITIAL_BUFFER_DELAY)
            nextRequestTime = time()
        end

        local requestSuccess, dataBuffer = ServerRequest:GetData(URL, false)
        if requestSuccess then
            local parseSuccess = pcall(enqueueFrames, dataBuffer)
            if not parseSuccess then
                print("http error")
            end
        end

        nextRequestTime += getRequestInterval()
        local waitTime = nextRequestTime - time()
        if waitTime > 0 then
            wait(waitTime)
        else
            nextRequestTime = time()
        end
    end
end

local function resetPlayback()
    frameQueue = {}
    queueHead = 1
    queueTail = 0
    playbackElapsed = 0
    clearBacklogRequested = true
end

resetPlayback()
coroutine.wrap(requestFrames)()

print("[color=blue][b]6d9's screenshare has loaded[/b][/color]")

IsStreamingValue.Changed:Connect(resetPlayback)

Hooks.Updated:Connect(function(dt)
    if not IsStreamingValue.Value or queueHead > queueTail then return end

    playbackElapsed += dt
    if playbackElapsed < 1 / FPS then return end

    playbackElapsed -= 1 / FPS
    local frame = frameQueue[queueHead]
    frameQueue[queueHead] = nil
    queueHead += 1
    drawTime = ScreenManager:DrawFrame(frame.Buffer, frame.Offset, frame.Length)

    if drawTime > HighestDrawTimeValue.Value then
        HighestDrawTimeValue.Value = drawTime
    end
end)

RedrawScreen.InvokedServer:Connect(function(player)
    if not player.IsCreator then return end
    
    local originalValue = IsStreamingValue.Value
    IsStreamingValue.Value = false
    wait()
    ScreenManager:MakeScreen()
    wait()
    resetPlayback()
    IsStreamingValue.Value = originalValue
end)

SetFPS.InvokedServer:Connect(function(player, msg)
    if not player.IsCreator then return end

    FPS = msg:GetInt("fps")
end)

SetResolution.InvokedServer:Connect(function(player, msg)
    if not player.IsCreator then return end

    local x, y = msg:GetInt("x"), msg:GetInt("y")

    if x then RESOLUTION.X = x end
    if y then RESOLUTION.Y = y end
end)