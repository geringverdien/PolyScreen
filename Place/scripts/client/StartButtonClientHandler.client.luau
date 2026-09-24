local LocalPlayer = Players.LocalPlayer

local ToggleUI = PlayerGUI:WaitChild("ToggleUI")
local Button = ToggleUI["Button"]

local ToggleStreamEvent = Hidden:WaitChild("ToggleStream")

ToggleUI.Visible = LocalPlayer.IsCreator or LocalPlayer.Name == "Player"

local isStarted = false

Button.Clicked:Connect(function()
    isStarted = not isStarted
    Button.Text = isStarted and "Stop" or "Start"

    local message = NetMessage.New()
    message:AddBool("toggle", isStarted)

    ToggleStreamEvent:InvokeServer(message)
end)