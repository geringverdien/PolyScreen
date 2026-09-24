local LocalPlayer = Players.LocalPlayer

local VideoFPS: GUI = PlayerGUI:WaitChild("VideoFPS")
local Input: UITextInput = VideoFPS["Input"]

local SetFPS: NetworkEvent = Hidden:WaitChild("SetFPS")

VideoFPS.Visible = LocalPlayer.IsCreator or LocalPlayer.Name == "Player"

Input.Submitted:Connect(function()
    local fps = tonumber(Input.Text)
    if not fps or fps < 1 then return end
    local msg = NetMessage.New()
    msg:AddInt("fps", fps)

    SetFPS:InvokeServer(msg)
end)