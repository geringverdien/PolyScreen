local ScreenManager = require(ScriptService:WaitChild("ScreenManager"))

local DispatchData: NetworkEvent = Hidden:WaitChild("DispatchData")

local Monitor: Model = Environment:WaitChild("Monitor")
local TextRenderer: Text3D = Monitor:WaitChild("TextRenderer")

DispatchData.InvokedClient:Connect(function(msg)
    local dataBuffer = msg:GetBuffer("data") -- image data buffer


end)

-- Hooks.Updated:Connect(function(dt)
--     -- update text if it updated

-- end)