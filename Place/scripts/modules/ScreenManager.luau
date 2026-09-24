local ScreenManager = {}

local realPrint = print
local print = function(...) return realPrint("[" .. script.Name .. "]", ...) end

local Monitor = Environment:WaitChild("Monitor")
---@type Part
local Screen = Monitor["Screen"]
---@type BoolValue
local LoadedValue = Monitor["Loaded"]

local screenSize = Vector2.New(Screen.Size.X, Screen.Size.Y)
local Pixels = {}
local pixelColors = {}
local colorCache = {}
local screenResolution
local FRAME_RECORD_BYTES = 8

local function createPixel(x, y, color, pixelTemplate, screenPosition, screenQuaternion)
    local localX = -screenSize.X / 2 + pixelTemplate.Size.X / 2 + x * pixelTemplate.Size.X
    local localY = -screenSize.Y / 2 + pixelTemplate.Size.Y / 2 + y * pixelTemplate.Size.Y
    local localZ = Screen.Size.Z / 2 + pixelTemplate.Size.Z / 2 + 0.001

    local pixel = pixelTemplate:Clone()
    pixel.Position = screenPosition + screenQuaternion * Vector3.New(localX, localY, localZ)
    pixel.Quaternion = screenQuaternion
    pixel.Color = color
    pixel.Name = x .. "_" .. y
    pixel.Parent = Screen
end

function ScreenManager:SetResolution(resolution)
    screenResolution = resolution
end

function ScreenManager:MakeScreen()
    Pixels = {}
    pixelColors = {}

    for _, child in pairs(Screen:GetChildren()) do
        if child:IsA("Part") then
            child:Destroy()
        end
    end

    local templatePixel = Instance.New("Part")
    templatePixel.Size = Vector3.New(screenSize.X / screenResolution.X, screenSize.Y / screenResolution.Y, 0.01)
    templatePixel.Position = Vector3.New()
    --templatePixel.Anchored = true
    templatePixel.CanCollide = false
    templatePixel.CastShadows = false
    --templatePixel.Material = Enums.PartMaterial.SmoothPlastic

    

    local screenPosition = Screen.Position
    local screenQuaternion = Screen.Quaternion
    for y = 0, screenResolution.Y - 1 do
        for x = 0, screenResolution.X - 1 do
            local brightness = (x + y) / (screenResolution.X + screenResolution.Y)
            local color = Color.New(brightness, brightness, brightness)
            --local color = Color.New(x / screenResolution.x, y / screenResolution.y, x+y / (screenResolution.x + screenResolution.y))
            --local color = Color.New(1, 1, 1)
            createPixel(x, y, color, templatePixel, screenPosition, screenQuaternion)
        end
        if y%3 == 0 then wait() end
    end

    wait(0.1)

    LoadedValue.Value = true
    
    local i = 0
    for y = 0, screenResolution.Y - 1 do
        for x = 0, screenResolution.X - 1 do
            local pixelName = x .. "_" .. y
            Pixels[i] = Screen[pixelName]
            pixelColors[i] = nil
            i = i + 1
        end
    end

    print(Pixels[0].Name, Pixels[0].Color)
    print(Pixels[#Pixels].Name, Pixels[#Pixels].Color)
end

function ScreenManager:DrawFrame(dataBuffer: buffer, frameOffset: number, frameLength: number)
    print("Painting screen with frame data of length " .. frameLength)
    local startTime = os.clock()

    local frameEnd = frameOffset + frameLength
    while frameOffset < frameEnd do
        local i = buffer.readu32(dataBuffer, frameOffset)
        local pixel = Pixels[i]
        if pixel then
            local r = buffer.readu8(dataBuffer, frameOffset + 4)
            local g = buffer.readu8(dataBuffer, frameOffset + 5)
            local b = buffer.readu8(dataBuffer, frameOffset + 6)
            local colorKey = r * 65536 + g * 256 + b
            if pixelColors[i] ~= colorKey then
                local color = colorCache[colorKey]
                if not color then
                    color = Color.New(r / 255, g / 255, b / 255)
                    colorCache[colorKey] = color
                end
                pixel.Color = color
                pixelColors[i] = colorKey
            end
        end
        frameOffset += FRAME_RECORD_BYTES
    end

    local endTime = os.clock()
    local elapsedTime = endTime - startTime
    print("Frame draw time: " .. elapsedTime .. " seconds.")

    return elapsedTime
end


return ScreenManager