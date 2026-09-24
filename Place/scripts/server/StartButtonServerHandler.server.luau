---@type NetworkEvent
local ToggleStreamEvent = Hidden:WaitChild("ToggleStream")
local IsStreamingValue = Hidden:WaitChild("IsStreaming")

ToggleStreamEvent.InvokedServer:Connect(function(player, message)
    if not (player.IsCreator or player.Name == "Player") then return end

    local toggle = message:GetBool("toggle")
    print("Toggling stream to " .. tostring(toggle))

    IsStreamingValue.Value = toggle
end)