WINDOW_SIZE = 5

local label = script.Parent
---@cast label UILabel

local frameTimes = {}
local frameCount = 0
local windowCount = 0
local writeIndex = 1
local dtSum = 0

Hooks.Updated:Connect(function(dt)
    frameCount = frameCount + 1

    local oldDt = frameTimes[writeIndex]
    if oldDt then
        dtSum = dtSum - oldDt
    else
        windowCount = windowCount + 1
    end

    frameTimes[writeIndex] = dt
    dtSum = dtSum + dt
    writeIndex = writeIndex + 1
    if writeIndex > WINDOW_SIZE then
        writeIndex = 1
    end

    if frameCount % WINDOW_SIZE == 0 and windowCount > 0 then
        local avgDt = dtSum / windowCount
        if avgDt > 0 then
            local fps = math.floor(1 / avgDt)
            label.Text = tostring(fps)
        end
    end
end)