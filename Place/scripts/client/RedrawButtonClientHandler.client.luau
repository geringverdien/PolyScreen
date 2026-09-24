local LocalPlayer = Players.LocalPlayer

local RedrawUI = PlayerGUI:WaitChild("RedrawUI")
local Button = RedrawUI["Button"]

local RedrawScreenEvent = Hidden:WaitChild("RedrawScreen")

RedrawUI.Visible = LocalPlayer.IsCreator or LocalPlayer.Name == "Player"

Button.Clicked:Connect(function()
    RedrawScreenEvent:InvokeServer()
end)